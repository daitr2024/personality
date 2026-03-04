import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/permission_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';

class PermissionSettingsPage extends ConsumerStatefulWidget {
  const PermissionSettingsPage({super.key});

  @override
  ConsumerState<PermissionSettingsPage> createState() =>
      _PermissionSettingsPageState();
}

class _PermissionSettingsPageState extends ConsumerState<PermissionSettingsPage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() => ref.read(permissionProvider.notifier).refreshAll());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(permissionProvider.notifier).refreshAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final permissionState = ref.watch(permissionProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.appPermissions),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildInfoBox(cs),
          const Gap(24),
          _buildPermissionTile(
            context,
            Permission.camera,
            'Kamera',
            'Görsel tarama ve belge analizi için gereklidir.',
            Icons.camera_alt_rounded,
            permissionState.statuses[Permission.camera],
          ),
          _buildPermissionTile(
            context,
            Permission.contacts,
            'Rehber',
            'Taranan kartvizitleri telefona kaydetmek için gereklidir.',
            Icons.contacts_rounded,
            permissionState.statuses[Permission.contacts],
          ),
          _buildPermissionTile(
            context,
            Permission.microphone,
            'Mikrofon',
            'Sesli notlar ve sesli komutlar için gereklidir.',
            Icons.mic_rounded,
            permissionState.statuses[Permission.microphone],
          ),
          _buildPermissionTile(
            context,
            Permission.calendarFullAccess,
            'Takvim',
            'Takvim etkinliklerini senkronize etmek için gereklidir.',
            Icons.calendar_today_rounded,
            permissionState.statuses[Permission.calendarFullAccess],
          ),
          _buildPermissionTile(
            context,
            Permission.notification,
            'Bildirimler',
            'Task hatırlatıcıları ve önemli uyarılar için gereklidir.',
            Icons.notifications_active_rounded,
            permissionState.statuses[Permission.notification],
          ),
          const Gap(32),
          Center(
            child: TextButton.icon(
              onPressed: () => openAppSettings(),
              icon: const Icon(Icons.settings),
              label: Text(AppLocalizations.of(context)!.openSystemSettings),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.primaryContainer),
      ),
      child: Row(
        children: [
          Icon(Icons.security_rounded, color: cs.primary),
          const Gap(16),
          const Expanded(
            child: Text(
              'Uygulamanın özelliklerini tam performanslı kullanabilmek için aşağıdaki izinlerin verilmesi önerilir.',
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionTile(
    BuildContext context,
    Permission permission,
    String title,
    String subtitle,
    IconData icon,
    PermissionStatus? status,
  ) {
    final isGranted = status?.isGranted ?? false;
    final isPermanentlyDenied = status?.isPermanentlyDenied ?? false;
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isGranted
              ? Colors.green.withValues(alpha: 0.1)
              : cs.surfaceContainerHighest,
          child: Icon(
            icon,
            color: isGranted ? Colors.green : cs.onSurfaceVariant,
          ),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: _buildStatusButton(
          context,
          permission,
          status,
          isPermanentlyDenied,
        ),
      ),
    );
  }

  Widget _buildStatusButton(
    BuildContext context,
    Permission permission,
    PermissionStatus? status,
    bool isPermanentlyDenied,
  ) {
    if (status == null) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (status.isGranted) {
      return const Icon(Icons.check_circle_rounded, color: Colors.green);
    }

    return ElevatedButton(
      onPressed: () async {
        if (isPermanentlyDenied) {
          await openAppSettings();
        } else {
          await ref
              .read(permissionProvider.notifier)
              .requestPermission(permission);
        }
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        visualDensity: VisualDensity.compact,
      ),
      child: Text(isPermanentlyDenied ? 'Ayarlar' : 'İzin Ver'),
    );
  }
}
