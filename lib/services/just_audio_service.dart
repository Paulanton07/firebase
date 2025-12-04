import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';
import 'package:flutter_voice_messenger/services/audio_service.dart';

class JustAudioService implements AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioRecorder _audioRecorder = AudioRecorder();

  @override
  Stream<bool> get onPlayerStateChanged => _audioPlayer.playerStateStream.map((state) => state.playing);

  @override
  Future<void> play(String url) async {
    if (url.startsWith('http')) {
      await _audioPlayer.setUrl(url);
    } else {
      await _audioPlayer.setFilePath(url);
    }
    _audioPlayer.play();
  }

  @override
  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  @override
  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  @override
  Future<void> record() async {
    if (await _audioRecorder.hasPermission()) {
      await _audioRecorder.start(const RecordConfig(), path: 'myFile.m4a');
    }
  }

  @override
  Future<String?> stopRecording() async {
    return await _audioRecorder.stop();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _audioRecorder.dispose();
  }
}
