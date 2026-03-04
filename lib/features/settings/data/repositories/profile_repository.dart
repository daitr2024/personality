import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';

class ProfileRepository {
  final AppDatabase _db;

  ProfileRepository(this._db);

  Stream<ProfileEntity?> watchProfile() {
    return (_db.select(_db.profiles)..limit(1)).watchSingleOrNull();
  }

  Future<ProfileEntity?> getProfile() async {
    return await (_db.select(_db.profiles)..limit(1)).getSingleOrNull();
  }

  Future<void> updateProfile({String? name, String? email}) async {
    final existing = await getProfile();
    final now = DateTime.now();

    if (existing == null) {
      await _db
          .into(_db.profiles)
          .insert(
            ProfilesCompanion.insert(
              name: Value(name),
              email: Value(email),
              updatedAt: Value(now),
            ),
          );
    } else {
      await (_db.update(
        _db.profiles,
      )..where((t) => t.id.equals(existing.id))).write(
        ProfilesCompanion(
          name: name != null ? Value(name) : const Value.absent(),
          email: email != null ? Value(email) : const Value.absent(),
          updatedAt: Value(now),
        ),
      );
    }
  }
}
