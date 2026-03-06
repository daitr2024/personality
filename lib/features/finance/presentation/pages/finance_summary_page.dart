import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../core/database/app_database.dart';
import '../providers/finance_providers.dart';
import '../../../home/presentation/widgets/home_header.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../settings/presentation/providers/currency_provider.dart';
import '../../../../core/widgets/attachment_manager.dart';

class FinanceSummaryPage extends ConsumerWidget {
  const FinanceSummaryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionListProvider);
    final monthlyIncome = ref.watch(monthlyIncomeTotalProvider);
    final monthlyExpense = ref.watch(monthlyExpenseTotalProvider);
    final balance = ref.watch(balanceProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);
    final groupedTx = ref.watch(groupedTransactionsProvider);

    final localeCode = Localizations.localeOf(context).toString();
    final currencySymbol = ref.watch(currencySymbolProvider);
    final currencyFormat = NumberFormat.currency(
      locale: localeCode,
      symbol: currencySymbol,
      decimalDigits: 2,
    );

    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const HomeHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  const Gap(8),
                  // ── Month Navigator ──
                  _buildMonthNavigator(context, ref, selectedMonth),
                  const Gap(16),

                  // ── Balance Card ──
                  _buildBalanceCard(
                    context,
                    ref,
                    balance,
                    monthlyIncome,
                    monthlyExpense,
                    currencyFormat,
                    selectedMonth,
                  ),
                  const Gap(20),

                  // ── Recurring Section ──
                  _buildRecurringSection(context, ref, currencyFormat, cs),

                  // ── Transactions by Date ──
                  transactionsAsync.when(
                    data: (transactions) {
                      final nonRecurring = transactions
                          .where((t) => !t.isRecurring)
                          .toList();
                      if (nonRecurring.isEmpty) {
                        return _buildEmptyState(context, selectedMonth);
                      }
                      return _buildGroupedTransactions(
                        context,
                        ref,
                        groupedTx,
                        currencyFormat,
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(
                      child: Text(
                        '${AppLocalizations.of(context)!.error}: $err',
                      ),
                    ),
                  ),
                  const Gap(80),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/finance/new'),
        icon: const Icon(Icons.add_rounded, size: 20),
        label: Text(
          AppLocalizations.of(context)!.addNewTransaction,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 2,
      ),
    );
  }

  // ─── Month Navigator ───────────────────────────────────────────

  Widget _buildMonthNavigator(
    BuildContext context,
    WidgetRef ref,
    DateTime selected,
  ) {
    final cs = Theme.of(context).colorScheme;
    final monthLabel = DateFormat('MMMM yyyy', 'tr').format(selected);
    final isCurrentMonth =
        selected.year == DateTime.now().year &&
        selected.month == DateTime.now().month;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () {
            ref
                .read(selectedMonthProvider.notifier)
                .setMonth(DateTime(selected.year, selected.month - 1));
          },
          icon: Icon(Icons.chevron_left_rounded, color: cs.primary),
          style: IconButton.styleFrom(
            backgroundColor: cs.primary.withValues(alpha: 0.08),
          ),
        ),
        GestureDetector(
          onTap: isCurrentMonth
              ? null
              : () {
                  ref
                      .read(selectedMonthProvider.notifier)
                      .setMonth(DateTime.now());
                },
          child: Column(
            children: [
              Text(
                monthLabel.toUpperCase(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                  letterSpacing: 0.5,
                ),
              ),
              if (!isCurrentMonth) ...[
                const Gap(2),
                Text(
                  'Bugüne dön',
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
        IconButton(
          onPressed: isCurrentMonth
              ? null
              : () {
                  ref
                      .read(selectedMonthProvider.notifier)
                      .setMonth(DateTime(selected.year, selected.month + 1));
                },
          icon: Icon(
            Icons.chevron_right_rounded,
            color: isCurrentMonth
                ? cs.onSurface.withValues(alpha: 0.15)
                : cs.primary,
          ),
          style: IconButton.styleFrom(
            backgroundColor: isCurrentMonth
                ? Colors.transparent
                : cs.primary.withValues(alpha: 0.08),
          ),
        ),
      ],
    );
  }

  // ─── Balance Card ──────────────────────────────────────────────

  Widget _buildBalanceCard(
    BuildContext context,
    WidgetRef ref,
    double totalBalance,
    double monthlyIncome,
    double monthlyExpense,
    NumberFormat format,
    DateTime selectedMonth,
  ) {
    final cs = Theme.of(context).colorScheme;
    final monthlyBalance = monthlyIncome - monthlyExpense;
    final monthLabel = DateFormat('MMMM', 'tr').format(selectedMonth);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.primary.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Total balance
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.totalBalance,
                    style: TextStyle(
                      color: cs.onPrimary.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    format.format(totalBalance),
                    style: TextStyle(
                      color: cs.onPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              // Monthly net indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: cs.onPrimary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      monthLabel,
                      style: TextStyle(
                        color: cs.onPrimary.withValues(alpha: 0.7),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Gap(2),
                    Text(
                      '${monthlyBalance >= 0 ? '+' : ''}${format.format(monthlyBalance)}',
                      style: TextStyle(
                        color: monthlyBalance >= 0
                            ? AppTheme.incomeColor
                            : AppTheme.expenseColor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap(20),
          // Income / Expense row
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _showAddIncomeDialog(context, ref),
                  child: _buildMiniStat(
                    context,
                    Icons.arrow_upward_rounded,
                    AppLocalizations.of(context)!.income,
                    format.format(monthlyIncome),
                    AppTheme.incomeColor,
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: cs.onPrimary.withValues(alpha: 0.15),
              ),
              Expanded(
                child: _buildMiniStat(
                  context,
                  Icons.arrow_downward_rounded,
                  AppLocalizations.of(context)!.expense,
                  format.format(monthlyExpense),
                  AppTheme.expenseColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const Gap(6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: cs.onPrimary.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: cs.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Recurring Section ─────────────────────────────────────────

  Widget _buildRecurringSection(
    BuildContext context,
    WidgetRef ref,
    NumberFormat format,
    ColorScheme cs,
  ) {
    final recurringAsync = ref.watch(recurringTemplatesProvider);

    return recurringAsync.when(
      data: (templates) {
        if (templates.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.repeat_rounded,
                  size: 18,
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
                const Gap(8),
                Text(
                  'Sabit Gelir / Gider',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            const Gap(10),
            SizedBox(
              height: 70,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: templates.length + 1,
                separatorBuilder: (_, _) => const Gap(10),
                itemBuilder: (context, index) {
                  if (index == templates.length) {
                    return _buildAddRecurringChip(context, ref);
                  }
                  final t = templates[index];
                  return _buildRecurringChip(context, ref, t, format, cs);
                },
              ),
            ),
            const Gap(20),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildRecurringChip(
    BuildContext context,
    WidgetRef ref,
    TransactionEntity t,
    NumberFormat format,
    ColorScheme cs,
  ) {
    final color = t.isExpense ? AppTheme.expenseColor : AppTheme.incomeColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onLongPress: () => _showDeleteRecurringDialog(context, ref, t),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? color.withValues(alpha: 0.08)
              : color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              t.title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Gap(4),
            Text(
              '${t.isExpense ? '-' : '+'}${format.format(t.amount)}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              _getRecurrenceLabel(t.recurrenceType ?? 'monthly'),
              style: TextStyle(
                fontSize: 10,
                color: cs.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddRecurringChip(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => _showAddRecurringDialog(context, ref),
      child: Container(
        width: 70,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.15)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_rounded,
              size: 22,
              color: cs.onSurface.withValues(alpha: 0.3),
            ),
            const Gap(2),
            Text(
              'Ekle',
              style: TextStyle(
                fontSize: 10,
                color: cs.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRecurrenceLabel(String type) {
    switch (type) {
      case 'weekly':
        return 'Haftalık';
      case 'yearly':
        return 'Yıllık';
      default:
        return 'Aylık';
    }
  }

  // ─── Grouped Transactions ──────────────────────────────────────

  Widget _buildGroupedTransactions(
    BuildContext context,
    WidgetRef ref,
    Map<String, List<TransactionEntity>> grouped,
    NumberFormat format,
  ) {
    final cs = Theme.of(context).colorScheme;
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sortedKeys.map((dateKey) {
        final dayTransactions = grouped[dateKey]!;
        final date = DateTime.parse(dateKey);
        final dayLabel = _formatDayLabel(date);
        final dayTotal = dayTransactions.fold<double>(
          0,
          (sum, t) => sum + (t.isExpense ? -t.amount : t.amount),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dayLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  Text(
                    '${dayTotal >= 0 ? '+' : ''}${format.format(dayTotal)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: dayTotal >= 0
                          ? AppTheme.incomeColor
                          : AppTheme.expenseColor,
                    ),
                  ),
                ],
              ),
            ),
            // Transaction cards
            ...dayTransactions.map(
              (t) => _buildTransactionItem(context, ref, t, format),
            ),
          ],
        );
      }).toList(),
    );
  }

  String _formatDayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);

    if (d == today) return 'Bugün';
    if (d == yesterday) return 'Dün';
    return DateFormat('d MMMM EEEE', 'tr').format(date);
  }

  // ─── Empty State ───────────────────────────────────────────────

  Widget _buildEmptyState(BuildContext context, DateTime selectedMonth) {
    final cs = Theme.of(context).colorScheme;
    final monthLabel = DateFormat('MMMM yyyy', 'tr').format(selectedMonth);

    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(
            Icons.account_balance_wallet_rounded,
            size: 42,
            color: cs.onSurface.withValues(alpha: 0.2),
          ),
          const Gap(12),
          Text(
            '$monthLabel için işlem bulunamadı',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: cs.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Transaction Item ──────────────────────────────────────────

  Widget _buildTransactionItem(
    BuildContext context,
    WidgetRef ref,
    TransactionEntity t,
    NumberFormat format,
  ) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final itemColor = t.isExpense
        ? AppTheme.expenseColor
        : AppTheme.incomeColor;
    final timeStr = DateFormat('HH:mm').format(t.date);
    final hasInstallment =
        t.installmentCount != null && t.installmentCount! > 1;

    return Dismissible(
      key: Key('transaction_${t.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.urgentColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete_rounded,
          color: AppTheme.urgentColor,
          size: 22,
        ),
      ),
      confirmDismiss: (direction) async {
        return await _showDeleteConfirmation(context, ref, t);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isDark ? cs.surfaceContainerHigh : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: isDark ? 0.12 : 0.15),
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showEditDialog(context, ref, t),
          onLongPress: () => _showTransactionOptions(context, ref, t),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Category icon
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: itemColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getCategoryIcon(t.category, t.isExpense),
                    color: itemColor,
                    size: 18,
                  ),
                ),
                const Gap(12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Gap(3),
                      Row(
                        children: [
                          // Category badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              t.category,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: cs.primary.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                          const Gap(6),
                          // Time
                          Text(
                            timeStr,
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurface.withValues(alpha: 0.35),
                            ),
                          ),
                          if (hasInstallment) ...[
                            const Gap(6),
                            Icon(
                              Icons.credit_card_rounded,
                              size: 12,
                              color: cs.onSurface.withValues(alpha: 0.35),
                            ),
                            const Gap(3),
                            Text(
                              '${t.installmentCurrent}/${t.installmentCount}',
                              style: TextStyle(
                                fontSize: 10,
                                color: cs.onSurface.withValues(alpha: 0.35),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Amount
                Text(
                  t.isExpense
                      ? '-${format.format(t.amount)}'
                      : '+${format.format(t.amount)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: itemColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category, bool isExpense) {
    final lower = category.toLowerCase();
    if (lower.contains('market') || lower.contains('alışveriş')) {
      return Icons.shopping_cart_rounded;
    }
    if (lower.contains('kira') || lower.contains('rent')) {
      return Icons.home_rounded;
    }
    if (lower.contains('fatura') || lower.contains('bill')) {
      return Icons.receipt_long_rounded;
    }
    if (lower.contains('maaş') ||
        lower.contains('salary') ||
        lower.contains('income')) {
      return Icons.account_balance_rounded;
    }
    if (lower.contains('ulaşım') || lower.contains('transport')) {
      return Icons.directions_car_rounded;
    }
    if (lower.contains('yemek') || lower.contains('food')) {
      return Icons.restaurant_rounded;
    }
    if (lower.contains('sağlık') || lower.contains('health')) {
      return Icons.medical_services_rounded;
    }
    if (lower.contains('eğitim') || lower.contains('education')) {
      return Icons.school_rounded;
    }
    if (lower.contains('eğlence') || lower.contains('entertainment')) {
      return Icons.movie_rounded;
    }
    if (lower.contains('abonelik') || lower.contains('subscription')) {
      return Icons.subscriptions_rounded;
    }
    if (!isExpense) {
      return Icons.arrow_upward_rounded;
    }
    return Icons.arrow_downward_rounded;
  }

  // ─── Transaction Options Bottom Sheet ──────────────────────────

  void _showTransactionOptions(
    BuildContext context,
    WidgetRef ref,
    TransactionEntity t,
  ) {
    final cs = Theme.of(context).colorScheme;
    final hasInstallmentGroup =
        t.installmentGroupId != null && t.installmentGroupId!.isNotEmpty;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Gap(16),
              Text(
                t.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Gap(16),
              ListTile(
                leading: Icon(Icons.edit_rounded, color: cs.primary),
                title: const Text('Düzenle'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditDialog(context, ref, t);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_rounded,
                  color: AppTheme.urgentColor,
                ),
                title: Text(AppLocalizations.of(context)!.delete),
                onTap: () {
                  Navigator.pop(ctx);
                  _showDeleteConfirmation(context, ref, t);
                },
              ),
              if (hasInstallmentGroup) ...[
                const Divider(),
                ListTile(
                  leading: Icon(Icons.view_list_rounded, color: cs.primary),
                  title: const Text('Tüm Taksitleri Gör'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showInstallmentDetails(context, ref, t);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.delete_sweep_rounded,
                    color: AppTheme.urgentColor,
                  ),
                  title: const Text('Tüm Taksitleri Sil'),
                  subtitle: const Text(
                    'Bu işlemin tüm taksitlerini siler',
                    style: TextStyle(fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _deleteInstallmentGroup(context, ref, t);
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─── Edit Dialog ───────────────────────────────────────────────

  void _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    TransactionEntity t,
  ) {
    final titleController = TextEditingController(text: t.title);
    final amountController = TextEditingController(
      text: t.amount.toStringAsFixed(2),
    );
    final cs = Theme.of(context).colorScheme;
    final currencySymbol = ref.read(currencySymbolProvider);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.edit_rounded, color: cs.primary, size: 20),
            ),
            const Gap(12),
            const Text('İşlemi Düzenle'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Açıklama',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.text_fields_rounded, size: 20),
                ),
              ),
              const Gap(12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Tutar',
                  suffixText: currencySymbol,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.attach_money_rounded, size: 20),
                ),
              ),
              const Gap(16),
              AttachmentManager(
                itemId: t.id,
                source: AttachmentSource.transaction,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleController.text.trim();
              final amount = double.tryParse(
                amountController.text.replaceAll(',', '.'),
              );
              if (title.isNotEmpty && amount != null && amount > 0) {
                ref
                    .read(financeRepositoryProvider)
                    .updateTransaction(t.id, title: title, amount: amount);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('İşlem güncellendi'),
                    backgroundColor: AppTheme.completedColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );
  }

  // ─── Delete Confirmation ───────────────────────────────────────

  Future<bool> _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    TransactionEntity t,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.urgentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.delete_rounded,
                color: AppTheme.urgentColor,
                size: 20,
              ),
            ),
            const Gap(12),
            const Text('İşlemi Sil'),
          ],
        ),
        content: Text(
          '"${t.title}" işlemini silmek istediğinize emin misiniz?',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(financeRepositoryProvider).deleteTransaction(t.id);
              Navigator.pop(ctx, true);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('İşlem silindi'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.urgentColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  // ─── Installment Details ───────────────────────────────────────

  void _showInstallmentDetails(
    BuildContext context,
    WidgetRef ref,
    TransactionEntity t,
  ) async {
    if (t.installmentGroupId == null) return;

    final installments = await ref
        .read(financeRepositoryProvider)
        .getInstallmentGroup(t.installmentGroupId!);

    if (!context.mounted) return;

    final cs = Theme.of(context).colorScheme;
    final currencySymbol = ref.read(currencySymbolProvider);
    final totalAmount = installments.fold(0.0, (sum, i) => sum + i.amount);
    final paidCount = installments
        .where((i) => i.date.isBefore(DateTime.now()))
        .length;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.eventColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.credit_card_rounded,
                color: AppTheme.eventColor,
                size: 20,
              ),
            ),
            const Gap(12),
            const Expanded(child: Text('Taksit Detayları')),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildInstallmentStat(
                      'Toplam',
                      '${totalAmount.toStringAsFixed(2)} $currencySymbol',
                      cs,
                    ),
                    _buildInstallmentStat(
                      'Ödenen',
                      '$paidCount/${installments.length}',
                      cs,
                    ),
                    _buildInstallmentStat(
                      'Kalan',
                      '${installments.length - paidCount}',
                      cs,
                    ),
                  ],
                ),
              ),
              const Gap(12),
              SizedBox(
                height: 250,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: installments.length,
                  itemBuilder: (ctx, index) {
                    final inst = installments[index];
                    final isPast = inst.date.isBefore(DateTime.now());
                    final dateStr = DateFormat(
                      'dd MMM yyyy',
                      'tr',
                    ).format(inst.date);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isPast
                            ? AppTheme.completedColor.withValues(alpha: 0.06)
                            : cs.surfaceContainerHighest.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isPast
                              ? AppTheme.completedColor.withValues(alpha: 0.2)
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isPast
                                ? Icons.check_circle_rounded
                                : Icons.schedule_rounded,
                            size: 18,
                            color: isPast
                                ? AppTheme.completedColor
                                : cs.onSurface.withValues(alpha: 0.4),
                          ),
                          const Gap(10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Taksit ${inst.installmentCurrent}/${inst.installmentCount}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: cs.onSurface,
                                  ),
                                ),
                                Text(
                                  dateStr,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: cs.onSurface.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${inst.amount.toStringAsFixed(2)} $currencySymbol',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isPast
                                  ? AppTheme.completedColor
                                  : AppTheme.expenseColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Widget _buildInstallmentStat(String label, String value, ColorScheme cs) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: cs.onSurface,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: cs.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  // ─── Delete Installment Group ──────────────────────────────────

  void _deleteInstallmentGroup(
    BuildContext context,
    WidgetRef ref,
    TransactionEntity t,
  ) async {
    if (t.installmentGroupId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Tüm Taksitleri Sil'),
        content: Text(
          'Bu işlemin tüm ${t.installmentCount} taksitini silmek istediğinize emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.urgentColor,
              elevation: 0,
            ),
            child: const Text('Tümünü Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref
          .read(financeRepositoryProvider)
          .deleteInstallmentGroup(t.installmentGroupId!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Tüm taksitler silindi'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  // ─── Add Recurring Dialog ──────────────────────────────────────

  void _showAddRecurringDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final cs = Theme.of(context).colorScheme;
    final currencySymbol = ref.read(currencySymbolProvider);
    bool isExpense = true;
    String recurrenceType = 'monthly';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.repeat_rounded, color: cs.primary, size: 20),
              ),
              const Gap(12),
              const Expanded(child: Text('Sabit Gelir / Gider')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Income / Expense toggle
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => isExpense = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isExpense
                                ? AppTheme.expenseColor.withValues(alpha: 0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isExpense
                                  ? AppTheme.expenseColor.withValues(alpha: 0.3)
                                  : Colors.transparent,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Gider',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isExpense
                                  ? AppTheme.expenseColor
                                  : cs.onSurface.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Gap(8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => isExpense = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !isExpense
                                ? AppTheme.incomeColor.withValues(alpha: 0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: !isExpense
                                  ? AppTheme.incomeColor.withValues(alpha: 0.3)
                                  : Colors.transparent,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Gelir',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: !isExpense
                                  ? AppTheme.incomeColor
                                  : cs.onSurface.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(14),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Açıklama (ör: Maaş, Kira)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.text_fields_rounded, size: 20),
                  ),
                ),
                const Gap(12),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Tutar',
                    suffixText: currencySymbol,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(
                      Icons.attach_money_rounded,
                      size: 20,
                    ),
                  ),
                ),
                const Gap(12),
                // Recurrence selector
                Row(
                  children: [
                    Text(
                      'Periyot:',
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const Gap(8),
                    ..._buildRecurrenceChips(
                      recurrenceType,
                      cs,
                      (type) => setState(() => recurrenceType = type),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                final title = titleController.text.trim();
                final amount = double.tryParse(
                  amountController.text.replaceAll(',', '.'),
                );
                if (title.isNotEmpty && amount != null && amount > 0) {
                  ref
                      .read(financeRepositoryProvider)
                      .addRecurringTransaction(
                        title: title,
                        amount: amount,
                        category: isExpense ? 'Sabit Gider' : 'Sabit Gelir',
                        startDate: DateTime.now(),
                        isExpense: isExpense,
                        recurrenceType: recurrenceType,
                      );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Sabit işlem eklendi'),
                      backgroundColor: AppTheme.completedColor,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text('Ekle'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRecurrenceChips(
    String selected,
    ColorScheme cs,
    ValueChanged<String> onSelect,
  ) {
    final options = [
      ('monthly', 'Aylık'),
      ('weekly', 'Haftalık'),
      ('yearly', 'Yıllık'),
    ];

    return options
        .map(
          (opt) => Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => onSelect(opt.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: selected == opt.$1
                      ? cs.primary.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected == opt.$1
                        ? cs.primary.withValues(alpha: 0.3)
                        : cs.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  opt.$2,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: selected == opt.$1
                        ? cs.primary
                        : cs.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),
        )
        .toList();
  }

  void _showDeleteRecurringDialog(
    BuildContext context,
    WidgetRef ref,
    TransactionEntity t,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sabit İşlemi Sil'),
        content: Text('"${t.title}" sabit işlemini silmek istiyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(financeRepositoryProvider).deleteTransaction(t.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.urgentColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );
  }

  // ─── Quick Add Income Dialog (from summary card) ───────────────

  void _showAddIncomeDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final currencySymbol = ref.read(currencySymbolProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(AppLocalizations.of(context)!.addIncome),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Açıklama',
                  hintText: 'ör: Maaş, Freelance',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.text_fields_rounded, size: 20),
                ),
              ),
              const Gap(12),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(
                    context,
                  )!.amountWithCurrency(currencySymbol),
                  suffixText: currencySymbol,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.attach_money_rounded, size: 20),
                ),
                autofocus: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleController.text.trim();
              final amount = double.tryParse(
                amountController.text.replaceAll(',', '.'),
              );
              if (amount != null && amount > 0) {
                ref
                    .read(financeRepositoryProvider)
                    .addTransaction(
                      title.isNotEmpty
                          ? title
                          : AppLocalizations.of(context)!.incomeAddition,
                      amount,
                      'Income',
                      DateTime.now(),
                      false,
                    );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.incomeAdded),
                    backgroundColor: AppTheme.completedColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(AppLocalizations.of(context)!.add),
          ),
        ],
      ),
    );
  }
}
