import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../../../calendar/presentation/providers/calendar_providers.dart';
import '../../../calendar/presentation/providers/calendar_settings_provider.dart';
import '../../../finance/presentation/providers/finance_providers.dart';
import 'about_page.dart';
import '../providers/backup_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSettingsItem(
            context,
            Icons.language,
            l10n.language,
            trailing: Text(
              currentLocale.languageCode.toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => SimpleDialog(
                  title: Text(l10n.selectLanguage),
                  children: [
                    SimpleDialogOption(
                      onPressed: () {
                        ref
                            .read(localeProvider.notifier)
                            .setLocale(const Locale('tr'));
                        Navigator.pop(context);
                      },
                      child: const Text('Türkçe'),
                    ),
                    SimpleDialogOption(
                      onPressed: () {
                        ref
                            .read(localeProvider.notifier)
                            .setLocale(const Locale('en'));
                        Navigator.pop(context);
                      },
                      child: const Text('English'),
                    ),
                    SimpleDialogOption(
                      onPressed: () {
                        ref
                            .read(localeProvider.notifier)
                            .setLocale(const Locale('ar'));
                        Navigator.pop(context);
                      },
                      child: const Text('العربية'),
                    ),
                  ],
                ),
              );
            },
          ),
          _buildSettingsItem(
            context,
            Icons.psychology_outlined,
            l10n.aiConfiguration,
            subtitle: l10n.aiConfigSubtitle,
            onTap: () => context.push('/settings/ai'),
          ),
          _buildSettingsItem(
            context,
            Icons.person_outline,
            l10n.accountInfo,
            subtitle: l10n.accountInfoSubtitle,
            onTap: () => context.push('/settings/profile'),
          ),
          _buildSettingsItem(
            context,
            Icons.calendar_today_outlined,
            l10n.calendarSync,
            onTap: () => _showCalendarSyncDialog(context, ref),
          ),

          _buildSettingsItem(
            context,
            Icons.delete_sweep_outlined,
            l10n.clearReceiptImages,
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l10n.clearReceiptsTitle),
                  content: Text(l10n.clearReceiptsConfirm),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(l10n.cancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(
                        l10n.delete,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await ref
                    .read(receiptScannerServiceProvider)
                    .clearAllReceiptImages();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.allImagesCleared)),
                  );
                }
              }
            },
          ),
          _buildSettingsItem(
            context,
            Icons.cloud_upload_outlined,
            l10n.backupAndRestore,
            subtitle: l10n.backupAndRestoreSubtitle,
            onTap: () => _showBackupRestoreDialog(context, ref),
          ),
          _buildSettingsItem(
            context,
            Icons.palette_outlined,
            l10n.themeSettings,
            onTap: () => context.push('/theme-settings'),
          ),
          _buildSettingsItem(
            context,
            Icons.security_outlined,
            l10n.appPermissions,
            subtitle: l10n.managePermissions,
            onTap: () => context.push('/settings/permissions'),
          ),
          _buildSettingsItem(
            context,
            Icons.info_outline,
            l10n.aboutApp,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showCalendarSyncDialog(BuildContext context, WidgetRef ref) async {
    final syncService = ref.read(calendarSyncServiceProvider);

    // Fetch calendars first
    final calendars = await syncService.getCalendars();

    if (context.mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          bool isSyncing = false;
          return StatefulBuilder(
            builder: (context, setLocalState) {
              return Consumer(
                builder: (context, ref, child) {
                  final currentSettings = ref.watch(calendarSettingsProvider);
                  final l10n = AppLocalizations.of(context)!;

                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.calendarSync,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Gap(16),
                        SwitchListTile(
                          title: Text(l10n.enableSync),
                          subtitle: Text(l10n.enableSyncSubtitle),
                          value: currentSettings.isSyncEnabled,
                          onChanged: (value) {
                            ref
                                .read(calendarSettingsProvider.notifier)
                                .setSyncEnabled(value);
                          },
                        ),
                        if (currentSettings.isSyncEnabled) ...[
                          const Divider(),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              l10n.selectTargetCalendar,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (calendars.isEmpty)
                            Text(l10n.noCalendarFound)
                          else
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight:
                                    MediaQuery.of(context).size.height * 0.4,
                              ),
                              child: ListView(
                                shrinkWrap: true,
                                children: calendars
                                    .map(
                                      (cal) => CheckboxListTile(
                                        title: Text(
                                          cal.name ?? l10n.unnamedCalendar,
                                        ),
                                        subtitle: Text(cal.accountName ?? ''),
                                        value:
                                            currentSettings
                                                .selectedCalendarId ==
                                            cal.id,
                                        onChanged: (value) {
                                          if (value == true) {
                                            ref
                                                .read(
                                                  calendarSettingsProvider
                                                      .notifier,
                                                )
                                                .setSelectedCalendarId(cal.id);
                                          } else {
                                            ref
                                                .read(
                                                  calendarSettingsProvider
                                                      .notifier,
                                                )
                                                .setSelectedCalendarId(null);
                                          }
                                        },
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                        ],
                        if (currentSettings.isSyncEnabled &&
                            currentSettings.selectedCalendarId != null) ...[
                          const Gap(16),
                          ElevatedButton.icon(
                            onPressed: isSyncing
                                ? null
                                : () async {
                                    setLocalState(() => isSyncing = true);
                                    try {
                                      final repo = ref.read(
                                        calendarRepositoryProvider,
                                      );
                                      final syncItems = await repo
                                          .getUnsyncedEvents();

                                      if (syncItems.isNotEmpty) {
                                        final result = await syncService
                                            .syncExistingEvents(
                                              calendarId: currentSettings
                                                  .selectedCalendarId!,
                                              eventsToSync: syncItems
                                                  .map(
                                                    (e) => (
                                                      id: e.id,
                                                      title: e.title,
                                                      date: e.date,
                                                    ),
                                                  )
                                                  .toList(),
                                            );

                                        // Update local DB with system ids
                                        for (var entry in result.entries) {
                                          await repo.updateSystemEventId(
                                            entry.key,
                                            entry.value,
                                          );
                                        }

                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                l10n.eventsSynced(
                                                  result.length,
                                                ),
                                              ),
                                            ),
                                          );
                                        }
                                      } else {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                l10n.noEventsToSync,
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    } finally {
                                      if (context.mounted) {
                                        setLocalState(() => isSyncing = false);
                                      }
                                    }
                                  },
                            icon: isSyncing
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.sync),
                            label: Text(l10n.syncAllOldRecords),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 45),
                            ),
                          ),
                        ],
                        const Gap(32),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      );
    }
  }

  void _showBackupRestoreDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.backupAndRestoreTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Gap(24),
            ListTile(
              leading: Icon(
                Icons.backup_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(l10n.backupNow),
              subtitle: Text(l10n.backupNowSubtitle),
              onTap: () async {
                Navigator.pop(context);
                try {
                  await ref.read(backupServiceProvider).createBackup();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.backupError(e.toString()))),
                    );
                  }
                }
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                Icons.restore_outlined,
                color: Theme.of(context).colorScheme.tertiary,
              ),
              title: Text(l10n.restoreFromBackup),
              subtitle: Text(l10n.restoreFromBackupSubtitle),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(l10n.restoreConfirmTitle),
                    content: Text(l10n.restoreConfirmMessage),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(l10n.cancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(
                          l10n.restoreFromBackup,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  try {
                    final success = await ref
                        .read(backupServiceProvider)
                        .restoreBackup();
                    if (success && context.mounted) {
                      await showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => AlertDialog(
                          title: Text(l10n.restoreSuccessTitle),
                          content: Text(l10n.restoreSuccessMessage),
                          actions: [
                            TextButton(
                              onPressed: () => exit(0),
                              child: Text(l10n.closeApp),
                            ),
                          ],
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.restoreError(e.toString())),
                        ),
                      );
                    }
                  }
                }
              },
            ),
            const Gap(16),
          ],
        ),
      ),
    );
  }

  static Widget _buildSettingsItem(
    BuildContext context,
    IconData icon,
    String title, {
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHighest : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: isDark ? 0.15 : 0.2),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: cs.primary),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w500, color: cs.onSurface),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withValues(alpha: 0.55),
                ),
              )
            : null,
        trailing:
            trailing ??
            Icon(
              Icons.chevron_right_rounded,
              color: cs.onSurface.withValues(alpha: 0.3),
            ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
