import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_voice_messenger/providers/audio_view_model.dart';

class VoiceMessagingPage extends StatelessWidget {
  const VoiceMessagingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final audioViewModel = Provider.of<AudioViewModel>(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface.withAlpha((255 * 0.95).round()),
      appBar: AppBar(
        title: const Text('Voice Messages'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.textTheme.bodyLarge?.color,
      ),
      body: Column(
        children: [
          Expanded(
            child: audioViewModel.recordings.isEmpty
                ? Center(
                    child: Text(
                      'No recordings yet.\nHold the button below to record.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                    ),
                  )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              itemCount: audioViewModel.recordings.length,
              itemBuilder: (context, index) {
                final recording = audioViewModel.recordings[index];
                final isPlaying = audioViewModel.isPlaying && audioViewModel.currentPlayingIndex == index;
                return Card(
                  elevation: 4.0,
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                    title: Text(
                      'Recording ${index + 1}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isPlaying ? theme.primaryColor : null,
                      ),
                    ),
                    subtitle: Text(
                      'Press to play',
                      style: theme.textTheme.bodySmall,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: isPlaying ? theme.primaryColor.withAlpha((255 * 0.1).round()) : Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: isPlaying ? theme.primaryColor : Colors.black,
                        size: 30.0,
                      ),
                    ),
                    onTap: () {
                      if (isPlaying) {
                        audioViewModel.pause();
                      } else {
                        audioViewModel.play(recording);
                      }
                    },
                  ),
                );
              },
            ),
          ),
          _buildRecordButton(context, audioViewModel),
        ],
      ),
    );
  }

  Widget _buildRecordButton(BuildContext context, AudioViewModel audioViewModel) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 40.0, top: 20.0),
      child: GestureDetector(
        onLongPressStart: (_) => audioViewModel.startRecording(),
        onLongPressEnd: (_) async {
          await audioViewModel.stopRecording();
        },
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: audioViewModel.isRecording
                  ? [Colors.red.shade400, Colors.red.shade700]
                  : [theme.primaryColor, theme.colorScheme.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: audioViewModel.isRecording ? Colors.red.withAlpha((255 * 0.5).round()) : theme.primaryColor.withAlpha((255 * 0.5).round()),
                spreadRadius: 3,
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Icon(
            audioViewModel.isRecording ? Icons.stop : Icons.mic,
            color: Colors.white,
            size: 40,
          ),
        ),
      ),
    );
  }
}
