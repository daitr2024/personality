import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionStatusState {
  final Map<Permission, PermissionStatus> statuses;

  PermissionStatusState({required this.statuses});

  PermissionStatusState copyWith({
    Map<Permission, PermissionStatus>? statuses,
  }) {
    return PermissionStatusState(statuses: statuses ?? this.statuses);
  }
}

class PermissionNotifier extends Notifier<PermissionStatusState> {
  static const List<Permission> relevantPermissions = [
    Permission.camera,
    Permission.microphone,
    Permission.contacts,
    Permission.calendarFullAccess,
    Permission.notification,
    Permission.reminders,
  ];

  @override
  PermissionStatusState build() {
    return PermissionStatusState(statuses: const {});
  }

  Future<void> refreshAll() async {
    final Map<Permission, PermissionStatus> newStatuses = {};
    for (final permission in relevantPermissions) {
      newStatuses[permission] = await permission.status;
    }
    state = state.copyWith(statuses: newStatuses);
  }

  Future<void> requestPermission(Permission permission) async {
    final status = await permission.request();
    state = state.copyWith(statuses: {...state.statuses, permission: status});
  }
}

final permissionProvider =
    NotifierProvider<PermissionNotifier, PermissionStatusState>(() {
      return PermissionNotifier();
    });
