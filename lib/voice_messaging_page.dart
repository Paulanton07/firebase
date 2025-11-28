
import 'dart:async';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';


class VoiceMessagingPage extends StatefulWidget {
  const VoiceMessagingPage({super.key});

  @override
  _VoiceMessagingPageState createState() => _VoiceMessagingPageState();
}

class _VoiceMessagingPageState extends State<VoiceMessagingPage> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _audioPath;
  Uint8List? _audioBytes;
  bool _isRecording = false;
  String _status = '';

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        setState(() => _status = 'Recording...');
        const recordConfig = RecordConfig(encoder: AudioEncoder.aacLc);
        if (kIsWeb) {
          await _audioRecorder.start(recordConfig, path: '');
        } else {
          final directory = await getApplicationDocumentsDirectory();
          final path = '${directory.path}/temp.m4a';
          await _audioRecorder.start(recordConfig, path: path);
          _audioPath = path;
        }
        setState(() => _isRecording = true);
      } else {
        setState(() => _status = 'Microphone permission is required.');
      }
    } catch (e) {
      setState(() => _status = 'Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final dynamic audioData = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _status = 'Recording stopped, uploading...';
      });
      if (kIsWeb) {
        _audioBytes = audioData;
      }
      await _uploadAndSave();
    } catch (e) {
      setState(() => _status = 'Error stopping recording: $e');
    }
  }

  Future<void> _uploadAndSave() async {
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final storageRef = FirebaseStorage.instance.ref().child('voice_messages/$fileName.m4a');

    try {
      UploadTask uploadTask;
      if (kIsWeb) {
        if (_audioBytes == null) return;
        uploadTask = storageRef.putData(_audioBytes!);
      } else {
        if (_audioPath == null) return;
        final file = File(_audioPath!);
        uploadTask = storageRef.putFile(file);
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('voice_messages').add({
        'url': downloadUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() => _status = 'Voice message saved!');
    } catch (e) {
      setState(() => _status = 'Error saving voice message: $e');
    }
  }

  Future<void> _play(String url) async {
    try {
      setState(() => _status = 'Playing...');
      await _audioPlayer.play(UrlSource(url));
      _audioPlayer.onPlayerComplete.first.then((_) => setState(() => _status = 'Playback finished.'));
    } catch (e) {
      setState(() => _status = 'Error playing audio: $e');
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(_status, style: Theme.of(context).textTheme.titleMedium),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('voice_messages').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final url = doc['url'];
                    final timestamp = doc['createdAt'] as Timestamp?;
                    final date = timestamp?.toDate();
                    final formattedDate = date != null ? DateFormat.yMMMd().add_jm().format(date) : '';


                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text('Voice Message ${index + 1}'),
                        subtitle: Text(formattedDate),
                        leading: IconButton(
                          icon: const Icon(Icons.play_arrow),
                          onPressed: () => _play(url),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isRecording ? _stopRecording : _startRecording,
        child: Icon(_isRecording ? Icons.stop : Icons.mic),
      ),
    );
  }
}
