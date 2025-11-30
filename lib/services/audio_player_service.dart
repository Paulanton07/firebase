import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();

  final ValueNotifier<PlayerState> playerState = ValueNotifier(PlayerState(false, ProcessingState.idle));
  final ValueNotifier<Duration> position = ValueNotifier(Duration.zero);
  final ValueNotifier<Duration?> totalDuration = ValueNotifier(null);

  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;

  AudioPlayerService() {
    _playerStateSubscription = _player.playerStateStream.listen((state) {
      playerState.value = state;
    });
    _positionSubscription = _player.positionStream.listen((pos) {
      position.value = pos;
    });
    _durationSubscription = _player.durationStream.listen((dur) {
      totalDuration.value = dur;
    });
  }

  bool get isPlaying => _player.playing;

  Future<void> play(String path) async {
    try {
      if (path.startsWith('http')) {
        await _player.setUrl(path);
      } else {
        await _player.setFilePath(path);
      }
      await _player.play();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> stop() async {
    await _player.stop();
    position.value = Duration.zero;
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  void dispose() {
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    playerState.dispose();
    position.dispose();
    totalDuration.dispose();
    _player.dispose();
  }
}
