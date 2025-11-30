
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'transcription_service_stub.dart'
    if (dart.library.io) 'transcription_service.dart';

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

class VoiceMessagingPage extends StatefulWidget {
  const VoiceMessagingPage({super.key});

  @override
  _VoiceMessagingPageState createState() => _VoiceMessagingPageState();
}

class _VoiceMessagingPageState extends State<VoiceMessagingPage> {
  bool _isRecording = false;
  final List<VoiceMessage> _messages = [];
  late final AudioRecorder _recorder;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _recorder = AudioRecorder();
  }

  @override
  void dispose() {
    _recorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (await _recorder.hasPermission()) {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );
      setState(() {
        _isRecording = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission not granted')),
      );
    }
  }

  Future<void> _stopRecording() async {
    final path = await _recorder.stop();
    if (path != null) {
      setState(() {
        _isRecording = false;
        _messages.add(VoiceMessage(audioPath: path));
      });
    }
  }

  Future<void> _playRecording(String path) async {
    await _audioPlayer.play(DeviceFileSource(path));
  }

  Future<void> _transcribeAudio(VoiceMessage message) async {
    setState(() {
      message.isTranscribing = true;
    });

    try {
      final transcription = await transcribeAudio(message.audioPath);
      setState(() {
        message.transcription = transcription;
      });
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during transcription: $e')),
      );
    } finally {
      setState(() {
        message.isTranscribing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Messages'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return ListTile(
                  title: Text(message.transcription ?? 'Press transcribe to generate text'),
                  subtitle: message.isTranscribing
                      ? const LinearProgressIndicator()
                      : null,
                  leading: IconButton(
                    icon: const Icon(Icons.play_arrow),
                    onPressed: () => _playRecording(message.audioPath),
                  ),
                  trailing: kIsWeb
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.translate),
                          onPressed: () => _transcribeAudio(message),
                        ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FloatingActionButton(
              onPressed: _isRecording ? _stopRecording : _startRecording,
              backgroundColor: _isRecording ? Colors.red : Theme.of(context).primaryColor,
              child: Icon(_isRecording ? Icons.stop : Icons.mic),
            ),
          ),
        ],
      ),
    );
  }
}
