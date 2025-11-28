
import 'dart:async';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String targetUid;
  final String targetEmail;

  const ChatScreen({
    super.key,
    required this.targetUid,
    required this.targetEmail,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TextEditingController _messageController = TextEditingController();
  String? _audioPath;
  Uint8List? _audioBytes;
  bool _isRecording = false;
  String _status = '';
  late String _chatId;

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _chatId = _getChatId(currentUser.uid, widget.targetUid);
    }
  }

  String _getChatId(String uid1, String uid2) {
    return uid1.compareTo(uid2) < 0 ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _messageController.dispose();
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
    final storageRef = FirebaseStorage.instance.ref().child('chats/$_chatId/$fileName.m4a');

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
      final user = FirebaseAuth.instance.currentUser;

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(_chatId)
          .collection('messages')
          .add({
        'type': 'voice',
        'url': downloadUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'senderId': user?.uid,
        'senderEmail': user?.email,
      });

      setState(() => _status = '');
    } catch (e) {
      setState(() => _status = 'Error saving voice message: $e');
    }
  }

  Future<void> _play(String url) async {
    try {
      await _audioPlayer.play(UrlSource(url));
    } catch (e) {
      setState(() => _status = 'Error playing audio: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.targetEmail),
      ),
      body: Column(
        children: [
          if (_status.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(_status, style: const TextStyle(color: Colors.grey)),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(_chatId)
                  .collection('messages')
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
                return ListView.builder(
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == currentUser?.uid;
                    final timestamp = data['createdAt'] as Timestamp?;
                    final date = timestamp?.toDate();
                    final formattedDate = date != null
                        ? DateFormat.jm().format(date)
                        : '';

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (data['type'] == 'voice')
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.play_arrow),
                                    onPressed: () => _play(data['url']),
                                  ),
                                  const Text('Voice Message'),
                                ],
                              )
                            else
                              Text(data['text'] ?? ''),
                            const SizedBox(height: 4),
                            Text(
                              formattedDate,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onLongPressStart: (_) => _startRecording(),
                    onLongPressEnd: (_) => _stopRecording(),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: _isRecording ? Colors.red : Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Center(
                        child: Text(
                          _isRecording ? 'Release to Send' : 'Hold to Record',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
