import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

@DataClassName('TransactionEntity')
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime()();
  TextColumn get category => text()();
  BoolColumn get isExpense => boolean().withDefault(const Constant(true))();
  TextColumn get receiptImagePath => text().nullable()();
  // Installment tracking
  IntColumn get installmentCount =>
      integer().nullable()(); // Total installments (e.g. 6)
  IntColumn get installmentCurrent =>
      integer().nullable()(); // Current installment (e.g. 1 of 6)
  TextColumn get installmentGroupId =>
      text().nullable()(); // Group ID to link installments together
  // Recurring transaction support
  BoolColumn get isRecurring => boolean().withDefault(const Constant(false))();
  TextColumn get recurrenceType =>
      text().nullable()(); // 'monthly', 'weekly', 'yearly'
}

@DataClassName('NoteEntity')
class Notes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get content => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get audioPath => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

@DataClassName('TaskEntity')
class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get date => dateTime().nullable()();
  BoolColumn get isUrgent => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get reminderTime => dateTime().nullable()();
  BoolColumn get reminderEnabled =>
      boolean().withDefault(const Constant(false))();
  IntColumn get notificationId => integer().nullable()();

  // Recurring task fields
  BoolColumn get isRecurring => boolean().withDefault(const Constant(false))();
  TextColumn get recurrencePattern =>
      text().nullable()(); // 'daily', 'weekly', 'monthly', 'custom'
  IntColumn get recurrenceInterval =>
      integer().nullable()(); // For custom intervals
  TextColumn get recurrenceDays =>
      text().nullable()(); // JSON array for weekly pattern
  DateTimeColumn get recurrenceEndDate => dateTime().nullable()();
  IntColumn get parentTaskId =>
      integer().nullable()(); // Link to parent recurring task
}

@DataClassName('CalendarEventEntity')
class CalendarEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get startTime => dateTime().nullable()();
  DateTimeColumn get endTime => dateTime().nullable()();
  TextColumn get systemEventId => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get reminderMinutesBefore => integer().nullable()();
  BoolColumn get reminderEnabled =>
      boolean().withDefault(const Constant(true))();
  IntColumn get notificationId => integer().nullable()();
}

@DataClassName('TagEntity')
class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get color => text()(); // Hex color code
  DateTimeColumn get createdAt => dateTime()();
}

@DataClassName('TaskTagEntity')
class TaskTags extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get taskId =>
      integer().references(Tasks, #id, onDelete: KeyAction.cascade)();
  IntColumn get tagId =>
      integer().references(Tags, #id, onDelete: KeyAction.cascade)();
}

@DataClassName('AttachmentEntity')
class Attachments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get taskId => integer().nullable().references(
    Tasks,
    #id,
    onDelete: KeyAction.cascade,
  )();
  IntColumn get noteId => integer().nullable().references(
    Notes,
    #id,
    onDelete: KeyAction.cascade,
  )();
  IntColumn get transactionId => integer().nullable().references(
    Transactions,
    #id,
    onDelete: KeyAction.cascade,
  )();
  IntColumn get eventId => integer().nullable().references(
    CalendarEvents,
    #id,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get filePath => text()();
  TextColumn get fileName => text()();
  TextColumn get fileType => text()(); // 'image', 'pdf', 'document', 'audio'
  IntColumn get fileSize => integer()(); // bytes
  DateTimeColumn get createdAt => dateTime()();
}

@DataClassName('ProductivityStatEntity')
class ProductivityStats extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime().unique()();
  IntColumn get tasksCompleted => integer().withDefault(const Constant(0))();
  IntColumn get tasksCreated => integer().withDefault(const Constant(0))();
  IntColumn get notesCreated => integer().withDefault(const Constant(0))();
  IntColumn get eventsAttended => integer().withDefault(const Constant(0))();
}

@DataClassName('ProfileEntity')
class Profiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().nullable()();
  TextColumn get email => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().nullable()();
}

