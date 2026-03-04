import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme/app_theme.dart';
import '../providers/task_providers.dart';
import '../../../../core/database/app_database.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../core/widgets/unified_agenda_item.dart';
import '../../../../core/widgets/attachment_manager.dart';

class TasksListPage extends ConsumerStatefulWidget {
  const TasksListPage({super.key});

  @override
  ConsumerState<TasksListPage> createState() => _TasksListPageState();
}

class _TasksListPageState extends ConsumerState<TasksListPage> {
  bool _isActiveTasksExpanded = true;

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(taskListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.tasksTitle),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_rounded),
          ),
        ],
      ),
      body: tasksAsync.when(
        data: (tasks) {
          // Filter out completed tasks
          final incompleteTasks = tasks.where((t) => !t.isCompleted).toList();

          // Separate archived tasks (older than 1 week and not completed)
          final now = DateTime.now();
          final oneWeekAgo = now.subtract(const Duration(days: 7));

          final archivedTasks = incompleteTasks.where((t) {
            if (t.date == null) return false;
            return t.date!.isBefore(oneWeekAgo);
          }).toList();

          final activeTasks = incompleteTasks.where((t) {
            if (t.date == null) return true; // Tasks without date are active
            return !t.date!.isBefore(oneWeekAgo);
          }).toList();

          return Column(
            children: [
              // Add Task Button at Top
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => context.push('/tasks/new'),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.add_task_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                              const Gap(10),
                              Text(
                                AppLocalizations.of(context)!.addTaskLabel,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Tasks List
              Expanded(
                child: incompleteTasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              size: 72,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.1),
                            ),
                            const Gap(20),
                            Text(
                              AppLocalizations.of(context)!.noTasksMessage,
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.45),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                        children: [
                          // Active Tasks Section
                          if (activeTasks.isNotEmpty) ...[
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => setState(
                                  () => _isActiveTasksExpanded =
                                      !_isActiveTasksExpanded,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: AppTheme.taskColor.withValues(
                                            alpha: 0.1,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.pending_actions_rounded,
                                          size: 18,
                                          color: AppTheme.taskColor,
                                        ),
                                      ),
                                      const Gap(12),
                                      Text(
                                        'Aktif Görevler (${activeTasks.length})',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.taskColor,
                                        ),
                                      ),
                                      const Spacer(),
                                      Icon(
                                        _isActiveTasksExpanded
                                            ? Icons.expand_less_rounded
                                            : Icons.expand_more_rounded,
                                        color: AppTheme.taskColor.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const Gap(12),
                            if (_isActiveTasksExpanded)
                              ...activeTasks.map((task) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: UnifiedAgendaItem(
                                    item: task,
                                    showDate: true,
                                    onEdit: () => _showTaskEditDialog(
                                      context,
                                      ref,
                                      task.id,
                                      task.title,
                                      task.date,
                                      task.isUrgent,
                                    ),
                                  ),
                                );
                              }),
                          ],

                          // Spacing between sections
                          if (activeTasks.isNotEmpty &&
                              archivedTasks.isNotEmpty)
                            const Gap(24),

                          // Archived Tasks Section at Bottom
                          if (archivedTasks.isNotEmpty)
                            _ArchivedTasksSection(
                              archivedTasks: archivedTasks,
                              onEdit: (task) => _showTaskEditDialog(
                                context,
                                ref,
                                task.id,
                                task.title,
                                task.date,
                                task.isUrgent,
                              ),
                            ),

                          // Archive Button
                          if (archivedTasks.isNotEmpty) const Gap(16),

                          InkWell(
                            onTap: () => context.push('/tasks/archive'),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outlineVariant
                                      .withValues(alpha: 0.2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.inventory_2_rounded,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.5),
                                    size: 20,
                                  ),
                                  const Gap(12),
                                  Expanded(
                                    child: Text(
                                      'Arşiv Görevler',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.2),
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text('${AppLocalizations.of(context)!.error}: $err')),
      ),
    );
  }

  void _showTaskEditDialog(
    BuildContext context,
    WidgetRef ref,
    int id,
    String currentTitle,
    DateTime? currentDate,
    bool currentUrgent, // Assuming we want to keep urgency or just edit title?
  ) {
    final controller = TextEditingController(text: currentTitle);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Text(AppLocalizations.of(context)!.editTask),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.taskTitleHint,
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const Gap(16),
            AttachmentManager(itemId: id, source: AttachmentSource.task),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref
                    .read(tasksRepositoryProvider)
                    .updateTaskContent(
                      id,
                      controller.text,
                      currentDate, // Keep existing date
                      currentUrgent, // Keep existing urgency
                    );
                Navigator.pop(context);
              }
            },
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );
  }
}

// Collapsible Archived Tasks Section
class _ArchivedTasksSection extends StatefulWidget {
  final List<TaskEntity> archivedTasks;
  final Function(TaskEntity) onEdit;

  const _ArchivedTasksSection({
    required this.archivedTasks,
    required this.onEdit,
  });

  @override
  State<_ArchivedTasksSection> createState() => _ArchivedTasksSectionState();
}

class _ArchivedTasksSectionState extends State<_ArchivedTasksSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.urgentColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.urgentColor.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.urgentColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: AppTheme.urgentColor,
                      size: 18,
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Text(
                      'Gecikmiş Görevler (${widget.archivedTasks.length})',
                      style: const TextStyle(
                        color: AppTheme.urgentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: AppTheme.urgentColor.withValues(alpha: 0.5),
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: widget.archivedTasks.map((task) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? cs.surfaceContainerHighest : cs.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: cs.outlineVariant.withValues(
                            alpha: isDark ? 0.1 : 0.2,
                          ),
                        ),
                      ),
                      child: UnifiedAgendaItem(
                        item: task,
                        showDate: true,
                        onEdit: () => widget.onEdit(task),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
