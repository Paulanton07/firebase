import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_ai/firebase_ai.dart' as firebase_ai;
import 'dart:typed_data';

import 'services/audio_recorder_service.dart';
import 'services/audio_player_service.dart';
import 'services/audio_data_service.dart';
import 'widgets/chat_bubble.dart';

class VoiceMessagingPage extends StatefulWidget {
  const VoiceMessagingPage({super.key});

  @override
  State<VoiceMessagingPage> createState() => _VoiceMessagingPageState();
}

class _VoiceMessagingPageState extends State<VoiceMessagingPage> {
  final AudioRecorderService _recorderService = AudioRecorderService();
  final AudioPlayerService _playerService = AudioPlayerService();
  final AudioDataService _audioDataService = AudioDataService();
  final List<VoiceMessage> _messages = [];
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _recorderService.init();
  }

  @override
  void dispose() {
    _recorderService.dispose();
    _playerService.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (kIsWeb) {
        await _recorderService.startRecording();
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final path =
            '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _recorderService.startRecording(path: path);
      }
      setState(() {
        _isRecording = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start recording: $e')),
      );
    }
  }

  Future<void> _stopRecording() async {
    try {
      final String? path = await _recorderService.stopRecording();
      setState(() {
        _isRecording = false;
      });
      if (path != null) {
        final newMessage = VoiceMessage(audioPath: path);
        setState(() {
          _messages.add(newMessage);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recording saved')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to stop recording: $e')),
      );
    }
  }

  Future<void> _playMessage(VoiceMessage message) async {
    if (_playerService.isPlaying) {
      await _playerService.stop();
    } else {
      await _playerService.play(message.audioPath);
    }
  }

  Future<void> _transcribeMessage(VoiceMessage message) async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transcription is not available on web')),
      );
      return;
    }
    setState(() {
      message.isTranscribing = true;
    });

    try {
      final model = firebase_ai.FirebaseVertexAI.instance
          .generativeModel(model: 'gemini-1.5-flash');
      final audioData = await _audioDataService.getAudioData(message.audioPath);

      final response = await model.generateContent([
        firebase_ai.Content.multi([
          const firebase_ai.TextPart('Transcribe the following audio:'),
          firebase_ai.DataPart('audio/mp4', audioData),
        ]),
      ]);

      setState(() {
        message.transcription = response.text;
        message.isTranscribing = false;
      });
    } catch (e) {
      setState(() {
        message.isTranscribing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error transcribing audio: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Messages'),
      ),
      body: ListView.builder(
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final message = _messages[index];
          return ChatBubble(
            message: message,
            onPlay: () => _playMessage(message),
            audioPlayerService: _playerService,
            onTranscribe: () => _transcribeMessage(message),
            showTranscribeButton: !kIsWeb,
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isRecording ? _stopRecording : _startRecording,
        child: Icon(_isRecording ? Icons.stop : Icons.mic),
      ),
    );
  }
}

class VoiceMessage {
  final String audioPath;
  String? transcription;
  bool isTranscribing;

  VoiceMessage({
    required this.audioPath,
    this.transcription,
    this.isTranscribing = false,
  });
}
