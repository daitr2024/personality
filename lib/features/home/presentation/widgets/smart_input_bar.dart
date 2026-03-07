import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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
    _controller.dispose();
    _audioRecorder.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      _controller.clear();
      // Directly analyze text
      showDialog(
        context: context,
        builder: (context) => AudioAnalysisDialog(text: text),
      );
    }
  }

  Future<void> _toggleRecording() async {
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
      _controller.text = '';
    });
    _pulseController.repeat(reverse: true);

    try {
      final result = await speechService.transcribeLive(
        onPartialResult: (text) {
          setState(() => _controller.text = text);
        },
        onListeningStopped: () {
          if (mounted) {
            setState(() {
              _isRecording = false;
              _pulseController.stop();
              _pulseController.reset();
            });
          }
        },
      );

      if (result != null && result.isNotEmpty && mounted) {
        showDialog(
          context: context,
          builder: (context) => AudioAnalysisDialog(text: result),
        );
      }
    } catch (e) {
      debugPrint('Local STT Error: $e');
      setState(() => _isRecording = false);
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
      }
    } catch (e) {
      debugPrint('Start error: $e');
    }
  }

  Future<void> _stopRecording() async {
    final speechService = ref.read(localSpeechServiceProvider);
    if (speechService.isListening) {
      speechService.stop();
      return;
    }

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
      final configService = ref.read(aiConfigServiceProvider);
      final userApiKey = await configService.getApiKey();
      final userEndpoint = await configService.getEndpoint();

      // If user has a custom endpoint (like Groq or OpenAI), use it for transcription too
      String whisperUrl = 'https://api.groq.com/openai/v1/audio/transcriptions';
      String whisperKey = '';

      // Require user-configured API key — no hardcoded fallback
      if (userApiKey == null || userApiKey.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.apiKeyNotSet),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      whisperKey = 'Bearer $userApiKey';
      if (userEndpoint.contains('openai.com')) {
        whisperUrl = 'https://api.openai.com/v1/audio/transcriptions';
      } else if (userEndpoint.contains('groq.com')) {
        whisperUrl = 'https://api.groq.com/openai/v1/audio/transcriptions';
      }
      // If it's a generic OpenAI-compatible endpoint, we try to append the standard path
      // but for now let's stick to known providers for reliability

      final request = http.MultipartRequest('POST', Uri.parse(whisperUrl));
      request.headers['Authorization'] = whisperKey;
      request.fields['model'] = whisperUrl.contains('openai.com')
          ? 'whisper-1'
          : 'whisper-large-v3';
      request.fields['language'] = 'tr';
      request.files.add(await http.MultipartFile.fromPath('file', path));

      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final text = jsonDecode(body)['text'];
        if (text != null && mounted) {
          showDialog(
            context: context,
            builder: (context) =>
                AudioAnalysisDialog(text: text, audioPath: path),
          );
        }
      } else {
        if (mounted) {
          String errorMsg = 'Ses analizi hatası (${response.statusCode})';
          try {
            final errorData = jsonDecode(body);
            if (errorData['error']?['message'] != null) {
              errorMsg = errorData['error']['message'];
            }
          } catch (_) {}

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      debugPrint('Transcribe error: $e');
    } finally {
      if (context.mounted) setState(() => _isTranscribing = false);
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
