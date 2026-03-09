import 'package:record/record.dart';

/// Shared recording configurations to avoid duplication across widgets.
class RecordingDefaults {
  RecordingDefaults._();

  /// Voice-optimized recording config with noise suppression,
  /// echo cancellation, and auto gain.
  /// Uses voiceCommunication audio source for near-field voice priority.
  /// Mutes other audio streams to avoid background interference.
  static const voiceConfig = RecordConfig(
    encoder: AudioEncoder.wav,
    numChannels: 1,
    autoGain: true,
    echoCancel: true,
    noiseSuppress: true,
    androidConfig: AndroidRecordConfig(
      audioSource: AndroidAudioSource.voiceCommunication,
      muteAudio: true,
    ),
  );

  /// Silence detection thresholds
  static const double silenceThresholdDb = -50.0;
  static const Duration gracePeriod = Duration(seconds: 3);
  static const Duration silenceDuration = Duration(seconds: 3);
  static const Duration amplitudeCheckInterval = Duration(milliseconds: 200);
}