@DriftDatabase(
  tables: [
    Transactions,
    Notes,
    Tasks,
    CalendarEvents,
    Tags,
    TaskTags,
    Attachments,
    ProductivityStats,
    Profiles,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // CRITICAL: Store dates as integer epoch, NOT as UTC text.
  // This ensures DateTimes are read back as local time automatically.
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: false);

  @override
  int get schemaVersion => 15;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 4) {
          // Notes
          try {
            await m.addColumn(notes, notes.isDeleted);
          } catch (e) {
            // ignore: empty_catches
          }
          try {
            await m.addColumn(notes, notes.deletedAt);
          } catch (e) {
            // ignore: empty_catches
          }

          // Tasks
          try {
            await m.addColumn(tasks, tasks.isDeleted);
          } catch (e) {
            // ignore: empty_catches
          }
          try {
            await m.addColumn(tasks, tasks.deletedAt);
          } catch (e) {
            // ignore: empty_catches
          }

          // CalendarEvents
          try {
            await m.addColumn(calendarEvents, calendarEvents.isDeleted);
          } catch (e) {
            // ignore: empty_catches
          }
          try {
            await m.addColumn(calendarEvents, calendarEvents.deletedAt);
          } catch (e) {
            // ignore: empty_catches
          }
        }
        if (from < 5) {
          try {
            await m.addColumn(calendarEvents, calendarEvents.systemEventId);
          } catch (e) {
            // ignore: empty_catches
          }
        }
        if (from < 6) {
          // Tasks reminder columns
          try {
            await m.addColumn(tasks, tasks.reminderTime);
          } catch (e) {
            // ignore: empty_catches
          }
          try {
            await m.addColumn(tasks, tasks.reminderEnabled);
          } catch (e) {
            // ignore: empty_catches
          }
          try {
            await m.addColumn(tasks, tasks.notificationId);
          } catch (e) {
            // ignore: empty_catches
          }

          // CalendarEvents reminder columns
          try {
            await m.addColumn(
              calendarEvents,
              calendarEvents.reminderMinutesBefore,
            );
          } catch (e) {
            // ignore: empty_catches
          }
          try {
            await m.addColumn(calendarEvents, calendarEvents.reminderEnabled);
          } catch (e) {
            // ignore: empty_catches
          }
          try {
            await m.addColumn(calendarEvents, calendarEvents.notificationId);
          } catch (e) {
            // ignore: empty_catches
          }
        }
        if (from < 7) {
          // Recurring task columns
          try {
            await m.addColumn(tasks, tasks.isRecurring);
          } catch (e) {
            // ignore: empty_catches
          }
          try {
            await m.addColumn(tasks, tasks.recurrencePattern);
          } catch (e) {
            // ignore: empty_catches
          }
          try {
            await m.addColumn(tasks, tasks.recurrenceInterval);
          } catch (e) {
            // ignore: empty_catches
          }
          try {
            await m.addColumn(tasks, tasks.recurrenceDays);
          } catch (e) {
            // ignore: empty_catches
          }
          try {
            await m.addColumn(tasks, tasks.recurrenceEndDate);
          } catch (e) {
            // ignore: empty_catches
          }
          try {
            await m.addColumn(tasks, tasks.parentTaskId);
          } catch (e) {
            // ignore: empty_catches
          }
        }
        if (from < 8) {
          // Tags tables
          try {
            await m.createTable(tags);
          } catch (e) {
            // ignore: empty_catches
          }
          try {
            await m.createTable(taskTags);
          } catch (e) {
            // ignore: empty_catches
          }
        }
        if (from < 9) {
          try {
            await m.createTable(attachments);
          } catch (e) {
            // ignore: empty_catches
          }
        }
        if (from < 10) {
          try {
            await m.createTable(productivityStats);
          } catch (e) {
            // ignore: empty_catches
          }
        }
        if (from < 11) {
          try {
            await m.createTable(profiles);
          } catch (e) {
            // ignore: empty_catches
          }
        }
        if (from < 12) {
          // Installment tracking columns
          try {
            await m.addColumn(transactions, transactions.installmentCount);
          } catch (e) {
            // ignore: empty_catches
          }
          try {
            await m.addColumn(transactions, transactions.installmentCurrent);
          } catch (e) {
            // ignore: empty_catches
          }
          try {
            await m.addColumn(transactions, transactions.installmentGroupId);
          } catch (e) {
            // ignore: empty_catches
          }
        }
        if (from < 13) {
          // Recurring transaction columns
          try {
            await m.addColumn(transactions, transactions.isRecurring);
          } catch (e) {
            // ignore: empty_catches
          }
          try {
            await m.addColumn(transactions, transactions.recurrenceType);
          } catch (e) {
            // ignore: empty_catches
          }
        }
        if (from < 14) {
          try {
            await m.addColumn(attachments, attachments.transactionId);
          } catch (e) {
            // ignore: empty_catches
          }
          try {
            await m.addColumn(attachments, attachments.eventId);
          } catch (e) {
            // ignore: empty_catches
          }
        }
        if (from < 15) {
          // Convert all text datetime columns to integer epoch (seconds)
          // because we switched storeDateTimeAsText from true to false.
          final dateColumns = <String, List<String>>{
            'transactions': ['date'],
            'notes': ['date', 'deleted_at'],
            'tasks': [
              'date',
              'deleted_at',
              'reminder_time',
              'recurrence_end_date',
            ],
            'calendar_events': ['date', 'start_time', 'end_time', 'deleted_at'],
            'tags': ['created_at'],
            'attachments': ['created_at'],
            'productivity_stats': ['date'],
            'profiles': ['updated_at'],
          };
          for (final entry in dateColumns.entries) {
            for (final col in entry.value) {
              try {
                await customStatement(
                  "UPDATE ${entry.key} SET $col = CAST(strftime('%s', $col) AS INTEGER) "
                  "WHERE $col IS NOT NULL AND typeof($col) = 'text'",
                );
              } catch (e) {
                // ignore: column might not exist yet
              }
            }
          }
        }
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db_v2.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
