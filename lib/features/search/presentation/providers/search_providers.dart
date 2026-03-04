import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/search_service.dart';
import '../../../../core/database/app_database.dart';

/// Provider for AppDatabase
final _appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

/// Provider for SearchService
final searchServiceProvider = Provider<SearchService>((ref) {
  final database = ref.watch(_appDatabaseProvider);
  return SearchService(database);
});
