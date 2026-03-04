import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import 'package:permission_handler/permission_handler.dart';
import '../../../../config/theme/app_theme.dart';
import '../../../../core/services/image_analysis_service.dart';
import '../../../../features/settings/presentation/providers/locale_provider.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:personality_ai/features/image_scan/presentation/providers/image_analysis_providers.dart';
import 'package:personality_ai/features/tasks/presentation/providers/task_providers.dart';
import 'package:personality_ai/features/notes/presentation/providers/note_providers.dart';
import 'package:personality_ai/features/calendar/presentation/providers/calendar_providers.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Page for scanning images and extracting tasks/notes/events
class ImageScanPage extends ConsumerStatefulWidget {
  final bool useGallery;
  const ImageScanPage({super.key, this.useGallery = false});

  @override
  ConsumerState<ImageScanPage> createState() => _ImageScanPageState();
}

class _ImageScanPageState extends ConsumerState<ImageScanPage> {
  @override
  void initState() {
    super.initState();
    if (widget.useGallery) {
      Future.microtask(() => _scanFromGallery());
    }
  }

  bool _isScanning = false;
  ImageAnalysisResult? _result;

  // Custom Selection Cropping state
  Uint8List? _rawImageBytes;
  ui.Image? _uiImage;
  Offset? _selectionStart;
  Offset? _selectionEnd;
  Size? _displaySize;
  bool _isCropping = false;
  String? _savedImagePath;

  // Selection tracking
  final Set<int> _selectedTaskIndices = {};
  final Set<int> _selectedNoteIndices = {};
  final Set<int> _selectedEventIndices = {};
  final Set<int> _selectedContactIndices = {};

  // Expand/collapse tracking per section
  final Map<String, bool> _expandedSections = {
    'tasks': true,
    'notes': true,
    'events': true,
    'contacts': true,
  };

  int get _totalSelectedCount =>
      _selectedTaskIndices.length +
      _selectedNoteIndices.length +
      _selectedEventIndices.length +
      _selectedContactIndices.length;

