import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:intl/intl.dart';
import '../../../../features/notes/presentation/widgets/audio_analysis_dialog.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../features/settings/presentation/providers/ai_config_provider.dart';

class SmartInputBar extends ConsumerStatefulWidget {
  final FocusNode? focusNode;
  const SmartInputBar({super.key, this.focusNode});

  @override
  ConsumerState<SmartInputBar> createState() => _SmartInputBarState();
}

class _SmartInputBarState extends ConsumerState<SmartInputBar>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final AudioRecorder _audioRecorder = AudioRecorder();

  bool _isRecording = false;
  bool _isTranscribing = false;

  Timer? _amplitudeTimer;
  Timer? _silenceTimer;
  Timer? _graceTimer;
  static const double _silenceThresholdDb = -50.0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _amplitudeTimer?.cancel();
    _silenceTimer?.cancel();
    _graceTimer?.cancel();
    _controller.dispose();
    _audioRecorder.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      _controller.clear();
      showDialog(
        context: context,
        builder: (context) => AudioAnalysisDialog(text: text),
      );
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await Permission.microphone.request().isGranted &&
          await _audioRecorder.hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        final path = '${directory.path}/SmartInput_$timestamp.wav';

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.wav),
          path: path,
        );
        setState(() => _isRecording = true);
        _pulseController.repeat(reverse: true);

        // Only enable silence detection if user hasn't disabled it
        final configService = ref.read(aiConfigServiceProvider);
        final autoStop = await configService.getAutoStopOnSilence();
        if (autoStop) {
          // Wait 3 seconds before starting silence detection
          // (gives the user time to start speaking)
          _graceTimer = Timer(const Duration(seconds: 3), () {
            if (_isRecording && mounted) {
              _startSilenceDetection();
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Start error: $e');
    }
  }

  void _startSilenceDetection() {
    _amplitudeTimer?.cancel();
    _silenceTimer?.cancel();
    _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 200), (
      timer,
    ) async {
      if (!_isRecording) return;
      final amp = await _audioRecorder.getAmplitude();
      if (!mounted) return;

      if (amp.current < _silenceThresholdDb) {
        _silenceTimer ??= Timer(const Duration(seconds: 3), () {
          if (_isRecording && mounted) {
            debugPrint('3s silence detected — auto-stopping recording');
            _stopRecording();
          }
        });
      } else {
        _silenceTimer?.cancel();
        _silenceTimer = null;
      }
    });
  }

  Future<void> _stopRecording() async {
    _amplitudeTimer?.cancel();
    _silenceTimer?.cancel();
    _graceTimer?.cancel();
    _silenceTimer = null;

    try {
      final path = await _audioRecorder.stop();
      _pulseController.stop();
      _pulseController.reset();
      setState(() => _isRecording = false);

      if (path != null) {
        await _transcribe(path);
      }
    } catch (e) {
      debugPrint('Stop error: $e');
    }
  }

  Future<void> _transcribe(String path) async {
    setState(() => _isTranscribing = true);
    try {
      // Use Gemini to transcribe audio to text
      final analysisService = ref.read(audioAnalysisServiceProvider);
      final transcribedText = await analysisService.transcribeAudioFile(path);

      if (transcribedText != null && transcribedText.isNotEmpty && mounted) {
        // Open AudioAnalysisDialog with the transcribed text for AI analysis
        showDialog(
          context: context,
          builder: (context) =>
              AudioAnalysisDialog(text: transcribedText, audioPath: path),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.apiKeyNotSet),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Transcribe error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ses analizi hatası: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isTranscribing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? cs.surfaceContainerHighest : cs.surface,
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.2)),
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark
                      ? cs.surface.withValues(alpha: 0.6)
                      : cs.surfaceContainerHighest.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(24),
                  border: _isRecording
                      ? Border.all(
                          color: Colors.redAccent.withValues(alpha: 0.6),
                          width: 1.5,
                        )
                      : Border.all(
                          color: cs.outlineVariant.withValues(alpha: 0.2),
                        ),
                ),
                child: Row(
                  children: [
                    if (_isRecording)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),

                    Expanded(
                      child: _isRecording
                          ? Text(
                              AppLocalizations.of(context)!.listening,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w500,
                              ),
                            )
                          : TextField(
                              controller: _controller,
                              focusNode: widget.focusNode,
                              style: theme.textTheme.bodyMedium,
                              maxLength: 200,
                              onSubmitted: (_) => _handleSend(),
                              decoration: InputDecoration(
                                hintText: AppLocalizations.of(
                                  context,
                                )!.smartInputHint,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                fillColor: Colors.transparent,
                                filled: false,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                counterText: "",
                                suffixIcon:
                                    ValueListenableBuilder<TextEditingValue>(
                                      valueListenable: _controller,
                                      builder: (context, value, child) {
                                        if (value.text.isEmpty) {
                                          return const SizedBox.shrink();
                                        }
                                        return IconButton(
                                          icon: const Icon(
                                            Icons.cancel_rounded,
                                            size: 20,
                                          ),
                                          onPressed: () => _controller.clear(),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          color: cs.onSurfaceVariant.withValues(
                                            alpha: 0.6,
                                          ),
                                        );
                                      },
                                    ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const Gap(8),
            // Camera/Image Scan Button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.push('/image-scan'),
                borderRadius: BorderRadius.circular(20),
                child: CircleAvatar(
                  backgroundColor: const Color(
                    0xFF2ECC71,
                  ).withValues(alpha: 0.15),
                  radius: 20,
                  child: const Icon(
                    Icons.document_scanner_rounded,
                    color: Color(0xFF2ECC71),
                    size: 20,
                  ),
                ),
              ),
            ),
            const Gap(8),
            if (_isTranscribing)
              SizedBox(
                width: 40,
                height: 40,
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: cs.primary,
                    ),
                  ),
                ),
              )
            else
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _controller,
                builder: (context, value, child) {
                  final hasText = value.text.isNotEmpty;
                  return AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _isRecording ? _pulseAnimation.value : 1.0,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: hasText ? _handleSend : _toggleRecording,
                            borderRadius: BorderRadius.circular(20),
                            child: CircleAvatar(
                              backgroundColor: _isRecording
                                  ? Colors.redAccent
                                  : cs.primary,
                              radius: 20,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  _isRecording
                                      ? Icons.stop_rounded
                                      : (hasText
                                            ? Icons.send_rounded
                                            : Icons.mic_rounded),
                                  key: ValueKey(
                                    _isRecording
                                        ? 'stop'
                                        : (hasText ? 'send' : 'mic'),
                                  ),
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
