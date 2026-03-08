import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/services/receipt_scanner_service.dart';
import '../../../../features/settings/presentation/providers/ai_config_provider.dart';
import '../../data/repositories/finance_repository.dart';

// Database Provider
final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

// Receipt Scanner Provider
final receiptScannerServiceProvider = Provider<ReceiptScannerService>((ref) {
  final aiConfig = ref.watch(aiConfigServiceProvider);
  return ReceiptScannerService(aiConfig);
});

// Repository Provider
final financeRepositoryProvider = Provider<FinanceRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return FinanceRepository(db);
});

/// Selected month/year for finance view
final selectedMonthProvider = NotifierProvider<SelectedMonthNotifier, DateTime>(
  SelectedMonthNotifier.new,
);

class SelectedMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();

  void setMonth(DateTime month) => state = month;
}

// Transaction List Stream Provider — filtered by selected month
final transactionListProvider = StreamProvider<List<TransactionEntity>>((ref) {
  final repository = ref.watch(financeRepositoryProvider);
  final selected = ref.watch(selectedMonthProvider);
  return repository.watchMonthlyTransactions(selected.year, selected.month);
});

// All transactions (unfiltered) — for total balance calculation
final allTransactionListProvider = StreamProvider<List<TransactionEntity>>((
  ref,
) {
  final repository = ref.watch(financeRepositoryProvider);
  return repository.watchTransactions();
});

// Recurring templates
final recurringTemplatesProvider = StreamProvider<List<TransactionEntity>>((
  ref,
) {
  final repository = ref.watch(financeRepositoryProvider);
  return repository.watchRecurringTemplates();
});

// Balance Provider — total across ALL transactions
final balanceProvider = Provider<double>((ref) {
  final transactions = ref.watch(allTransactionListProvider).value ?? [];
  double balance = 0;
  for (var t in transactions) {
    if (t.isRecurring) continue; // Skip templates
    if (t.isExpense) {
      balance -= t.amount;
    } else {
      balance += t.amount;
    }
  }
  return balance;
});

// Monthly Income/Expense Totals (filtered by selected month)
final monthlyIncomeTotalProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionListProvider).value ?? [];
  return transactions
      .where((t) => !t.isExpense && !t.isRecurring)
      .fold(0.0, (sum, t) => sum + t.amount);
});

final monthlyExpenseTotalProvider = Provider<double>((ref) {
  final transactions = ref.watch(transactionListProvider).value ?? [];
  return transactions
      .where((t) => t.isExpense && !t.isRecurring)
      .fold(0.0, (sum, t) => sum + t.amount);
});

// Legacy total providers (all time — still used by some widgets)
final incomeTotalProvider = Provider<double>((ref) {
  final transactions = ref.watch(allTransactionListProvider).value ?? [];
  return transactions
      .where((t) => !t.isExpense && !t.isRecurring)
      .fold(0.0, (sum, t) => sum + t.amount);
});

final expenseTotalProvider = Provider<double>((ref) {
  final transactions = ref.watch(allTransactionListProvider).value ?? [];
  return transactions
      .where((t) => t.isExpense && !t.isRecurring)
      .fold(0.0, (sum, t) => sum + t.amount);
});

/// Group transactions by date for display
final groupedTransactionsProvider = Provider<Map<String, List<TransactionEntity>>>((
  ref,
) {
  final transactions = ref.watch(transactionListProvider).value ?? [];
  final Map<String, List<TransactionEntity>> grouped = {};

  for (final t in transactions) {
    if (t.isRecurring) continue; // Skip recurring templates
    final key =
        '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}-${t.date.day.toString().padLeft(2, '0')}';
    grouped.putIfAbsent(key, () => []);
    grouped[key]!.add(t);
  }

  return grouped;
});

/// Search query for filtering transactions
final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void setQuery(String query) => state = query;
  void clear() => state = '';
}

/// Selected category for filtering transactions (null = all)
final selectedCategoryFilterProvider =
    NotifierProvider<CategoryFilterNotifier, String?>(
      CategoryFilterNotifier.new,
    );

class CategoryFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void setCategory(String? category) => state = category;
  void clear() => state = null;
}

/// Monthly totals for chart (last 6 months)
final monthlyTotalsProvider = FutureProvider<Map<String, Map<String, double>>>((
  ref,
) {
  final repository = ref.watch(financeRepositoryProvider);
  return repository.getMonthlyTotals(6);
});
