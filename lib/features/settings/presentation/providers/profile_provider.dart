import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../../finance/presentation/providers/finance_providers.dart';
import '../../data/repositories/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ProfileRepository(db);
});

final profileProvider = StreamProvider<ProfileEntity?>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return repository.watchProfile();
});
