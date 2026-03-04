import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';

class FinanceRepository {
  final AppDatabase _db;

  FinanceRepository(this._db);

  /// Watch all transactions (no filter)
  Stream<List<TransactionEntity>> watchTransactions() {
    return (_db.select(_db.transactions)..orderBy([
          (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
        ]))
        .watch();
  }

  /// Watch transactions for a specific month
  Stream<List<TransactionEntity>> watchMonthlyTransactions(
    int year,
    int month,
  ) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);

    return (_db.select(_db.transactions)
          ..where(
            (t) =>
                t.date.isBiggerOrEqualValue(start) &
                t.date.isSmallerThanValue(end),
          )
          ..orderBy([
            (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  /// Get recurring transaction templates
  Stream<List<TransactionEntity>> watchRecurringTemplates() {
    return (_db.select(_db.transactions)
          ..where((t) => t.isRecurring.equals(true))
          ..orderBy([
            (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Future<void> addTransaction(
    String title,
    double amount,
    String category,
    DateTime date,
    bool isExpense, {
    String? receiptImagePath,
    int? installmentCount,
    int? installmentCurrent,
    String? installmentGroupId,
    bool isRecurring = false,
    String? recurrenceType,
  }) async {
    await _db
        .into(_db.transactions)
        .insert(
          TransactionsCompanion.insert(
            title: title,
            amount: amount,
            category: category,
            date: date,
            isExpense: Value(isExpense),
            receiptImagePath: Value(receiptImagePath),
            installmentCount: Value(installmentCount),
            installmentCurrent: Value(installmentCurrent),
            installmentGroupId: Value(installmentGroupId),
            isRecurring: Value(isRecurring),
            recurrenceType: Value(recurrenceType),
          ),
        );
  }

  /// Add a recurring transaction template and generate instances
  Future<void> addRecurringTransaction({
    required String title,
    required double amount,
    required String category,
    required DateTime startDate,
    required bool isExpense,
    required String recurrenceType, // 'monthly', 'weekly', 'yearly'
  }) async {
    // Create the template entry
    await addTransaction(
      title,
      amount,
      category,
      startDate,
      isExpense,
      isRecurring: true,
      recurrenceType: recurrenceType,
    );
  }

  /// Add installment transactions - creates N entries for each taksit
  Future<void> addInstallmentTransaction({
    required String title,
    required double totalAmount,
    required String category,
    required DateTime startDate,
    required int installmentCount,
    String? receiptImagePath,
  }) async {
    final perInstallment = totalAmount / installmentCount;
    final groupId = '${DateTime.now().millisecondsSinceEpoch}';

    for (int i = 1; i <= installmentCount; i++) {
      final installmentDate = DateTime(
        startDate.year,
        startDate.month + (i - 1),
        startDate.day,
      );

      await _db
          .into(_db.transactions)
          .insert(
            TransactionsCompanion.insert(
              title: '$title (Taksit $i/$installmentCount)',
              amount: double.parse(perInstallment.toStringAsFixed(2)),
              category: category,
              date: installmentDate,
              isExpense: const Value(true),
              receiptImagePath: Value(i == 1 ? receiptImagePath : null),
              installmentCount: Value(installmentCount),
              installmentCurrent: Value(i),
              installmentGroupId: Value(groupId),
            ),
          );
    }
  }

  Future<void> updateTransaction(
    int id, {
    String? title,
    double? amount,
    String? category,
    DateTime? date,
    bool? isExpense,
  }) async {
    await (_db.update(_db.transactions)..where((t) => t.id.equals(id))).write(
      TransactionsCompanion(
        title: title != null ? Value(title) : const Value.absent(),
        amount: amount != null ? Value(amount) : const Value.absent(),
        category: category != null ? Value(category) : const Value.absent(),
        date: date != null ? Value(date) : const Value.absent(),
        isExpense: isExpense != null ? Value(isExpense) : const Value.absent(),
      ),
    );
  }

  Future<void> deleteTransaction(int id) async {
    await (_db.delete(_db.transactions)..where((t) => t.id.equals(id))).go();
  }

  /// Delete all installments in a group
  Future<void> deleteInstallmentGroup(String groupId) async {
    await (_db.delete(
      _db.transactions,
    )..where((t) => t.installmentGroupId.equals(groupId))).go();
  }

  /// Get all installments in a group
  Future<List<TransactionEntity>> getInstallmentGroup(String groupId) async {
    return (_db.select(_db.transactions)
          ..where((t) => t.installmentGroupId.equals(groupId))
          ..orderBy([
            (t) => OrderingTerm(
              expression: t.installmentCurrent,
              mode: OrderingMode.asc,
            ),
          ]))
        .get();
  }

  /// Get monthly totals for a range (for mini chart)
  Future<Map<String, Map<String, double>>> getMonthlyTotals(
    int monthsBack,
  ) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - monthsBack + 1, 1);
    final transactions =
        await (_db.select(_db.transactions)
              ..where((t) => t.date.isBiggerOrEqualValue(start))
              ..where((t) => t.isRecurring.equals(false)))
            .get();

    final Map<String, Map<String, double>> result = {};

    for (final t in transactions) {
      final key = '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}';
      result.putIfAbsent(key, () => {'income': 0, 'expense': 0});
      if (t.isExpense) {
        result[key]!['expense'] = result[key]!['expense']! + t.amount;
      } else {
        result[key]!['income'] = result[key]!['income']! + t.amount;
      }
    }

    return result;
  }
}
