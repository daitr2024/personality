// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../config/theme/app_theme.dart';
import '../providers/finance_providers.dart';
import '../utils/currency_input_formatter.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../settings/presentation/providers/currency_provider.dart';

class NewTransactionPage extends ConsumerStatefulWidget {
  const NewTransactionPage({super.key});

  @override
  ConsumerState<NewTransactionPage> createState() => _NewTransactionPageState();
}

class _NewTransactionPageState extends ConsumerState<NewTransactionPage> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _amountFocusNode = FocusNode();
  final _amountKey = GlobalKey();
  bool _isExpense = true;
  String _selectedCategory = '';
  DateTime _selectedDate = DateTime.now();

  // Installment
  bool _isInstallment = false;
  int _installmentCount = 2;

  // Scanning State
  bool _isScanning = false;
  String? _receiptImagePath;
  OverlayEntry? _tooltipOverlay;


  /// Expense categories (8)
  List<String> get _expenseCategories => [
    AppLocalizations.of(context)!.categoryMarket,
    AppLocalizations.of(context)!.categoryHousing,
    AppLocalizations.of(context)!.categoryTransport,
    AppLocalizations.of(context)!.categoryHealth,
    AppLocalizations.of(context)!.categoryPersonal,
    AppLocalizations.of(context)!.categoryTech,
    AppLocalizations.of(context)!.categoryDonation,
    AppLocalizations.of(context)!.categoryOther,
  ];

  /// Income categories (3)
  List<String> get _incomeCategories => [
    AppLocalizations.of(context)!.categorySalary,
    AppLocalizations.of(context)!.categoryInvestment,
    AppLocalizations.of(context)!.categoryOtherIncome,
  ];


  List<String> get _categories =>
      _isExpense ? _expenseCategories : _incomeCategories;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _amountFocusNode.dispose();
    _tooltipOverlay?.remove();
    super.dispose();
  }

  void _showAmountTooltip() {
    _tooltipOverlay?.remove();
    final l10n = AppLocalizations.of(context)!;
    final renderBox =
        _amountKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final offset = renderBox.localToGlobal(Offset.zero);
    final cs = Theme.of(context).colorScheme;

    _tooltipOverlay = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx + 16,
        top: offset.dy - 40,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 250),
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, (1 - value) * 6),
                child: child,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: cs.inverseSurface,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                l10n.installmentTotalTooltip,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: cs.onInverseSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_tooltipOverlay!);
    Future.delayed(const Duration(milliseconds: 1500), () {
      _tooltipOverlay?.remove();
      _tooltipOverlay = null;
    });
  }

  Future<void> _scanReceipt() async {
    var status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.cameraPermissionRequired,
            ),
          ),
        );
      }
      return;
    }

    setState(() => _isScanning = true);

    try {
      final scannerService = ref.read(receiptScannerServiceProvider);
      final image = await scannerService.pickImageFromCamera();
      if (image != null) {
        final savedPath = await scannerService.saveImageLocally(image);
        setState(() => _receiptImagePath = savedPath);

        final result = await scannerService.scanReceipt(savedPath);

        if (context.mounted) {
          if (result.amount != null) {
            _amountController.text = result.amount!.toStringAsFixed(2);
          }
          if (result.description.isNotEmpty) {
            _titleController.text = result.description;
          }
          // Auto-set date from receipt if detected
          if (result.receiptDate != null) {
            setState(() {
              _selectedDate = result.receiptDate!;
            });
          }
          // Auto-set category from receipt
          if (result.category.isNotEmpty) {
            final matchedCategory = _categories.firstWhere(
              (c) => c.toLowerCase() == result.category.toLowerCase(),
              orElse: () => _categories.last,
            );
            setState(() {
              _selectedCategory = matchedCategory;
            });
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.receiptScanned),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.error}: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  void _saveTransaction() {
    final l10n = AppLocalizations.of(context)!;
    final title = _titleController.text.trim();
    final amount = parseCurrencyInput(_amountController.text, Localizations.localeOf(context).toString());
    final note = '';

    if (title.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.pleaseEnterValidValues)));
      return;
    }

    final repo = ref.read(financeRepositoryProvider);
    final effectiveCategory = _selectedCategory.isEmpty
        ? _categories.first
        : _selectedCategory;

    if (_isInstallment && _isExpense && _installmentCount > 1) {
      // Create installment transactions
      repo.addInstallmentTransaction(
        title: title,
        totalAmount: amount,
        category: effectiveCategory,
        startDate: _selectedDate,
        installmentCount: _installmentCount,
        receiptImagePath: _receiptImagePath,
      );

      final perInstallment = amount / _installmentCount;
      final symbol = ref.read(currencySymbolProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.installmentsCreated(
              _installmentCount,
              '${perInstallment.toStringAsFixed(2)} $symbol',
            ),
          ),
          backgroundColor: AppTheme.completedColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } else {
      // Single transaction
      repo.addTransaction(
        title,
        amount,
        effectiveCategory,
        _selectedDate,
        _isExpense,
        receiptImagePath: _receiptImagePath,
        note: note.isNotEmpty ? note : null,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.transactionSaved),
          backgroundColor: AppTheme.completedColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }

    context.pop();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: Localizations.localeOf(context),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final localeCode = Localizations.localeOf(context).toString();
    final dateStr = DateFormat('dd MMM yyyy', localeCode).format(_selectedDate);

    // Ensure selected category is valid for current type
    if (!_categories.contains(_selectedCategory)) {
      _selectedCategory = _categories.first;
    }

    return Scaffold(

      appBar: AppBar(title: Text(l10n.addNewTransaction)),

      body: Column(

        children: [

          Expanded(

            child: SingleChildScrollView(

              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  // -- Type Toggle --

                  Row(

                    children: [

                      Expanded(

                        child: _buildTypeButton(

                          label: l10n.expense,

                          isSelected: _isExpense,

                          color: AppTheme.expenseColor,

                          icon: Icons.arrow_downward_rounded,

                          onTap: () => setState(() => _isExpense = true),

                        ),

                      ),

                      const Gap(8),

                      Expanded(

                        child: _buildTypeButton(

                          label: l10n.income,

                          isSelected: !_isExpense,

                          color: AppTheme.incomeColor,

                          icon: Icons.arrow_upward_rounded,

                          onTap: () => setState(() {

                            _isExpense = false;

                            _isInstallment = false;

                          }),

                        ),

                      ),

                    ],

                  ),

                  const Gap(12),



                  // -- Receipt Scan (compact inline) --

                  if (_isExpense)

                    Padding(

                      padding: const EdgeInsets.only(bottom: 12),

                      child: GestureDetector(

                        onTap: _scanReceipt,

                        child: Container(

                          width: double.infinity,

                          height: 52,

                          decoration: BoxDecoration(

                            color: cs.surfaceContainerHighest.withValues(alpha: 0.4),

                            borderRadius: BorderRadius.circular(12),

                            border: Border.all(

                              color: _receiptImagePath != null

                                  ? AppTheme.completedColor.withValues(alpha: 0.5)

                                  : cs.outlineVariant.withValues(alpha: 0.3),

                            ),

                          ),

                          child: _isScanning

                              ? const Center(

                                  child: SizedBox(

                                    width: 20, height: 20,

                                    child: CircularProgressIndicator(strokeWidth: 2),

                                  ),

                                )

                              : Row(

                                  mainAxisAlignment: MainAxisAlignment.center,

                                  children: [

                                    Icon(

                                      _receiptImagePath != null

                                          ? Icons.check_circle_rounded

                                          : Icons.camera_alt_rounded,

                                      color: _receiptImagePath != null

                                          ? AppTheme.completedColor

                                          : cs.onSurface.withValues(alpha: 0.4),

                                      size: 20,

                                    ),

                                    const Gap(8),

                                    Text(

                                      _receiptImagePath != null

                                          ? l10n.receiptAdded

                                          : l10n.scanReceipt,

                                      style: TextStyle(

                                        color: _receiptImagePath != null

                                            ? AppTheme.completedColor

                                            : cs.onSurface.withValues(alpha: 0.5),

                                        fontWeight: FontWeight.w500,

                                        fontSize: 13,

                                      ),

                                    ),

                                  ],

                                ),

                        ),

                      ),

                    ),



                  // -- Description --

                  TextField(

                    controller: _titleController,

                    maxLength: 40,
                    maxLines: 2,

                    style: const TextStyle(fontSize: 14),

                    decoration: InputDecoration(

                      labelText: l10n.description,

                      isDense: true,

                      border: OutlineInputBorder(

                        borderRadius: BorderRadius.circular(12),

                      ),

                      prefixIcon: const Icon(Icons.text_fields_rounded, size: 18),

                      helperText: l10n.descriptionHint,

                      helperStyle: const TextStyle(fontSize: 10),

                      counterText: '',

                    ),

                  ),

                  const Gap(8),



                  // -- Amount + Category (side by side) --

                  Row(

                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

                      Expanded(

                        flex: 5,

                        child: TextField(

                          key: _amountKey,

                          controller: _amountController,

                          focusNode: _amountFocusNode,

                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [CurrencyInputFormatter(locale: Localizations.localeOf(context).toString())],
                          style: const TextStyle(fontSize: 14),

                          decoration: InputDecoration(

                            labelText: l10n.amount,

                            isDense: true,

                            border: OutlineInputBorder(

                              borderRadius: BorderRadius.circular(12),

                            ),

                            prefixIcon: Padding(

                              padding: const EdgeInsets.only(left: 10, right: 2),

                              child: Text(

                                ref.watch(currencySymbolProvider),

                                style: TextStyle(

                                  fontSize: 16,

                                  fontWeight: FontWeight.w600,

                                  color: cs.onSurface.withValues(alpha: 0.5),

                                ),

                              ),

                            ),

                            prefixIconConstraints: const BoxConstraints(

                              minWidth: 32, minHeight: 0,

                            ),

                            suffixText: ref.watch(currencySymbolProvider),

                            suffixStyle: const TextStyle(fontSize: 12),

                          ),

                        ),

                      ),

                      const Gap(8),

                      Expanded(

                        flex: 6,

                        // ignore: deprecated_member_use

                        child: DropdownButtonFormField<String>(

                          initialValue: _categories.contains(_selectedCategory)

                              ? _selectedCategory

                              : _categories.first,

                          items: _categories

                              .map((c) => DropdownMenuItem(

                                    value: c,

                                    child: Text(c, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),

                                  ))

                              .toList(),
                          onChanged: (val) => setState(() => _selectedCategory = val ?? _selectedCategory),

                          decoration: InputDecoration(

                            labelText: l10n.category,

                            isDense: true,

                            border: OutlineInputBorder(

                              borderRadius: BorderRadius.circular(12),

                            ),

                          ),

                          isExpanded: true,

                        ),

                      ),

                    ],

                  ),

                  const Gap(8),



                  // -- Date Picker --
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: cs.outline.withValues(alpha: 0.5)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 16, color: cs.onSurface.withValues(alpha: 0.5)),
                          const Gap(8),
                          Text(dateStr, style: TextStyle(fontSize: 13, color: cs.onSurface)),
                        ],
                      ),
                    ),
                  ),
                  const Gap(10),



                  // -- Installment Toggle (expenses only) --

                  if (_isExpense)

                    Container(

                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

                      decoration: BoxDecoration(

                        color: _isInstallment

                            ? AppTheme.eventColor.withValues(alpha: 0.06)

                            : cs.surfaceContainerHighest.withValues(alpha: 0.4),

                        borderRadius: BorderRadius.circular(12),

                        border: Border.all(

                          color: _isInstallment

                              ? AppTheme.eventColor.withValues(alpha: 0.3)

                              : cs.outlineVariant.withValues(alpha: 0.2),

                        ),

                      ),

                      child: Column(

                        children: [

                          Row(

                            children: [

                              Icon(

                                Icons.credit_card_rounded,

                                color: _isInstallment

                                    ? AppTheme.eventColor

                                    : cs.onSurface.withValues(alpha: 0.4),

                                size: 20,

                              ),

                              const Gap(8),

                              Expanded(

                                child: Text(

                                  l10n.installmentPayment,

                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface),

                                ),

                              ),

                              SizedBox(

                                height: 32,

                                child: Switch(

                                  value: _isInstallment,

                                  onChanged: (val) {

                                    setState(() => _isInstallment = val);

                                    if (val) {

                                      Future.delayed(const Duration(milliseconds: 200), () {

                                        _amountFocusNode.requestFocus();

                                        _showAmountTooltip();

                                      });

                                    }

                                  },

                                  activeThumbColor: AppTheme.eventColor,

                                ),

                              ),

                            ],

                          ),

                          if (_isInstallment) ...[

                            const Gap(8),

                            _buildInstallmentSelector(cs),

                            const Gap(8),

                            _buildInstallmentPreview(cs),

                          ],

                        ],

                      ),

                    ),

                ],

              ),

            ),

          ),



          // -- Save Button (pinned at bottom) --

          Container(

            padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).viewPadding.bottom + 12),

            decoration: BoxDecoration(

              color: Theme.of(context).scaffoldBackgroundColor,

              boxShadow: [

                BoxShadow(

                  color: Colors.black.withValues(alpha: 0.06),

                  blurRadius: 8,

                  offset: const Offset(0, -2),

                ),

              ],

            ),

            child: SizedBox(

              width: double.infinity,

              child: ElevatedButton.icon(

                onPressed: _saveTransaction,

                icon: Icon(

                  _isInstallment ? Icons.credit_card_rounded : Icons.save_rounded,

                  size: 18,

                ),

                label: Text(

                  _isInstallment ? l10n.createInstallments(_installmentCount) : l10n.save,

                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),

                ),

                style: ElevatedButton.styleFrom(

                  padding: const EdgeInsets.symmetric(vertical: 14),

                  backgroundColor: _isExpense ? AppTheme.expenseColor : AppTheme.incomeColor,

                  foregroundColor: Colors.white,

                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),

                  elevation: 0,

                ),

              ),

            ),

          ),

        ],

      ),

    );

  }

  Widget _buildTypeButton({
    required String label,
    required bool isSelected,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.12)
              : cs.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.4)
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? color : cs.onSurface.withValues(alpha: 0.4),
              size: 20,
            ),
            const Gap(8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? color : cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstallmentSelector(ColorScheme cs) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Text(
          l10n.installmentCount,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: cs.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const Spacer(),
        // Decrement
        _buildCountButton(
          icon: Icons.remove_rounded,
          onTap: _installmentCount > 2
              ? () => setState(() => _installmentCount--)
              : null,
          cs: cs,
        ),
        Container(
          width: 48,
          alignment: Alignment.center,
          child: Text(
            '$_installmentCount',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.eventColor,
            ),
          ),
        ),
        // Increment
        _buildCountButton(
          icon: Icons.add_rounded,
          onTap: _installmentCount < 48
              ? () => setState(() => _installmentCount++)
              : null,
          cs: cs,
        ),
      ],
    );
  }

  Widget _buildCountButton({
    required IconData icon,
    required VoidCallback? onTap,
    required ColorScheme cs,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: onTap != null
              ? AppTheme.eventColor.withValues(alpha: 0.1)
              : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: onTap != null
              ? AppTheme.eventColor
              : cs.onSurface.withValues(alpha: 0.2),
        ),
      ),
    );
  }

  Widget _buildInstallmentPreview(ColorScheme cs) {
    final l10n = AppLocalizations.of(context)!;
    final amountText = _amountController.text.replaceAll(',', '.');
    final totalAmount = double.tryParse(amountText);

    if (totalAmount == null || totalAmount <= 0) {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          l10n.installmentPreviewHint,
          style: TextStyle(
            fontSize: 12,
            color: cs.onSurface.withValues(alpha: 0.4),
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    final perInstallment = totalAmount / _installmentCount;
    final localeCode = Localizations.localeOf(context).toString();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.totalAmount,
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
              ),
              Text(
                '${totalAmount.toStringAsFixed(2)} ${ref.watch(currencySymbolProvider)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const Gap(6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.monthlyInstallment,
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
              ),
              Text(
                '${perInstallment.toStringAsFixed(2)} ${ref.watch(currencySymbolProvider)} × $_installmentCount',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.eventColor,
                ),
              ),
            ],
          ),
          const Gap(6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.endDate,
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
              ),
              Text(
                DateFormat('MMM yyyy', localeCode).format(
                  DateTime(
                    _selectedDate.year,
                    _selectedDate.month + _installmentCount - 1,
                    _selectedDate.day,
                  ),
                ),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
