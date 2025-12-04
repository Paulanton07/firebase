import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_voice_messenger/services/audio_service.dart';

class AudioViewModel with ChangeNotifier {
  final AudioService _audioService;

  AudioViewModel(this._audioService) {
    _audioService.onPlayerStateChanged.listen((isPlaying) {
      _isPlaying = isPlaying;
      if (!isPlaying) {
        _currentPlayingIndex = -1; // Reset when playback finishes
        _currentUrl = null;
      }
      notifyListeners();
    });
  }

  // State for both voice messages and radio
  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  // State for voice message recording
  bool _isRecording = false;
  bool get isRecording => _isRecording;

  // State for voice message playback
  final List<String> _recordings = [];
  List<String> get recordings => _recordings;
  int _currentPlayingIndex = -1;
  int get currentPlayingIndex => _currentPlayingIndex;

  // State for radio playback
  bool _isRadioMode = false;
  bool get isRadioMode => _isRadioMode;
  String? _currentUrl;
  String? get currentUrl => _currentUrl;


  // --- Methods ---

  // Unified Play method
  Future<void> play(String url, {bool isRadio = false}) async {
    // If another track is playing, or a radio stream, stop it first.
    if (_isPlaying) {
      await stop();
    }

    _isRadioMode = isRadio;
    _currentUrl = url;
    if (!isRadio) {
      // Find the index of the recording being played
      _currentPlayingIndex = _recordings.indexOf(url);
    }
    
    await _audioService.play(url);
    // The listener will update _isPlaying to true.
    notifyListeners();
  }

  Future<void> pause() async {
    await _audioService.pause();
    // The listener will update _isPlaying to false.
    notifyListeners();
  }

  Future<void> stop() async {
    await _audioService.stop();
    _isPlaying = false;
    _isRadioMode = false;
    _currentPlayingIndex = -1;
    _currentUrl = null;
    notifyListeners();
  }

  Future<void> startRecording() async {
    if (_isRecording) return;
    try {
      _isRecording = true;
      notifyListeners();
      await _audioService.record();
    } catch (e) {
      _isRecording = false;
      notifyListeners();
      // Handle recording error
    }
  }

  Future<String?> stopRecording() async {
    if (!_isRecording) return null;
    try {
      final path = await _audioService.stopRecording();
      if (path != null) {
        _recordings.add(path);
      }
      _isRecording = false;
      notifyListeners();
      return path;
    } catch (e) {
      _isRecording = false;
      notifyListeners();
      // Handle recording error
      return null;
    }
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
}
