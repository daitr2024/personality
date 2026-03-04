// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/search_service.dart';
import '../../../../core/database/app_database.dart';
import '../providers/search_providers.dart';
import '../../../finance/presentation/providers/finance_providers.dart';
import '../../../notes/presentation/providers/note_providers.dart';
import '../../../tasks/presentation/providers/task_providers.dart';
import '../../../../core/widgets/unified_agenda_item.dart';
import '../../../../l10n/generated/app_localizations.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _searchController = TextEditingController();
  SearchResults? _results;
  bool _isLoading = false;

  // Filters
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty && _startDate == null) {
      setState(() => _results = null);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final results = await ref
          .read(searchServiceProvider)
          .searchAll(
            query: query,
            startDate: _startDate,
            endDate: _endDate,
            tagIds: null,
          );

      setState(() {
        _results = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.searchError(e.toString()))));
      }
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      locale: const Locale('tr', 'TR'),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _performSearch();
    }
  }

  void _clearDateRange() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _performSearch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.search)),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Etkinlik, görev, not veya işlem ara...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (_) => _performSearch(),
            ),
          ),

          // Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date range filter
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _selectDateRange,
                        icon: const Icon(Icons.date_range, size: 18),
                        label: Text(
                          _startDate != null && _endDate != null
                              ? '${DateFormat('dd/MM/yy').format(_startDate!)} - ${DateFormat('dd/MM/yy').format(_endDate!)}'
                              : 'Tarih Aralığı',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                    if (_startDate != null) ...[
                      const Gap(8),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: _clearDateRange,
                        tooltip: 'Temizle',
                      ),
                    ],
                  ],
                ),
                const Gap(12),
              ],
            ),
          ),

          const Gap(16),
          const Divider(height: 1),

          // Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _results == null
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search, size: 64, color: Colors.grey),
                        Gap(16),
                        Text(
                          'Aramaya başlamak için yukarıya yazın',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : _results!.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey),
                        Gap(16),
                        Text(
                          'Sonuç bulunamadı',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : _buildResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Tasks
        if (_results!.tasks.isNotEmpty) ...[
          _buildSectionHeader('Görevler', _results!.tasks.length),
          const Gap(8),
          ..._results!.tasks.map((task) => _buildTaskItem(task)),
          const Gap(24),
        ],

        // Notes
        if (_results!.notes.isNotEmpty) ...[
          _buildSectionHeader('Notlar', _results!.notes.length),
          const Gap(8),
          ..._results!.notes.map((note) => _buildNoteItem(note)),
          const Gap(24),
        ],

        // Calendar Events
        if (_results!.events.isNotEmpty) ...[
          _buildSectionHeader('Etkinlikler', _results!.events.length),
          const Gap(8),
          ..._results!.events.map((event) => _buildCalendarItem(event)),
          const Gap(24),
        ],

        // Transactions
        if (_results!.transactions.isNotEmpty) ...[
          _buildSectionHeader('İşlemler', _results!.transactions.length),
          const Gap(8),
          ..._results!.transactions.map((tx) => _buildTransactionItem(tx)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const Gap(8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskItem(TaskEntity task) {
    return UnifiedAgendaItem(
      item: task,
      showDate: true,
      onEdit: () => _showTaskEditDialog(task),
    );
  }

  void _showTaskEditDialog(TaskEntity task) {
    final controller = TextEditingController(text: task.title);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.editTask),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          autofocus: true,
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
                      task.id,
                      controller.text,
                      task.date,
                      task.isUrgent,
                    );
                Navigator.pop(context);
                _performSearch();
              }
            },
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteItem(NoteEntity note) {
    return UnifiedAgendaItem(
      item: note,
      showDate: true,
      onEdit: () => _showNoteEditDialog(note),
    );
  }

  void _showNoteEditDialog(NoteEntity note) {
    final controller = TextEditingController(text: note.content);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.editNote),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(border: OutlineInputBorder()),
          maxLines: 3,
          autofocus: true,
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
                    .read(notesRepositoryProvider)
                    .updateNote(
                      note.id,
                      controller.text,
                      audioPath: note.audioPath,
                    );
                Navigator.pop(context);
                _performSearch();
              }
            },
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarItem(CalendarEventEntity event) {
    return UnifiedAgendaItem(item: event, showDate: true);
  }

  Widget _buildTransactionItem(TransactionEntity transaction) {
    final isIncome = transaction.amount > 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isIncome ? Colors.green.shade50 : Colors.red.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            color: isIncome ? Colors.green : Colors.red,
            size: 20,
          ),
        ),
        title: Text(
          transaction.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${DateFormat('dd MMMM yyyy', 'tr_TR').format(transaction.date)} • ${transaction.category}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isIncome ? '+' : ''}${transaction.amount.toStringAsFixed(2)} ₺',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isIncome ? Colors.green : Colors.red,
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                size: 20,
                color: Colors.grey,
              ),
              onPressed: () => _confirmDeleteTransaction(transaction),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteTransaction(TransactionEntity tx) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteTransaction),
        content: Text(AppLocalizations.of(context)!.deleteTransactionConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              ref.read(financeRepositoryProvider).deleteTransaction(tx.id);
              Navigator.pop(context);
              _performSearch();
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
