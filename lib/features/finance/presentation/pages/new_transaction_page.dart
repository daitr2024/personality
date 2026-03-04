// ignore_for_file: use_build_context_synchronously
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../config/theme/app_theme.dart';
import '../providers/finance_providers.dart';
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
  bool _isExpense = true;
  String _selectedCategory = 'Diğer';
  DateTime _selectedDate = DateTime.now();

  // Installment
  bool _isInstallment = false;
  int _installmentCount = 2;

  // Scanning State
  bool _isScanning = false;
  String? _receiptImagePath;

  List<String> get _categories => [
    AppLocalizations.of(context)!.categoryMarket,
    AppLocalizations.of(context)!.categoryRent,
    AppLocalizations.of(context)!.categoryBill,
    AppLocalizations.of(context)!.categorySalary,
    AppLocalizations.of(context)!.categoryOther,
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
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
          setState(() {
            _selectedCategory = result.category;
          });

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
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.'));

    if (title.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.pleaseEnterValidValues),
        ),
      );
      return;
    }

    final repo = ref.read(financeRepositoryProvider);

    if (_isInstallment && _isExpense && _installmentCount > 1) {
      // Create installment transactions
      repo.addInstallmentTransaction(
        title: title,
        totalAmount: amount,
        category: _selectedCategory,
        startDate: _selectedDate,
        installmentCount: _installmentCount,
        receiptImagePath: _receiptImagePath,
      );

      final perInstallment = amount / _installmentCount;
      final symbol = ref.read(currencySymbolProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$_installmentCount taksit oluşturuldu (${perInstallment.toStringAsFixed(2)} $symbol/ay)',
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
        _selectedCategory,
        _selectedDate,
        _isExpense,
        receiptImagePath: _receiptImagePath,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('İşlem kaydedildi'),
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
      locale: const Locale('tr'),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dateStr = DateFormat('dd MMM yyyy', 'tr').format(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.addNewTransaction),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Type Toggle ──
            Row(
              children: [
                Expanded(
                  child: _buildTypeButton(
                    label: AppLocalizations.of(context)!.expense,
                    isSelected: _isExpense,
                    color: AppTheme.expenseColor,
                    icon: Icons.arrow_downward_rounded,
                    onTap: () => setState(() => _isExpense = true),
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: _buildTypeButton(
                    label: AppLocalizations.of(context)!.income,
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
            const Gap(20),

            // ── Receipt Scan ──
            if (_isExpense) ...[
              GestureDetector(
                onTap: _scanReceipt,
                child: Container(
                  width: double.infinity,
                  height: 100,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.3),
                    ),
                    image: _receiptImagePath != null
                        ? DecorationImage(
                            image: FileImage(File(_receiptImagePath!)),
                            fit: BoxFit.cover,
                            opacity: 0.4,
                          )
                        : null,
                  ),
                  child: _isScanning
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _receiptImagePath != null
                                  ? Icons.check_circle_rounded
                                  : Icons.camera_alt_rounded,
                              color: _receiptImagePath != null
                                  ? AppTheme.completedColor
                                  : cs.onSurface.withValues(alpha: 0.4),
                              size: 28,
                            ),
                            const Gap(6),
                            Text(
                              _receiptImagePath != null
                                  ? AppLocalizations.of(context)!.receiptAdded
                                  : AppLocalizations.of(context)!.scanReceipt,
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
              const Gap(20),
            ],

            // ── Description ──
            TextField(
              controller: _titleController,
              maxLength: 40,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.description,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                prefixIcon: const Icon(Icons.text_fields_rounded, size: 20),
                helperText: AppLocalizations.of(context)!.descriptionHint,
              ),
            ),
            const Gap(12),

            // ── Amount ──
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.amount,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                prefixIcon: const Icon(Icons.attach_money_rounded, size: 20),
                suffixText: ref.watch(currencySymbolProvider),
              ),
            ),
            const Gap(12),

            // ── Category ──
            DropdownButtonFormField<String>(
              initialValue: _categories.contains(_selectedCategory)
                  ? _selectedCategory
                  : _categories.last,
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (val) =>
                  setState(() => _selectedCategory = val ?? _selectedCategory),
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.category,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                prefixIcon: const Icon(Icons.category_rounded, size: 20),
              ),
            ),
            const Gap(12),

            // ── Date Picker ──
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: cs.outline.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 20,
                      color: cs.onSurface.withValues(alpha: 0.6),
                    ),
                    const Gap(12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tarih',
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                          Text(
                            dateStr,
                            style: TextStyle(fontSize: 15, color: cs.onSurface),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: cs.onSurface.withValues(alpha: 0.3),
                    ),
                  ],
                ),
              ),
            ),
            const Gap(20),

            // ── Installment Toggle ──
            if (_isExpense) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: _isInstallment
                      ? AppTheme.eventColor.withValues(alpha: 0.06)
                      : cs.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(16),
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
                          size: 22,
                        ),
                        const Gap(12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Taksitli Ödeme',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface,
                                ),
                              ),
                              Text(
                                'Toplam tutarı aylara bölün',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: cs.onSurface.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isInstallment,
                          onChanged: (val) =>
                              setState(() => _isInstallment = val),
                          activeThumbColor: AppTheme.eventColor,
                        ),
                      ],
                    ),
                    if (_isInstallment) ...[
                      const Gap(16),
                      _buildInstallmentSelector(cs),
                      const Gap(12),
                      _buildInstallmentPreview(cs),
                    ],
                  ],
                ),
              ),
              const Gap(20),
            ],

            // ── Save Button ──
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveTransaction,
                icon: Icon(
                  _isInstallment
                      ? Icons.credit_card_rounded
                      : Icons.save_rounded,
                  size: 20,
                ),
                label: Text(
                  _isInstallment
                      ? '$_installmentCount Taksit Oluştur'
                      : AppLocalizations.of(context)!.save,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(18),
                  backgroundColor: _isExpense
                      ? AppTheme.expenseColor
                      : AppTheme.incomeColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
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
    return Row(
      children: [
        Text(
          'Taksit Sayısı',
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
          'Tutarı girdikten sonra taksit dağılımını göreceksiniz',
          style: TextStyle(
            fontSize: 12,
            color: cs.onSurface.withValues(alpha: 0.4),
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    final perInstallment = totalAmount / _installmentCount;

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
                'Toplam Tutar',
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
                'Aylık Taksit',
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
              ),
              Text(
                '${perInstallment.toStringAsFixed(2)} ${ref.watch(currencySymbolProvider)} × $_installmentCount ay',
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
                'Bitiş Tarihi',
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
              ),
              Text(
                DateFormat('MMM yyyy', 'tr').format(
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
