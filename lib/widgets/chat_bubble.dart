import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../models/voice_message.dart';
import '../services/audio_player_service.dart';

class ChatBubble extends StatelessWidget {
  final VoiceMessage message;
  final VoidCallback onPlay;
  final AudioPlayerService audioPlayerService;
  final VoidCallback onTranscribe;
  final bool showTranscribeButton;

  const ChatBubble({
    super.key,
    required this.message,
    required this.onPlay,
    required this.audioPlayerService,
    required this.onTranscribe,
    this.showTranscribeButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text('Voice Message'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ValueListenableBuilder<PlayerState>(
            valueListenable: audioPlayerService.playerState,
            builder: (context, playerState, child) {
              return ValueListenableBuilder<Duration>(
                valueListenable: audioPlayerService.position,
                builder: (context, position, child) {
                  return ValueListenableBuilder<Duration?>(
                    valueListenable: audioPlayerService.totalDuration,
                    builder: (context, totalDuration, child) {
                      return Column(
                        children: [
                          Slider(
                            value: position.inMilliseconds.toDouble(),
                            min: 0.0,
                            max: totalDuration?.inMilliseconds.toDouble() ?? 0.0,
                            onChanged: (value) {
                              audioPlayerService.seek(Duration(milliseconds: value.toInt()));
                            },
                          ),
                          Text(
                            '${position.inMinutes}:${(position.inSeconds % 60).toString().padLeft(2, '0')} / '
                            '${totalDuration?.inMinutes ?? 0}:${(totalDuration?.inSeconds ?? 0 % 60).toString().padLeft(2, '0')}',
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
          if (message.isTranscribing)
            const CircularProgressIndicator()
          else if (message.transcription != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(message.transcription!),
            )
          else if (showTranscribeButton)
            TextButton(
              onPressed: onTranscribe,
              child: const Text('Transcribe'),
            ),
        ],
      ),
      leading: IconButton(
        icon: ValueListenableBuilder<PlayerState>(
          valueListenable: audioPlayerService.playerState,
          builder: (context, playerState, child) {
            return Icon(
              playerState.playing ? Icons.pause : Icons.play_arrow,
            );
          },
        ),
        onPressed: onPlay,
      ),
    );
  }
}
