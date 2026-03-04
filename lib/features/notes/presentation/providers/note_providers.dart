import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../data/repositories/notes_repository.dart';
import '../../../finance/presentation/providers/finance_providers.dart';

final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return NotesRepository(db);
});

final noteListProvider = StreamProvider<List<NoteEntity>>((ref) {
  final repository = ref.watch(notesRepositoryProvider);
  return repository.watchAllNotes();
});
