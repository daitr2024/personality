import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';

class NotesRepository {
  final AppDatabase _db;

  NotesRepository(this._db);

  Stream<List<NoteEntity>> watchAllNotes() {
    return (_db.select(_db.notes)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([
            (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Future<int> addNote(String content, {String? audioPath}) async {
    return await _db
        .into(_db.notes)
        .insert(
          NotesCompanion.insert(
            content: content,
            date: DateTime.now(),
            audioPath: Value(audioPath),
          ),
        );
  }

  Future<void> updateNote(int id, String content, {String? audioPath}) async {
    await (_db.update(_db.notes)..where((t) => t.id.equals(id))).write(
      NotesCompanion(
        content: Value(content),
        audioPath: Value(audioPath),
        // We probably don't want to update date on edit to keep original timestamp?
        // Or update it? For now let's keep original date (don't update it).
      ),
    );
  }

  Future<void> deleteNote(int id) async {
    // Soft delete
    await (_db.update(_db.notes)..where((t) => t.id.equals(id))).write(
      NotesCompanion(
        isDeleted: const Value(true),
        deletedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> permanentDeleteNote(int id) async {
    await (_db.delete(_db.notes)..where((t) => t.id.equals(id))).go();
  }

  Future<List<NoteEntity>> findNotesByContent(String content) async {
    return (_db.select(
      _db.notes,
    )..where((t) => t.content.equals(content))).get();
  }
}
