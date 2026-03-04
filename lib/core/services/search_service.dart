import '../database/app_database.dart';
import 'package:drift/drift.dart';

/// Simple search service for tasks, notes, and transactions
class SearchService {
  final AppDatabase _database;

  SearchService(this._database);

  /// Search tasks by title
  Future<List<TaskEntity>> searchTasks({
    required String query,
    DateTime? startDate,
    DateTime? endDate,
    List<int>? tagIds,
  }) async {
    if (query.isEmpty &&
        tagIds == null &&
        startDate == null &&
        endDate == null) {
      return [];
    }

    var selectQuery = _database.select(_database.tasks)
      ..where((t) => t.isDeleted.equals(false));

    // Date range filter
    if (startDate != null) {
      selectQuery = selectQuery
        ..where((t) => t.date.isBiggerOrEqualValue(startDate));
    }
    if (endDate != null) {
      final endOfDay = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        23,
        59,
        59,
      );
      selectQuery = selectQuery
        ..where((t) => t.date.isSmallerOrEqualValue(endOfDay));
    }

    var results = await selectQuery.get();

    // Text search (client-side filtering)
    if (query.isNotEmpty) {
      final lowerQuery = query.toLowerCase();
      results = results
          .where((task) => task.title.toLowerCase().contains(lowerQuery))
          .toList();
    }

    // Tag filtering (if specified)
    if (tagIds != null && tagIds.isNotEmpty) {
      final taskIds = <int>{};
      for (final tagId in tagIds) {
        final taskTagPairs = await (_database.select(
          _database.taskTags,
        )..where((tt) => tt.tagId.equals(tagId))).get();
        taskIds.addAll(taskTagPairs.map((tt) => tt.taskId));
      }
      results = results.where((task) => taskIds.contains(task.id)).toList();
    }

    return results;
  }

  /// Search notes by content
  Future<List<NoteEntity>> searchNotes({
    required String query,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (query.isEmpty && startDate == null && endDate == null) return [];

    var selectQuery = _database.select(_database.notes)
      ..where((n) => n.isDeleted.equals(false));

    // Date range filter
    if (startDate != null) {
      selectQuery = selectQuery
        ..where((n) => n.date.isBiggerOrEqualValue(startDate));
    }
    if (endDate != null) {
      final endOfDay = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        23,
        59,
        59,
      );
      selectQuery = selectQuery
        ..where((n) => n.date.isSmallerOrEqualValue(endOfDay));
    }

    var results = await selectQuery.get();

    // Text search (client-side filtering)
    final lowerQuery = query.toLowerCase();
    results = results
        .where((note) => note.content.toLowerCase().contains(lowerQuery))
        .toList();

    return results;
  }

  /// Search transactions by title
  Future<List<TransactionEntity>> searchTransactions({
    required String query,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (query.isEmpty && startDate == null && endDate == null) return [];

    var selectQuery = _database.select(_database.transactions);

    // Date range filter
    if (startDate != null) {
      selectQuery = selectQuery
        ..where((t) => t.date.isBiggerOrEqualValue(startDate));
    }
    if (endDate != null) {
      final endOfDay = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        23,
        59,
        59,
      );
      selectQuery = selectQuery
        ..where((t) => t.date.isSmallerOrEqualValue(endOfDay));
    }

    var results = await selectQuery.get();

    // Text search (client-side filtering)
    final lowerQuery = query.toLowerCase();
    results = results
        .where((tx) => tx.title.toLowerCase().contains(lowerQuery))
        .toList();

    return results;
  }

  /// Search calendar events by title
  Future<List<CalendarEventEntity>> searchCalendarEvents({
    required String query,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (query.isEmpty && startDate == null && endDate == null) return [];

    var selectQuery = _database.select(_database.calendarEvents)
      ..where((e) => e.isDeleted.equals(false));

    // Date range filter
    if (startDate != null) {
      selectQuery = selectQuery
        ..where((e) => e.date.isBiggerOrEqualValue(startDate));
    }
    if (endDate != null) {
      final endOfDay = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        23,
        59,
        59,
      );
      selectQuery = selectQuery
        ..where((e) => e.date.isSmallerOrEqualValue(endOfDay));
    }

    var results = await selectQuery.get();

    // Text search (client-side filtering)
    final lowerQuery = query.toLowerCase();
    results = results
        .where((event) => event.title.toLowerCase().contains(lowerQuery))
        .toList();

    return results;
  }

  /// Search all (combined results)
  Future<SearchResults> searchAll({
    required String query,
    DateTime? startDate,
    DateTime? endDate,
    List<int>? tagIds,
  }) async {
    final tasks = await searchTasks(
      query: query,
      startDate: startDate,
      endDate: endDate,
      tagIds: tagIds,
    );
    final notes = await searchNotes(
      query: query,
      startDate: startDate,
      endDate: endDate,
    );
    final transactions = await searchTransactions(
      query: query,
      startDate: startDate,
      endDate: endDate,
    );
    final events = await searchCalendarEvents(
      query: query,
      startDate: startDate,
      endDate: endDate,
    );

    return SearchResults(
      tasks: tasks,
      notes: notes,
      transactions: transactions,
      events: events,
    );
  }
}

/// Search results container
class SearchResults {
  final List<TaskEntity> tasks;
  final List<NoteEntity> notes;
  final List<TransactionEntity> transactions;
  final List<CalendarEventEntity> events;

  SearchResults({
    required this.tasks,
    required this.notes,
    required this.transactions,
    required this.events,
  });

  bool get isEmpty =>
      tasks.isEmpty && notes.isEmpty && transactions.isEmpty && events.isEmpty;
  int get totalCount =>
      tasks.length + notes.length + transactions.length + events.length;
}
