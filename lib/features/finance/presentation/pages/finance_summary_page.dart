import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../core/database/app_database.dart';
import '../providers/finance_providers.dart';
import '../utils/currency_input_formatter.dart';
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
    final selectedMonth = ref.watch(selectedMonthProvider);

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
                  // -- Month Navigator --
                  _buildMonthNavigator(context, ref, selectedMonth),
                  const Gap(16),

                  // -- Income vs Expense Balance Bar --
                  _buildBalanceBar(
                    context,
                    monthlyIncome,
                    monthlyExpense,
                    cs,
                    currencyFormat,
                  ),
                  const Gap(16),

                  // ── Recurring Section ──
                  _buildRecurringSection(context, ref, currencyFormat, cs),

                  // ── Search & Filter ──
                  _buildSearchFilterBar(context, ref, cs),
                  const Gap(8),

                  // ── Transactions by Date ──
                  transactionsAsync.when(
                    data: (transactions) {
                      final nonRecurring = transactions
                          .where((t) => !t.isRecurring)
                          .toList();

                      // Apply search and category filter
                      final searchQuery = ref
                          .watch(searchQueryProvider)
                          .toLowerCase();
                      final selectedCategory = ref.watch(
                        selectedCategoryFilterProvider,
                      );

                      final filtered = nonRecurring.where((t) {
                        final matchesSearch =
                            searchQuery.isEmpty ||
                            t.title.toLowerCase().contains(searchQuery) ||
                            (t.note ?? '').toLowerCase().contains(searchQuery);
                        final matchesCategory =
                            selectedCategory == null ||
                            t.category == selectedCategory;
                        return matchesSearch && matchesCategory;
                      }).toList();

                      if (filtered.isEmpty) {
                        if (searchQuery.isNotEmpty ||
                            selectedCategory != null) {
                          return _buildNoResultsState(context, cs);
                        }
                        return _buildEmptyState(context, selectedMonth);
                      }

                      // Re-group filtered transactions
                      final Map<String, List<TransactionEntity>>
                      filteredGrouped = {};
                      for (final t in filtered) {
                        final key =
                            '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}-${t.date.day.toString().padLeft(2, '0')}';
                        filteredGrouped.putIfAbsent(key, () => []);
                        filteredGrouped[key]!.add(t);
                      }

                      return _buildGroupedTransactions(
                        context,
                        ref,
                        filteredGrouped,
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
    final localeCode = Localizations.localeOf(context).toString();
    final monthLabel = DateFormat('MMMM yyyy', localeCode).format(selected);
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
                  AppLocalizations.of(context)!.returnToToday,
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
                  AppLocalizations.of(context)!.fixedIncomeExpense,
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
              AppLocalizations.of(context)!.addLabel,
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
        return 'Weekly';
      case 'yearly':
        return 'Yearly';
      default:
        return 'Monthly';
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
        final dayLabel = _formatDayLabel(context, date);
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

  String _formatDayLabel(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);

    if (d == today) return AppLocalizations.of(context)!.dayToday;
    if (d == yesterday) return AppLocalizations.of(context)!.dayYesterday;
    final localeCode = Localizations.localeOf(context).toString();
    return DateFormat('d MMMM EEEE', localeCode).format(date);
  }

  Widget _buildBalanceBar(
    BuildContext context,
    double income,
    double expense,
    ColorScheme cs,
    NumberFormat currencyFormat,
  ) {
    final total = income + expense;
    if (total == 0) return const SizedBox.shrink();

    final incomeRatio = income / total;
    final expenseRatio = expense / total;
    final isHealthy = income >= expense;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Icon(
                isHealthy ? Icons.thumb_up_rounded : Icons.warning_rounded,
                size: 18,
                color: isHealthy ? AppTheme.incomeColor : AppTheme.expenseColor,
              ),
              const Gap(8),
              Text(
                isHealthy ? l10n.income : l10n.expense,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isHealthy
                      ? AppTheme.incomeColor
                      : AppTheme.expenseColor,
                ),
              ),
              Text(
                isHealthy ? ' > ' : ' > ',
                style: TextStyle(
                  fontSize: 14,
                  color: cs.onSurface.withValues(alpha: 0.4),
                ),
              ),
              Text(
                isHealthy ? l10n.expense : l10n.income,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isHealthy
                      ? AppTheme.expenseColor
                      : AppTheme.incomeColor,
                ),
              ),
              const Spacer(),
              Icon(
                isHealthy ? Icons.check_circle_rounded : Icons.error_rounded,
                size: 16,
                color: isHealthy ? AppTheme.incomeColor : AppTheme.expenseColor,
              ),
            ],
          ),
          const Gap(12),

          // Horizontal balance bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 20,
              child: Row(
                children: [
                  // Income portion (green)
                  Expanded(
                    flex: (incomeRatio * 1000).round().clamp(1, 999),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.incomeColor.withValues(alpha: 0.7),
                            AppTheme.incomeColor,
                          ],
                        ),
                      ),
                      alignment: Alignment.center,
                      child: incomeRatio > 0.15
                          ? Text(
                              '${(incomeRatio * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                  ),
                  // Expense portion (red)
                  Expanded(
                    flex: (expenseRatio * 1000).round().clamp(1, 999),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.expenseColor,
                            AppTheme.expenseColor.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                      alignment: Alignment.center,
                      child: expenseRatio > 0.15
                          ? Text(
                              '${(expenseRatio * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Gap(10),

          // Legend row
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppTheme.incomeColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const Gap(4),
              Text(
                currencyFormat.format(income),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.incomeColor,
                ),
              ),
              const Spacer(),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppTheme.expenseColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const Gap(4),
              Text(
                currencyFormat.format(expense),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.expenseColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Search & Filter Bar ─────────────────────────────────────────

  Widget _buildSearchFilterBar(
    BuildContext context,
    WidgetRef ref,
    ColorScheme cs,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final searchQuery = ref.watch(searchQueryProvider);
    final selectedCategory = ref.watch(selectedCategoryFilterProvider);

    // Collect unique categories from current transactions
    final transactions = ref.watch(transactionListProvider).value ?? [];
    final categories =
        transactions
            .where((t) => !t.isRecurring)
            .map((t) => t.category)
            .toSet()
            .toList()
          ..sort();

    return Column(
      children: [
        // Search Field
        TextField(
          decoration: InputDecoration(
            hintText: l10n.searchTransactions,
            hintStyle: TextStyle(
              color: cs.onSurface.withValues(alpha: 0.3),
              fontSize: 13,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              size: 20,
              color: cs.onSurface.withValues(alpha: 0.3),
            ),
            suffixIcon: searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear_rounded,
                      size: 18,
                      color: cs.onSurface.withValues(alpha: 0.4),
                    ),
                    onPressed: () {
                      ref.read(searchQueryProvider.notifier).clear();
                    },
                  )
                : null,
            filled: true,
            fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.4),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          onChanged: (value) {
            ref.read(searchQueryProvider.notifier).setQuery(value);
          },
        ),
        const Gap(8),
        // Category Filter Chips
        if (categories.isNotEmpty)
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // "All" chip
                _buildFilterChip(
                  label: l10n.allCategories,
                  isSelected: selectedCategory == null,
                  onTap: () {
                    ref.read(selectedCategoryFilterProvider.notifier).clear();
                  },
                  cs: cs,
                ),
                const Gap(6),
                // Category chips
                ...categories.map(
                  (cat) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _buildFilterChip(
                      label: cat,
                      isSelected: selectedCategory == cat,
                      onTap: () {
                        ref
                            .read(selectedCategoryFilterProvider.notifier)
                            .setCategory(cat);
                      },
                      cs: cs,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ColorScheme cs,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? cs.primary.withValues(alpha: 0.15)
              : cs.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? cs.primary.withValues(alpha: 0.4)
                : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected
                ? cs.primary
                : cs.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  // ─── No Results State (for search/filter) ────────────────────────

  Widget _buildNoResultsState(BuildContext context, ColorScheme cs) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 42,
            color: cs.onSurface.withValues(alpha: 0.2),
          ),
          const Gap(12),
          Text(
            l10n.noResultsFound,
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

  // ─── Empty State ───────────────────────────────────────────────

  Widget _buildEmptyState(BuildContext context, DateTime selectedMonth) {
    final cs = Theme.of(context).colorScheme;
    final monthLabel = DateFormat(
      'MMMM yyyy',
      Localizations.localeOf(context).toString(),
    ).format(selectedMonth);

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
            AppLocalizations.of(context)!.noTransactionsForMonth(monthLabel),
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
    // Market / Yeme-İçme (Shopping & Food)
    if (lower.contains('market') ||
        lower.contains('shopping') ||
        lower.contains('yeme') ||
        lower.contains('food')) {
      return Icons.shopping_cart_rounded;
    }
    // Konut / Faturalar (Housing & Bills)
    if (lower.contains('konut') ||
        lower.contains('housing') ||
        lower.contains('fatura') ||
        lower.contains('bill')) {
      return Icons.home_rounded;
    }
    // Ulaşım (Transport)
    if (lower.contains('transport') || lower.contains('ula')) {
      return Icons.directions_car_rounded;
    }
    // Sağlık (Health)
    if (lower.contains('health') || lower.contains('sa')) {
      return Icons.medical_services_rounded;
    }
    // Kişisel (Personal)
    if (lower.contains('personal') || lower.contains('ki')) {
      return Icons.person_rounded;
    }
    // Abonelik / Teknoloji (Subscription & Tech)
    if (lower.contains('abonelik') ||
        lower.contains('subscription') ||
        lower.contains('tech') ||
        lower.contains('teknoloji')) {
      return Icons.devices_rounded;
    }
    // Bağış (Donation)
    if (lower.contains('donation')) {
      return Icons.volunteer_activism_rounded;
    }
    // Maaş (Salary)
    if (lower.contains('maa') || lower.contains('salary')) {
      return Icons.account_balance_rounded;
    }
    // Yatırım / Kira Geliri (Investment & Rental)
    if (lower.contains('yat') ||
        lower.contains('invest') ||
        lower.contains('rental')) {
      return Icons.trending_up_rounded;
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
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  CurrencyInputFormatter(
                    locale: Localizations.localeOf(context).toString(),
                  ),
                ],
                decoration: InputDecoration(
                  labelText: 'Tutar',
                  suffixText: currencySymbol,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 12, right: 4),
                    child: Text(
                      currencySymbol,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 0,
                  ),
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
              final amount = parseCurrencyInput(
                amountController.text,
                Localizations.localeOf(context).toString(),
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
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    CurrencyInputFormatter(
                      locale: Localizations.localeOf(context).toString(),
                    ),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Tutar',
                    suffixText: currencySymbol,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 12, right: 4),
                      child: Text(
                        currencySymbol,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 0,
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
                final amount = parseCurrencyInput(
                  amountController.text,
                  Localizations.localeOf(context).toString(),
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
}