  Future<void> _scanFromCamera() async {
    var status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.cameraPermissionRequired,
            ),
          ),
        );
      }
      return;
    }
    await _performScan(true);
  }

  Future<void> _scanFromGallery() async {
    await _performScan(false);
  }

  Future<void> _performScan(bool fromCamera) async {
    try {
      final service = ref.read(imageAnalysisServiceProvider);

      final image = fromCamera
          ? await service.pickImageFromCamera()
          : await service.pickImageFromGallery();

      if (image == null) return;

      final bytes = await File(image.path).readAsBytes();
      final decoded = await decodeImageFromList(bytes);

      if (mounted) {
        setState(() {
          _rawImageBytes = bytes;
          _uiImage = decoded;
          _selectionStart = null;
          _selectionEnd = null;
          _isScanning = false;
          _result = null;
        });
      }
    } catch (e) {
      debugPrint('UI: Pick Error: $e');
    }
  }

  Future<void> _performActualCrop() async {
    if (_uiImage == null ||
        _selectionStart == null ||
        _selectionEnd == null ||
        _displaySize == null) {
      return;
    }
    setState(() => _isCropping = true);

    try {
      final imgW = _uiImage!.width.toDouble();
      final imgH = _uiImage!.height.toDouble();

      // Calculate image's displayed size in BoxFit.contain
      final displayRatio = _displaySize!.width / _displaySize!.height;
      final imageRatio = imgW / imgH;

      double actualDisplayW, actualDisplayH;
      double offsetX = 0, offsetY = 0;

      if (imageRatio > displayRatio) {
        actualDisplayW = _displaySize!.width;
        actualDisplayH = actualDisplayW / imageRatio;
        offsetY = (_displaySize!.height - actualDisplayH) / 2;
      } else {
        actualDisplayH = _displaySize!.height;
        actualDisplayW = actualDisplayH * imageRatio;
        offsetX = (_displaySize!.width - actualDisplayW) / 2;
      }

      // Map selection to image coordinates
      final rect = Rect.fromPoints(_selectionStart!, _selectionEnd!);

      final left = ((rect.left - offsetX) / actualDisplayW * imgW).clamp(
        0,
        imgW,
      );
      final top = ((rect.top - offsetY) / actualDisplayH * imgH).clamp(0, imgH);
      final width = (rect.width / actualDisplayW * imgW).clamp(1, imgW - left);
      final height = (rect.height / actualDisplayH * imgH).clamp(1, imgH - top);

      final cropRect = Rect.fromLTWH(
        left.toDouble(),
        top.toDouble(),
        width.toDouble(),
        height.toDouble(),
      );

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      final paint = Paint();
      canvas.drawImageRect(
        _uiImage!,
        cropRect,
        Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
        paint,
      );

      final croppedImg = await recorder.endRecording().toImage(
        width.toInt(),
        height.toInt(),
      );
      final byteData = await croppedImg.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData != null) {
        _finishAnalysis(byteData.buffer.asUint8List());
      } else {
        _finishAnalysis(_rawImageBytes!);
      }

      setState(() => _isCropping = false);
    } catch (e) {
      debugPrint('Crop error: $e');
      _finishAnalysis(_rawImageBytes!);
      setState(() => _isCropping = false);
    }
  }

  Future<void> _finishAnalysis(Uint8List croppedBytes) async {
    setState(() {
      _isScanning = true;
      // Keep _rawImageBytes for original image preview
      _uiImage = null;
    });

    try {
      final service = ref.read(imageAnalysisServiceProvider);

      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
        p.join(
          tempDir.path,
          'scan_crop_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );
      await tempFile.writeAsBytes(croppedBytes);

      final savedPath = await service.saveImageLocally(XFile(tempFile.path));
      _savedImagePath = savedPath;
      debugPrint('UI: Starting analysis with 60s global timeout...');

      final languageCode = ref.read(localeProvider).languageCode;
      final result = await service
          .analyzeImage(savedPath, language: languageCode)
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () {
              throw 'ANALYSIS_TIMEOUT';
            },
          );

      if (mounted) {
        setState(() {
          _result = result;
          _isScanning = false;
          _selectedTaskIndices.clear();
          _selectedNoteIndices.clear();
          _selectedEventIndices.clear();
          _selectedContactIndices.clear();
          // Auto-select all items
          for (int i = 0; i < result.tasks.length; i++) {
            _selectedTaskIndices.add(i);
          }
          for (int i = 0; i < result.notes.length; i++) {
            _selectedNoteIndices.add(i);
          }
          for (int i = 0; i < result.events.length; i++) {
            _selectedEventIndices.add(i);
          }
          for (int i = 0; i < result.contacts.length; i++) {
            _selectedContactIndices.add(i);
          }
        });
      }
    } catch (e) {
      debugPrint('UI: Scan Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        setState(() => _isScanning = false);
      }
    }
  }

  Future<void> _saveSelectedItems() async {
    if (_result == null) return;

    try {
      final service = ref.read(imageAnalysisServiceProvider);

      final selectedTasks = _selectedTaskIndices
          .map((i) => _result!.tasks[i])
          .toList();
      final selectedNotes = _selectedNoteIndices
          .map((i) => _result!.notes[i])
          .toList();
      final selectedEvents = _selectedEventIndices
          .map((i) => _result!.events[i])
          .toList();

      debugPrint(
        'SAVE: Tasks=${selectedTasks.length}, Notes=${selectedNotes.length}, Events=${selectedEvents.length}',
      );
      for (var t in selectedTasks) {
        debugPrint('SAVE Task: "${t.title}" date=${t.dueDate}');
      }
      for (var e in selectedEvents) {
        debugPrint('SAVE Event: "${e.title}" start=${e.startTime}');
      }

      await service.saveTasksToDatabase(
        selectedTasks,
        imagePath: _savedImagePath,
      );
      debugPrint('SAVE: Tasks saved successfully');
      await service.saveNotesToDatabase(
        selectedNotes,
        imagePath: _savedImagePath,
      );
      debugPrint('SAVE: Notes saved successfully');
      await service.saveEventsToDatabase(
        selectedEvents,
        imagePath: _savedImagePath,
      );
      debugPrint('SAVE: Events saved successfully');

      final selectedContacts = _selectedContactIndices
          .map((i) => _result!.contacts[i])
          .toList();
      if (selectedContacts.isNotEmpty) {
        await service.saveContactsAsNotes(
          selectedContacts,
          imagePath: _savedImagePath,
        );
      }

      // Invalidate providers to refresh Home and other screens
      ref.invalidate(taskListProvider);
      ref.invalidate(noteListProvider);
      ref.invalidate(calendarEventsProvider);
      ref.invalidate(imageAnalysisServiceProvider);

      if (mounted) {
        final parts = <String>[];
        if (selectedTasks.isNotEmpty) {
          parts.add('${selectedTasks.length} görev');
        }
        if (selectedNotes.isNotEmpty) {
          parts.add('${selectedNotes.length} not');
        }
        if (selectedEvents.isNotEmpty) {
          parts.add('${selectedEvents.length} etkinlik');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              parts.isEmpty
                  ? 'Kaydedildi!'
                  : '${parts.join(", ")} başarıyla kaydedildi!',
            ),
            backgroundColor: AppTheme.completedColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.saveError(e.toString()),
            ),
          ),
        );
      }
    }
  }

  void _toggleSelectAll(String type) {
    setState(() {
      switch (type) {
        case 'tasks':
          if (_selectedTaskIndices.length == _result!.tasks.length) {
            _selectedTaskIndices.clear();
          } else {
            _selectedTaskIndices.clear();
            for (int i = 0; i < _result!.tasks.length; i++) {
              _selectedTaskIndices.add(i);
            }
          }
          break;
        case 'notes':
          if (_selectedNoteIndices.length == _result!.notes.length) {
            _selectedNoteIndices.clear();
          } else {
            _selectedNoteIndices.clear();
            for (int i = 0; i < _result!.notes.length; i++) {
              _selectedNoteIndices.add(i);
            }
          }
          break;
        case 'events':
          if (_selectedEventIndices.length == _result!.events.length) {
            _selectedEventIndices.clear();
          } else {
            _selectedEventIndices.clear();
            for (int i = 0; i < _result!.events.length; i++) {
              _selectedEventIndices.add(i);
            }
          }
          break;
        case 'contacts':
          if (_selectedContactIndices.length == _result!.contacts.length) {
            _selectedContactIndices.clear();
          } else {
            _selectedContactIndices.clear();
            for (int i = 0; i < _result!.contacts.length; i++) {
              _selectedContactIndices.add(i);
            }
          }
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Görsel Tarama'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_result != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Tekrar Tara',
              onPressed: () {
                setState(() {
                  _result = null;
                  _selectedTaskIndices.clear();
                  _selectedNoteIndices.clear();
                  _selectedEventIndices.clear();
                  _selectedContactIndices.clear();
                });
              },
            ),
        ],
      ),
      body: _uiImage != null
          ? _buildSelectionCropView()
          : _isScanning
          ? _buildScanningState()
          : _result == null
          ? _buildScanOptions()
          : _buildResults(),
    );
  }

  Widget _buildSelectionCropView() {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          color: cs.primary.withValues(alpha: 0.1),
          child: const Row(
            children: [
              Icon(Icons.gesture_rounded, size: 20),
              Gap(12),
              Expanded(
                child: Text(
                  'İsteğe bağlı: Analiz edilecek alanı çizerek seçebilirsiniz.',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              _displaySize = Size(constraints.maxWidth, constraints.maxHeight);
              return GestureDetector(
                onPanStart: (details) {
                  setState(() {
                    _selectionStart = details.localPosition;
                    _selectionEnd = details.localPosition;
                  });
                },
                onPanUpdate: (details) {
                  setState(() {
                    _selectionEnd = details.localPosition;
                  });
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(_rawImageBytes!, fit: BoxFit.contain),
                    CustomPaint(
                      painter: SelectionPainter(
                        start: _selectionStart,
                        end: _selectionEnd,
                        primaryColor: cs.primary,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // İptal butonu
                OutlinedButton(
                  onPressed: () => setState(() => _uiImage = null),
                  child: const Text('İPTAL'),
                ),
                const Gap(8),
                // Tümünü analiz et butonu
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isCropping
                        ? null
                        : () => _finishAnalysis(_rawImageBytes!),
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    label: const Text('TÜMÜNÜ ANALİZ ET'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.secondary,
                      foregroundColor: cs.onSecondary,
                    ),
                  ),
                ),
                // Seçili alanı analiz et butonu (sadece seçim varsa aktif)
                if (_selectionStart != null && _selectionEnd != null) ...[
                  const Gap(8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isCropping ? null : _performActualCrop,
                      icon: const Icon(Icons.crop, size: 18),
                      label: _isCropping
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('SEÇİLİ ALAN'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScanningState() {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(strokeWidth: 3, color: cs.primary),
          ),
          const Gap(24),
          Text(
            'Gemini Vision AI Analiz Ediliyor...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: cs.primary,
            ),
          ),
          const Gap(8),
          Text(
            'AI metin ve içerikleri çıkarıyor',
            style: TextStyle(
              fontSize: 13,
              color: cs.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanOptions() {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    cs.primary.withValues(alpha: 0.12),
                    cs.primary.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.document_scanner_rounded,
                size: 64,
                color: cs.primary,
              ),
            ),
            const Gap(32),
            Text(
              'Görsel Tarama',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const Gap(12),
            Text(
              'Görseldeki metinleri AI ile analiz ederek\ngörev, not, etkinlik ve kişileri otomatik çıkarın',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: cs.onSurface.withValues(alpha: 0.6),
                height: 1.6,
              ),
            ),
            const Gap(48),
            _buildScanButton(
              onPressed: _scanFromCamera,
              icon: Icons.camera_alt_rounded,
              label: 'Kamera ile Tara',
              isPrimary: true,
            ),
            const Gap(12),
            _buildScanButton(
              onPressed: _scanFromGallery,
              icon: Icons.photo_library_rounded,
              label: 'Galeriden Seç',
              isPrimary: false,
            ),
            const Gap(32),
            // Feature hints
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildFeatureHint(
                  Icons.task_alt_rounded,
                  'Görev',
                  AppTheme.taskColor,
                ),
                const Gap(20),
                _buildFeatureHint(
                  Icons.note_alt_rounded,
                  'Not',
                  AppTheme.noteColor,
                ),
                const Gap(20),
                _buildFeatureHint(
                  Icons.event_rounded,
                  'Etkinlik',
                  AppTheme.eventColor,
                ),
                const Gap(20),
                _buildFeatureHint(
                  Icons.person_rounded,
                  'Kişi',
                  AppTheme.completedColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureHint(IconData icon, String label, Color color) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color.withValues(alpha: 0.7)),
        const Gap(4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildScanButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required bool isPrimary,
  }) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: isPrimary
          ? ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 20),
              label: Text(label),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 20),
              label: Text(label),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                side: BorderSide(color: cs.outlineVariant),
              ),
            ),
    );
  }

  // ─── Results UI ──────────────────────────────────────────────

  Widget _buildResults() {
    if (_result == null) return const SizedBox();
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final hasItems =
        _result!.tasks.isNotEmpty ||
        _result!.notes.isNotEmpty ||
        _result!.events.isNotEmpty ||
        _result!.contacts.isNotEmpty;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // ── Summary Header ──
              _buildSummaryHeader(cs),
              const Gap(20),

              // ── Tasks Section ──
              if (_result!.tasks.isNotEmpty) ...[
                _buildSectionHeader(
                  title: 'Görevler',
                  icon: Icons.task_alt_rounded,
                  color: AppTheme.taskColor,
                  count: _result!.tasks.length,
                  selectedCount: _selectedTaskIndices.length,
                  sectionKey: 'tasks',
                ),
                if (_expandedSections['tasks'] == true)
                  ..._result!.tasks.asMap().entries.map((entry) {
                    return _buildTaskTile(entry.key, entry.value);
                  }),
                const Gap(16),
              ],

              // ── Notes Section ──
              if (_result!.notes.isNotEmpty) ...[
                _buildSectionHeader(
                  title: 'Notlar',
                  icon: Icons.note_alt_rounded,
                  color: AppTheme.noteColor,
                  count: _result!.notes.length,
                  selectedCount: _selectedNoteIndices.length,
                  sectionKey: 'notes',
                ),
                if (_expandedSections['notes'] == true)
                  ..._result!.notes.asMap().entries.map((entry) {
                    return _buildNoteTile(entry.key, entry.value);
                  }),
                const Gap(16),
              ],

              // ── Raw Text Toggle (Under Notes as requested) ──
              if (_result!.rawText.isNotEmpty && hasItems) ...[
                _buildRawTextSection(cs),
                const Gap(16),
              ],

              // ── Events Section ──
              if (_result!.events.isNotEmpty) ...[
                _buildSectionHeader(
                  title: 'Etkinlikler',
                  icon: Icons.event_rounded,
                  color: AppTheme.eventColor,
                  count: _result!.events.length,
                  selectedCount: _selectedEventIndices.length,
                  sectionKey: 'events',
                ),
                if (_expandedSections['events'] == true)
                  ..._result!.events.asMap().entries.map((entry) {
                    return _buildEventTile(entry.key, entry.value);
                  }),
                const Gap(16),
              ],

              // ── Contacts Section ──
              if (_result!.contacts.isNotEmpty) ...[
                _buildSectionHeader(
                  title: 'Kişi Bilgileri',
                  icon: Icons.person_rounded,
                  color: AppTheme.completedColor,
                  count: _result!.contacts.length,
                  selectedCount: null,
                  sectionKey: 'contacts',
                ),
                if (_expandedSections['contacts'] == true)
                  ..._result!.contacts.asMap().entries.map((entry) {
                    return _buildContactTile(entry.key, entry.value);
                  }),
                const Gap(16),
              ],

              // ── No Items ──
              if (!hasItems) _buildEmptyState(cs),

              const Gap(100), // space for bottom bar
            ],
          ),
        ),

        // ── Bottom Action Bar ──
        if (hasItems) _buildBottomBar(cs, isDark),
      ],
    );
  }

  Widget _buildSummaryHeader(ColorScheme cs) {
    final totalItems =
        _result!.tasks.length +
        _result!.notes.length +
        _result!.events.length +
        _result!.contacts.length;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primary.withValues(alpha: 0.08),
            cs.primary.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.primary.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: cs.primary,
                    size: 18,
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Analiz Tamamlandı',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      Text(
                        '$totalItems öğe tespit edildi',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Gap(16),
            Row(
              children: [
                if (_result!.tasks.isNotEmpty)
                  _buildMiniStat(
                    '${_result!.tasks.length}',
                    'Görev',
                    AppTheme.taskColor,
                  ),
                if (_result!.notes.isNotEmpty)
                  _buildMiniStat(
                    '${_result!.notes.length}',
                    'Not',
                    AppTheme.noteColor,
                  ),
                if (_result!.events.isNotEmpty)
                  _buildMiniStat(
                    '${_result!.events.length}',
                    'Etkinlik',
                    AppTheme.eventColor,
                  ),
                if (_result!.contacts.isNotEmpty)
                  _buildMiniStat(
                    '${_result!.contacts.length}',
                    'Kişi',
                    AppTheme.completedColor,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String count, String label, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Section Header ──────────────────────────────────────────

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required Color color,
    required int count,
    required int? selectedCount,
    required String sectionKey,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isExpanded = _expandedSections[sectionKey] ?? true;

    return GestureDetector(
      onTap: () {
        setState(() {
          _expandedSections[sectionKey] = !isExpanded;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const Gap(10),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const Gap(8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            const Spacer(),
            if (selectedCount != null) ...[
              GestureDetector(
                onTap: () => _toggleSelectAll(sectionKey),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: selectedCount == count
                        ? color.withValues(alpha: 0.15)
                        : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    selectedCount == count ? 'Tümünü Kaldır' : 'Tümünü Seç',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: selectedCount == count
                          ? color
                          : cs.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
              const Gap(8),
            ],
            AnimatedRotation(
              turns: isExpanded ? 0.0 : -0.25,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.expand_more_rounded,
                color: cs.onSurface.withValues(alpha: 0.4),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Task Tile ───────────────────────────────────────────────

  Widget _buildTaskTile(int index, ExtractedTask task) {
    final isSelected = _selectedTaskIndices.contains(index);
    final cs = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.taskColor.withValues(alpha: 0.06)
            : cs.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected
              ? AppTheme.taskColor.withValues(alpha: 0.3)
              : Colors.transparent,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedTaskIndices.remove(index);
            } else {
              _selectedTaskIndices.add(index);
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.taskColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.taskColor
                        : cs.outline.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 14,
                      )
                    : null,
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    if (task.dueDate != null) ...[
                      const Gap(4),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 13,
                            color: AppTheme.taskColor.withValues(alpha: 0.7),
                          ),
                          const Gap(4),
                          Text(
                            '${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.taskColor.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.zoom_in_rounded, size: 20),
                onPressed: () => _showFullRawText(
                  context,
                  'Görev: ${task.title}'
                  '${task.dueDate != null ? '\nTarih: ${task.dueDate!.day.toString().padLeft(2, '0')}/${task.dueDate!.month.toString().padLeft(2, '0')}/${task.dueDate!.year}' : ''}'
                  '${task.description != null ? '\nAçıklama: ${task.description}' : ''}',
                ),
                color: cs.primary.withValues(alpha: 0.6),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Note Tile ───────────────────────────────────────────────

  Widget _buildNoteTile(int index, ExtractedNote note) {
    final isSelected = _selectedNoteIndices.contains(index);
    final cs = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.noteColor.withValues(alpha: 0.06)
            : cs.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected
              ? AppTheme.noteColor.withValues(alpha: 0.3)
              : Colors.transparent,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedNoteIndices.remove(index);
            } else {
              _selectedNoteIndices.add(index);
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.noteColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.noteColor
                        : cs.outline.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 14,
                      )
                    : null,
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const Gap(4),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.noteColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        note.content,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: cs.onSurface.withValues(alpha: 0.7),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: IconButton(
                  icon: const Icon(Icons.zoom_in_rounded, size: 20),
                  onPressed: () => _showFullRawText(
                    context,
                    'Not: ${note.title}'
                    '\nİçerik: ${note.content}'
                    '${note.date != null ? '\nTarih: ${note.date!.day.toString().padLeft(2, '0')}/${note.date!.month.toString().padLeft(2, '0')}/${note.date!.year}' : ''}',
                  ),
                  color: cs.primary.withValues(alpha: 0.6),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Event Tile ──────────────────────────────────────────────

  Widget _buildEventTile(int index, ExtractedEvent event) {
    final isSelected = _selectedEventIndices.contains(index);
    final cs = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.eventColor.withValues(alpha: 0.06)
            : cs.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected
              ? AppTheme.eventColor.withValues(alpha: 0.3)
              : Colors.transparent,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedEventIndices.remove(index);
            } else {
              _selectedEventIndices.add(index);
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.eventColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.eventColor
                        : cs.outline.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 14,
                      )
                    : null,
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const Gap(4),
                    Row(
                      children: [
                        if (event.startTime != null) ...[
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 13,
                            color: AppTheme.eventColor.withValues(alpha: 0.7),
                          ),
                          const Gap(4),
                          Text(
                            '${event.startTime!.day}/${event.startTime!.month} ${event.startTime!.hour}:${event.startTime!.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.eventColor.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                        if (event.location != null &&
                            event.location!.isNotEmpty) ...[
                          const Gap(12),
                          Icon(
                            Icons.location_on_rounded,
                            size: 13,
                            color: AppTheme.eventColor.withValues(alpha: 0.7),
                          ),
                          const Gap(4),
                          Flexible(
                            child: Text(
                              event.location!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.eventColor.withValues(
                                  alpha: 0.8,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (event.description != null &&
                        event.description!.isNotEmpty) ...[
                      const Gap(6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.eventColor.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          event.description!,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.7),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.zoom_in_rounded, size: 20),
                onPressed: () {
                  final st = event.startTime;
                  final et = event.endTime;
                  _showFullRawText(
                    context,
                    'Etkinlik: ${event.title}'
                    '${st != null ? '\nBaşlangıç: ${st.day.toString().padLeft(2, '0')}/${st.month.toString().padLeft(2, '0')}/${st.year} ${st.hour.toString().padLeft(2, '0')}:${st.minute.toString().padLeft(2, '0')}' : ''}'
                    '${et != null ? '\nBitiş: ${et.day.toString().padLeft(2, '0')}/${et.month.toString().padLeft(2, '0')}/${et.year} ${et.hour.toString().padLeft(2, '0')}:${et.minute.toString().padLeft(2, '0')}' : ''}'
                    '${event.location != null ? '\nKonum: ${event.location}' : ''}',
                  );
                },
                color: cs.primary.withValues(alpha: 0.6),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Contact Tile ────────────────────────────────────────────

  Widget _buildContactTile(int index, ExtractedContact contact) {
    final isSelected = _selectedContactIndices.contains(index);
    final cs = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.completedColor.withValues(alpha: 0.04)
            : cs.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected
              ? AppTheme.completedColor.withValues(alpha: 0.3)
              : Colors.transparent,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedContactIndices.remove(index);
            } else {
              _selectedContactIndices.add(index);
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.completedColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.completedColor
                        : cs.outline.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 14,
                      )
                    : null,
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.name ?? 'İsimsiz Kişi',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const Gap(4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (contact.jobTitle != null ||
                            contact.department != null)
                          _buildContactChip(
                            Icons.work_outline_rounded,
                            [
                              if (contact.jobTitle != null) contact.jobTitle,
                              if (contact.department != null)
                                contact.department,
                            ].join(' / '),
                            cs,
                          ),
                        if (contact.company != null)
                          _buildContactChip(
                            Icons.business_rounded,
                            contact.company!,
                            cs,
                          ),
                        if (contact.phone != null)
                          _buildContactChip(
                            Icons.phone_rounded,
                            contact.phone!,
                            cs,
                          ),
                        if (contact.email != null)
                          _buildContactChip(
                            Icons.email_rounded,
                            contact.email!,
                            cs,
                          ),
                        if (contact.address != null)
                          _buildContactChip(
                            Icons.location_on_rounded,
                            contact.address!,
                            cs,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  _buildContactAction(
                    icon: Icons.zoom_in_rounded,
                    color: cs.primary,
                    tooltip: 'Taranan Metni Gör',
                    onTap: () => _showFullRawText(
                      context,
                      'Kişi: ${contact.name ?? 'Bilinmiyor'}'
                      '${contact.phone != null ? '\nTelefon: ${contact.phone}' : ''}'
                      '${contact.email != null ? '\nE-posta: ${contact.email}' : ''}'
                      '${contact.company != null ? '\nŞirket: ${contact.company}' : ''}',
                    ),
                  ),
                  const Gap(4),
                  _buildContactAction(
                    icon: Icons.edit_rounded,
                    color: AppTheme.eventColor,
                    tooltip: 'Düzenle',
                    onTap: () => _showContactEditDialog(contact),
                  ),
                  const Gap(4),
                  _buildContactAction(
                    icon: Icons.person_add_rounded,
                    color: AppTheme.completedColor,
                    tooltip: 'Rehbere Kaydet',
                    onTap: () => _saveToNativeContacts(contact),
                  ),
                ],
              ),
              const Gap(12),
              IconButton(
                icon: const Icon(Icons.zoom_in_rounded, size: 20),
                onPressed: () => _showFullRawText(
                  context,
                  'Kişi: ${contact.name ?? 'Bilinmiyor'}'
                  '${contact.phone != null ? '\nTelefon: ${contact.phone}' : ''}'
                  '${contact.email != null ? '\nE-posta: ${contact.email}' : ''}'
                  '${contact.company != null ? '\nŞirket: ${contact.company}' : ''}',
                ),
                color: cs.primary.withValues(alpha: 0.6),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactChip(IconData icon, String text, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: cs.onSurface.withValues(alpha: 0.5)),
          const Gap(4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: cs.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactAction({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  // ─── Empty State ─────────────────────────────────────────────

  Widget _buildEmptyState(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 48,
            color: cs.onSurface.withValues(alpha: 0.3),
          ),
          const Gap(16),
          Text(
            'Hiçbir öğe bulunamadı',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const Gap(8),
          Text(
            'Görselde okunaklı metin olduğundan emin olun.\nParlak yüzeylerden ve bulanık görsellerden kaçının.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: cs.onSurface.withValues(alpha: 0.4),
              height: 1.5,
            ),
          ),
          const Gap(16),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _result = null;
              });
            },
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  // ─── Raw Text Section ────────────────────────────────────────

  Widget _buildRawTextSection(ColorScheme cs) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.3),
      collapsedBackgroundColor: cs.surfaceContainerHighest.withValues(
        alpha: 0.3,
      ),
      leading: Icon(
        Icons.text_snippet_rounded,
        size: 18,
        color: cs.onSurface.withValues(alpha: 0.4),
      ),
      title: Row(
        children: [
          Text(
            'Taranan Metin',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
      children: [
        // Orijinal görseli göster butonu
        if (_savedImagePath != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => _showOriginalImage(context),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.image_rounded, size: 20, color: cs.primary),
                    const Gap(8),
                    Text(
                      'Orijinal Görseli Gör',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cs.primary,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.open_in_new_rounded,
                      size: 16,
                      color: cs.primary.withValues(alpha: 0.6),
                    ),
                  ],
                ),
              ),
            ),
          ),
        GestureDetector(
          onTap: () => _showFullRawText(context, _result!.rawText),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              _result!.rawText,
              maxLines: 8,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withValues(alpha: 0.6),
                height: 1.5,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showOriginalImage(BuildContext context) {
    if (_savedImagePath == null) return;
    final file = File(_savedImagePath!);
    if (!file.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.imageFileNotFound),
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Row(
                children: [
                  const Icon(Icons.image_rounded, size: 20),
                  const Gap(8),
                  const Expanded(
                    child: Text(
                      'Orijinal Görsel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.file(file, fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullRawText(BuildContext context, String text) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Taranan Tam Metin'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              text,
              style: const TextStyle(
                fontSize: 13,
                fontFamily: 'monospace',
                height: 1.5,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  // ─── Bottom Action Bar ───────────────────────────────────────

  Widget _buildBottomBar(ColorScheme cs, bool isDark) {
    final hasContactsOnly =
        _selectedTaskIndices.isEmpty &&
        _selectedNoteIndices.isEmpty &&
        _selectedEventIndices.isEmpty &&
        _result!.contacts.isNotEmpty;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: isDark ? cs.surface : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Scan again button
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: cs.outlineVariant),
                borderRadius: BorderRadius.circular(14),
              ),
              child: IconButton(
                icon: const Icon(Icons.add_a_photo_rounded),
                tooltip: 'Yeni Tarama',
                onPressed: () {
                  setState(() {
                    _result = null;
                  });
                },
              ),
            ),
            const Gap(12),
            // Save button
            Expanded(
              child: ElevatedButton(
                onPressed: _totalSelectedCount > 0
                    ? _saveSelectedItems
                    : hasContactsOnly
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Kişileri sağdaki butonlarla rehbere kaydedin.',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.save_rounded, size: 20),
                    const Gap(8),
                    Text(
                      _totalSelectedCount > 0
                          ? 'Seçilenleri Kaydet ($_totalSelectedCount)'
                          : hasContactsOnly
                          ? 'Kişileri Rehbere Kaydedin'
                          : 'Öğe Seçin',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Contact Actions ─────────────────────────────────────────

  Future<void> _showContactEditDialog(ExtractedContact contact) async {
    final editedContact = await showDialog<ExtractedContact>(
      context: context,
      builder: (context) => ContactEditDialog(contact: contact),
    );

    if (editedContact != null) {
      _saveToNativeContacts(editedContact);
    }
  }

  Future<void> _saveToNativeContacts(ExtractedContact contact) async {
    try {
      if ((contact.name == null || contact.name!.isEmpty) &&
          (contact.phone == null || contact.phone!.isEmpty)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Hata: İsim veya Telefon bilgisi bulunamadı.'),
            ),
          );
        }
        return;
      }

      if (await fc.FlutterContacts.requestPermission()) {
        final newContact = fc.Contact();

        final nameParts = (contact.name ?? 'İsimsiz Kişi').trim().split(' ');
        if (nameParts.length > 1) {
          newContact.name.first = nameParts.first;
          newContact.name.last = nameParts.skip(1).join(' ');
        } else {
          newContact.name.first = nameParts.first;
        }

        if (contact.phone != null && contact.phone!.isNotEmpty) {
          newContact.phones = [fc.Phone(contact.phone!)];
        }
        if (contact.email != null && contact.email!.isNotEmpty) {
          newContact.emails = [fc.Email(contact.email!)];
        }
        if (contact.company != null && contact.company!.isNotEmpty) {
          newContact.organizations = [
            fc.Organization(
              company: contact.company ?? '',
              title: contact.jobTitle ?? '',
              department: contact.department ?? '',
            ),
          ];
        } else if ((contact.jobTitle != null && contact.jobTitle!.isNotEmpty) ||
            (contact.department != null && contact.department!.isNotEmpty)) {
          newContact.organizations = [
            fc.Organization(
              title: contact.jobTitle ?? '',
              department: contact.department ?? '',
            ),
          ];
        }

        if (contact.address != null && contact.address!.isNotEmpty) {
          newContact.addresses = [fc.Address(contact.address!)];
        }

        await newContact.insert();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Kişi başarıyla telefon rehberine eklendi!'),
              backgroundColor: AppTheme.completedColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Rehber izni verilmedi. Ayarlar > İzinler sayfasından kontrol edin.',
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Contact Save Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.contactSaveError(e.toString()),
            ),
          ),
        );
      }
    }
  }
}

// ─── Contact Edit Dialog ─────────────────────────────────────

class ContactEditDialog extends StatefulWidget {
  final ExtractedContact contact;

  const ContactEditDialog({super.key, required this.contact});

  @override
  State<ContactEditDialog> createState() => _ContactEditDialogState();
}

class _ContactEditDialogState extends State<ContactEditDialog> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _companyController;
  late TextEditingController _jobTitleController;
  late TextEditingController _departmentController;
  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.contact.name);
    _phoneController = TextEditingController(text: widget.contact.phone);
    _emailController = TextEditingController(text: widget.contact.email);
    _companyController = TextEditingController(text: widget.contact.company);
    _jobTitleController = TextEditingController(text: widget.contact.jobTitle);
    _departmentController = TextEditingController(
      text: widget.contact.department,
    );
    _addressController = TextEditingController(text: widget.contact.address);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _companyController.dispose();
    _jobTitleController.dispose();
    _departmentController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.completedColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: AppTheme.completedColor,
              size: 20,
            ),
          ),
          const Gap(12),
          const Text('Kişi Bilgileri'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogField(_nameController, 'Ad Soyad', Icons.person),
            const Gap(10),
            _buildDialogField(
              _phoneController,
              'Telefon',
              Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            const Gap(10),
            _buildDialogField(
              _emailController,
              'E-posta',
              Icons.email,
              keyboardType: TextInputType.emailAddress,
            ),
            const Gap(10),
            _buildDialogField(_companyController, 'Şirket', Icons.business),
            const Gap(10),
            _buildDialogField(_jobTitleController, 'Unvan', Icons.work),
            const Gap(10),
            _buildDialogField(_departmentController, 'Birim/Bölüm', Icons.hub),
            const Gap(10),
            _buildDialogField(
              _addressController,
              'Adres',
              Icons.location_on,
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'İptal',
            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6)),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(
              context,
              ExtractedContact(
                name: _nameController.text,
                phone: _phoneController.text,
                email: _emailController.text,
                company: _companyController.text,
                jobTitle: _jobTitleController.text,
                department: _departmentController.text,
                address: _addressController.text,
              ),
            );
          },
          icon: const Icon(Icons.person_add_rounded, size: 18),
          label: const Text('Rehbere Kaydet'),
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildDialogField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        isDense: true,
      ),
    );
  }
}

class SelectionPainter extends CustomPainter {
  final Offset? start;
  final Offset? end;
  final Color primaryColor;

  SelectionPainter({this.start, this.end, required this.primaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (start == null || end == null) return;

    final rect = Rect.fromPoints(start!, end!);

    // Draw semi-transparent overlay
    final overlayPaint = Paint()..color = Colors.black.withValues(alpha: 0.5);

    // Path for the whole area with a hole for the selected rect
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(rect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, overlayPaint);

    // Draw selection border
    final borderPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawRect(rect, borderPaint);

    // Draw little handles at corners
    final handlePaint = Paint()..color = primaryColor;
    canvas.drawCircle(rect.topLeft, 4, handlePaint);
    canvas.drawCircle(rect.topRight, 4, handlePaint);
    canvas.drawCircle(rect.bottomLeft, 4, handlePaint);
    canvas.drawCircle(rect.bottomRight, 4, handlePaint);
  }

  @override
  bool shouldRepaint(covariant SelectionPainter oldDelegate) =>
      oldDelegate.start != start || oldDelegate.end != end;
}
