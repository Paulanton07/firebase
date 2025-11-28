
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'radio_station.dart';

class RadioProvider with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<RadioStation> _stations = [];

  bool _isPlaying = false;
  bool _isLoading = false; // Kept for potential future use, but won't be used for the button
  int _selectedIndex = 0;
  static const _stationsKey = 'radio_stations';

  List<RadioStation> get stations => _stations;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  int get selectedIndex => _selectedIndex;
  // This getter tells the UI what the player is ACTUALLY playing
  int? get playingIndex => _audioPlayer.currentIndex;

  RadioProvider() {
    _setupListeners();
  }

  Future<void> init() async {
    await _loadStations();
    await _rebuildAudioSource();
  }

  Future<void> _rebuildAudioSource() async {
    if (_stations.isEmpty) return;
    try {
      final playlist = ConcatenatingAudioSource(
        children: _stations.map((s) => AudioSource.uri(Uri.parse(s.url))).toList(),
      );
      await _audioPlayer.setAudioSource(playlist, initialIndex: _selectedIndex, preload: false);
    } catch (e, s) {
      developer.log('Error rebuilding audio source', name: 'RadioProvider', error: e, stackTrace: s);
    }
  }

  void _setupListeners() {
    _audioPlayer.playerStateStream.listen((state) {
      final isPlaying = state.playing;
      final isLoading = [ProcessingState.loading, ProcessingState.buffering].contains(state.processingState);

      if (isPlaying != _isPlaying || isLoading != _isLoading) {
        _isPlaying = isPlaying;
        _isLoading = isLoading;
        notifyListeners();
      }
    });

    // Listen for when the player *actually* changes the playing station
    _audioPlayer.currentIndexStream.listen((index) {
        notifyListeners();
    });

    _audioPlayer.playbackEventStream.listen((event) {},
        onError: (Object e, StackTrace stackTrace) {
      developer.log('A playback error occurred: $e',
          name: 'RadioProvider', error: e, stackTrace: stackTrace);
    });
  }

  Future<void> _loadStations() async {
    final prefs = await SharedPreferences.getInstance();
    final stationStrings = prefs.getStringList(_stationsKey);
    if (stationStrings != null && stationStrings.isNotEmpty) {
      try {
        _stations = stationStrings
          .map((s) => RadioStation.fromJson(jsonDecode(s)))
          .toList();
      } catch (e) {
        _stations = [ RadioStation(name: 'BBC Radio 1', url: 'https://stream.live.vc.bbcmedia.co.uk/bbc_radio_one') ];
      }
    } else {
        _stations = [ RadioStation(name: 'BBC Radio 1', url: 'https://stream.live.vc.bbcmedia.co.uk/bbc_radio_one') ];
    }
    notifyListeners();
  }

  Future<void> _saveStations() async {
    final prefs = await SharedPreferences.getInstance();
    final stationStrings =
        _stations.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList(_stationsKey, stationStrings);
  }

  // Plays the station at the currently selected index
  void play() {
     playAtIndex(_selectedIndex);
  }

  // Selects a station without playing it
  void selectStation(int index) {
    if (index >= 0 && index < _stations.length) {
      _selectedIndex = index;
      notifyListeners();
    }
  }

  void playAtIndex(int index) {
    selectStation(index);
    if (index >= 0 && index < _stations.length) {
      if (_audioPlayer.currentIndex != index) {
         _audioPlayer.seek(Duration.zero, index: index).then((_) => _audioPlayer.play());
      } else {
         _audioPlayer.play();
      }
    }
  }

  void pause() {
    _audioPlayer.pause();
  }

  Future<void> addRadioStation(RadioStation station) async {
    _stations.add(station);
    await _saveStations();
    await _rebuildAudioSource();
    selectStation(_stations.length - 1);
    notifyListeners();
  }

  Future<void> updateRadioStationName(int index, String name) async {
    if (index >= 0 && index < _stations.length) {
      _stations[index].name = name;
      await _saveStations();
      notifyListeners();
    }
  }

  Future<void> deleteRadioStation(int index) async {
    if (index >= 0 && index < _stations.length) {
      final wasPlaying = _isPlaying;
      final deletedCurrent = index == _selectedIndex;

      _stations.removeAt(index);
      
      if (_stations.isEmpty) {
        await _audioPlayer.stop();
        _selectedIndex = 0;
      } else {
        if (index < _selectedIndex) {
          _selectedIndex--;
        } else if (index == _selectedIndex) {
           _selectedIndex = _selectedIndex % _stations.length;
        }

        await _rebuildAudioSource();
        if (deletedCurrent && wasPlaying) {
            playAtIndex(_selectedIndex); 
        }
      }
      await _saveStations();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
