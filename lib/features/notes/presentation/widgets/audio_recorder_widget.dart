// ignore_for_file: use_build_context_synchronously
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
  double _currentAmplitude = -160.0; // Min dB

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    if (widget.autoStart) {
      // Delay slightly to ensure UI is ready
      Future.delayed(const Duration(milliseconds: 500), _startRecording);
    }
  }

  @override
  void dispose() {
    _amplitudeTimer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  void _startAmplitudeTimer() {
    _amplitudeTimer?.cancel();
    _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 100), (
      timer,
    ) async {
      if (!_isRecording) return;
      final amp = await _audioRecorder.getAmplitude();
      if (context.mounted) {
        setState(() {
          _currentAmplitude = amp.current;
        });
      }
    });
  }

  Future<void> _handlePress() async {
    final speechService = ref.read(localSpeechServiceProvider);
    if (_isRecording || speechService.isListening) {
      await _stopRecording();
    } else {
      final configService = ref.read(aiConfigServiceProvider);
      final isConfigured = await configService.isConfigured();
      final alwaysLocal = await configService.getAlwaysUseLocalSTT();

      if (!isConfigured || alwaysLocal) {
        await _startLocalTranscription();
      } else {
        await _startRecording();
      }
    }
  }

  Future<void> _startLocalTranscription() async {
    final speechService = ref.read(localSpeechServiceProvider);

    setState(() {
      _isRecording = true;
    });

    final result = await speechService.transcribeLive(
      onListeningStopped: () {
        if (mounted) {
          setState(() => _isRecording = false);
        }
      },
    );

    if (result != null && result.isNotEmpty && mounted) {
      widget.onRecordingComplete('', result);
    }
  }

  Future<void> _startRecording() async {
    try {
      // Request microphone permission
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

        _startAmplitudeTimer();

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
    final speechService = ref.read(localSpeechServiceProvider);
    if (speechService.isListening) {
      speechService.stop();
      return;
    }

    _amplitudeTimer?.cancel();
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

        // Start Transcription
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
      final configService = ref.read(aiConfigServiceProvider);
      final userApiKey = await configService.getApiKey();

      // Require user-configured API key — no hardcoded fallback
      if (userApiKey == null || userApiKey.isEmpty) {
        widget.onRecordingComplete(path, null);
        return;
      }

      final userEndpoint = await configService.getEndpoint();
      String whisperUrl = 'https://api.groq.com/openai/v1/audio/transcriptions';
      String whisperKey = 'Bearer $userApiKey';

      if (userEndpoint.contains('openai.com')) {
        whisperUrl = 'https://api.openai.com/v1/audio/transcriptions';
      } else if (userEndpoint.contains('groq.com')) {
        whisperUrl = 'https://api.groq.com/openai/v1/audio/transcriptions';
      }

      final request = http.MultipartRequest('POST', Uri.parse(whisperUrl));

      request.headers['Authorization'] = whisperKey;
      request.fields['model'] = whisperUrl.contains('openai.com')
          ? 'whisper-1'
          : 'whisper-large-v3';
      request.fields['language'] = 'tr'; // Turkish

      request.files.add(await http.MultipartFile.fromPath('file', path));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      debugPrint('Groq Response: ${response.statusCode} - $responseBody');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(responseBody);
        final text = jsonResponse['text'] as String?;

        // Delete the audio file to save space (User Request)
        if (await File(path).exists()) {
          await File(path).delete();
          debugPrint('Deleted audio file to save space: $path');
        }

        widget.onRecordingComplete('', text);
      } else {
        debugPrint('Transcription failed');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(
                  context,
                )!.transcriptionError(response.statusCode),
              ),
            ),
          );
        }
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
          const SizedBox(height: 16), // Changed Gap to SizedBox
          Text(AppLocalizations.of(context)!.aiTranscribing),
        ],
      );
    }

    // Normalize dB (-50 to 0) to 0.0 - 1.0 for visual height
    // Usually silence is -160, quiet room -60, loud -10.
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
                Expanded(
                  child: Text(
                    'Ses kaydedildi',
                    style: const TextStyle(fontSize: 12),
                  ),
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
            padding: EdgeInsets.all(12 + (normalized * 10)), // Pulse effect
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
