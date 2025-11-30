import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class VoiceMessagingPage extends StatefulWidget {
  const VoiceMessagingPage({super.key});

  @override
  State<VoiceMessagingPage> createState() => _VoiceMessagingPageState();
}

class _VoiceMessagingPageState extends State<VoiceMessagingPage> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _audioPath;
  Uint8List? _audioBytes; // Web capture
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
          final path = '${directory.path}/temp_${DateTime.now().millisecondsSinceEpoch}.m4a';
          await _audioRecorder.start(recordConfig, path: path);
          _audioPath = path;
        }
        setState(() => _isRecording = true);
      } else {
        setState(() => _status = 'Microphone permission denied');
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
        _status = 'Uploading...';
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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _status = 'Not authenticated');
      return;
    }
    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final ref = FirebaseStorage.instance.ref().child('voice_messages/$fileName.m4a');
    try {
      UploadTask uploadTask;
      if (kIsWeb) {
        if (_audioBytes == null) {
          setState(() => _status = 'No audio data');
          return;
        }
        uploadTask = ref.putData(_audioBytes!);
      } else {
        if (_audioPath == null) {
          setState(() => _status = 'No file path');
          return;
        }
        uploadTask = ref.putFile(File(_audioPath!));
      }
      final snap = await uploadTask;
      final url = await snap.ref.getDownloadURL();
      await FirebaseFirestore.instance.collection('voice_messages').add({
        'url': url,
        'userId': user.uid,
        'userEmail': user.email,
        'createdAt': FieldValue.serverTimestamp(),
      });
      setState(() => _status = 'Saved');
    } catch (e) {
      setState(() => _status = 'Upload failed: $e');
    }
  }

  Future<void> _play(String url) async {
    try {
      setState(() => _status = 'Playing...');
      await _audioPlayer.play(UrlSource(url));
      _audioPlayer.onPlayerComplete.first.then((_) => setState(() => _status = 'Finished'));
    } catch (e) {
      setState(() => _status = 'Play error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Voice Messages')),
      body: Column(
        children: [
          if (_status.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(_status, style: Theme.of(context).textTheme.labelMedium),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('voice_messages')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text('No voice messages yet'));
                }
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final url = data['url'] as String?;
                    final email = data['userEmail'] as String? ?? 'Unknown';
                    final ts = data['createdAt'] as Timestamp?;
                    final dt = ts?.toDate();
                    final when = dt != null ? DateFormat.yMMMd().add_jm().format(dt) : '';
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: IconButton(
                          icon: const Icon(Icons.play_arrow),
                          onPressed: url == null ? null : () => _play(url),
                        ),
                        title: Text(email),
                        subtitle: Text(when),
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
