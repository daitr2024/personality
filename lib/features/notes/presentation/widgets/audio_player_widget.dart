import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String audioPath;

  const AudioPlayerWidget({super.key, required this.audioPath});

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (context.mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((newDuration) {
      if (context.mounted) {
        setState(() => _duration = newDuration);
      }
    });

    _audioPlayer.onPositionChanged.listen((newPosition) {
      if (context.mounted) {
        setState(() => _position = newPosition);
      }
    });
    
    // Set source efficiently without auto-playing
    _audioPlayer.setSourceDeviceFile(widget.audioPath);
    _audioPlayer.setVolume(1.0); // Ensure max volume
    
    // Listen for errors
    _audioPlayer.onLog.listen((log) {
      debugPrint('AudioPlayer Log: $log');
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
            onPressed: () async {
              if (_isPlaying) {
                await _audioPlayer.pause();
              } else {
                await _audioPlayer.play(DeviceFileSource(widget.audioPath));
              }
            },
            color: Colors.blue,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            iconSize: 24,
          ),
          const SizedBox(width: 8),
          Text(
            '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}




