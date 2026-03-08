// ignore_for_file: use_build_context_synchronously
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:intl/intl.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../settings/presentation/providers/ai_config_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';

class AudioRecorderWidget extends ConsumerStatefulWidget {
  final Function(String path, String? transcription) onRecordingComplete;
  final bool autoStart;

  const AudioRecorderWidget({
    super.key,
    required this.onRecordingComplete,
    this.autoStart = false,
  });

  @override
  ConsumerState<AudioRecorderWidget> createState() =>
      _AudioRecorderWidgetState();
}

class _AudioRecorderWidgetState extends ConsumerState<AudioRecorderWidget> {
  late final AudioRecorder _audioRecorder;

  bool _isRecording = false;
  bool _isTranscribing = false;
  String? _recordingPath;

  Timer? _amplitudeTimer;
  Timer? _silenceTimer;
  Timer? _graceTimer;
  double _currentAmplitude = -160.0;
  static const double _silenceThresholdDb = -50.0;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    if (widget.autoStart) {
      Future.delayed(const Duration(milliseconds: 500), _startRecording);
    }
  }

  @override
  void dispose() {
    _amplitudeTimer?.cancel();
    _silenceTimer?.cancel();
    _graceTimer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  void _startAmplitudeTimer({bool enableAutoStop = true}) {
    _amplitudeTimer?.cancel();
    _silenceTimer?.cancel();
    _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 200), (
      timer,
    ) async {
      if (!_isRecording) return;
      final amp = await _audioRecorder.getAmplitude();
      if (context.mounted) {
        setState(() {
          _currentAmplitude = amp.current;
        });

        // Only auto-stop if the setting is enabled
        if (enableAutoStop) {
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
        }
      }
    });
  }

  Future<void> _handlePress() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      var status = await Permission.microphone.status;
      if (status != PermissionStatus.granted) {
        status = await Permission.microphone.request();
      }

      if (status == PermissionStatus.granted &&
          await _audioRecorder.hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        final path = '${directory.path}/Note_$timestamp.wav';

        const config = RecordConfig(encoder: AudioEncoder.wav);
        await _audioRecorder.start(config, path: path);

        // Check if auto-stop on silence is enabled
        final configService = ref.read(aiConfigServiceProvider);
        final autoStop = await configService.getAutoStopOnSilence();

        // Always start amplitude timer for visual feedback
        _startAmplitudeTimer(enableAutoStop: false);

        // Grace period: wait 3 seconds before enabling silence detection
        if (autoStop) {
          _graceTimer = Timer(const Duration(seconds: 3), () {
            if (_isRecording && mounted) {
              // Cancel the visual-only timer and restart with auto-stop
              _amplitudeTimer?.cancel();
              _startAmplitudeTimer(enableAutoStop: true);
            }
          });
        }

        debugPrint('Started recording to: $path');

        setState(() {
          _isRecording = true;
          _recordingPath = null;
        });
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.microphonePermissionRequired,
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error starting record: $e');
    }
  }

  Future<void> _stopRecording() async {
    _silenceTimer?.cancel();
    _silenceTimer = null;
    _amplitudeTimer?.cancel();
    _graceTimer?.cancel();

    try {
      final path = await _audioRecorder.stop();

      setState(() {
        _isRecording = false;
        _recordingPath = path;
      });

      if (path != null) {
        final file = File(path);
        final size = await file.length();
        debugPrint('Recording saved to: $path (Size: $size bytes)');

        if (size > 0) {
          await _transcribeAudio(path);
        } else {
          widget.onRecordingComplete(path, null);
        }
      }
    } catch (e) {
      debugPrint('Error stopping record: $e');
    }
  }

  Future<void> _transcribeAudio(String path) async {
    setState(() {
      _isTranscribing = true;
    });

    try {
      // Use Gemini API to transcribe audio
      final analysisService = ref.read(audioAnalysisServiceProvider);
      final transcribedText = await analysisService.transcribeAudioFile(path);

      if (transcribedText != null && transcribedText.isNotEmpty && mounted) {
        // Delete the audio file to save space
        if (await File(path).exists()) {
          await File(path).delete();
          debugPrint('Deleted audio file to save space: $path');
        }

        widget.onRecordingComplete('', transcribedText);
      } else {
        widget.onRecordingComplete(path, null);
      }
    } catch (e) {
      debugPrint('Transcription error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.errorGeneric(e.toString()),
            ),
          ),
        );
      }
      widget.onRecordingComplete(path, null);
    } finally {
      if (context.mounted) {
        setState(() {
          _isTranscribing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isTranscribing) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context)!.aiTranscribing),
        ],
      );
    }

    final normalized = ((_currentAmplitude + 60) / 60).clamp(0.0, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_recordingPath != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Ses kaydedildi', style: TextStyle(fontSize: 12)),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                  onPressed: () {
                    setState(() => _recordingPath = null);
                  },
                ),
              ],
            ),
          ),
        GestureDetector(
          onTap: _handlePress,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            padding: EdgeInsets.all(12 + (normalized * 10)),
            decoration: BoxDecoration(
              color: _isRecording ? Colors.red.shade100 : Colors.blue.shade50,
              shape: BoxShape.circle,
              border: _isRecording
                  ? Border.all(
                      color: Colors.red.withValues(alpha: 0.5),
                      width: 2 + (normalized * 5),
                    )
                  : null,
            ),
            child: Icon(
              _isRecording ? Icons.stop : Icons.mic,
              color: _isRecording ? Colors.red : Colors.blue,
              size: 32,
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (_isRecording) ...[
          SizedBox(
            width: 100,
            height: 4,
            child: LinearProgressIndicator(
              value: normalized,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
            ),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          _isRecording ? 'Dinleniyor...' : 'Sesle metin ekle (AI)',
          style: TextStyle(
            fontSize: 12,
            color: _isRecording ? Colors.red : Colors.grey,
          ),
        ),
      ],
    );
  }
}
