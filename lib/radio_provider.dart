
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    FirebaseAuth.instance.authStateChanges().listen((user) {
      _loadStations();
    });
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
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('stations')
            .get();

        if (snapshot.docs.isNotEmpty) {
          _stations = snapshot.docs
              .map((doc) => RadioStation.fromJson(doc.data(), id: doc.id))
              .toList();
        } else {
          _stations = [
            RadioStation(name: 'BBC Radio 1', url: 'https://stream.live.vc.bbcmedia.co.uk/bbc_radio_one')
          ];
        }
      } catch (e) {
        developer.log('Error loading stations from Firestore', error: e);
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      final stationStrings = prefs.getStringList(_stationsKey);
      if (stationStrings != null && stationStrings.isNotEmpty) {
        try {
          _stations = stationStrings
              .map((s) => RadioStation.fromJson(jsonDecode(s)))
              .toList();
        } catch (e) {
          _stations = [
            RadioStation(name: 'BBC Radio 1', url: 'https://stream.live.vc.bbcmedia.co.uk/bbc_radio_one')
          ];
        }
      } else {
        _stations = [
          RadioStation(name: 'BBC Radio 1', url: 'https://stream.live.vc.bbcmedia.co.uk/bbc_radio_one')
        ];
      }
    }
    notifyListeners();
    _rebuildAudioSource();
  }

  Future<void> _saveStations() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      final prefs = await SharedPreferences.getInstance();
      final stationStrings =
          _stations.map((s) => jsonEncode(s.toJson())).toList();
      await prefs.setStringList(_stationsKey, stationStrings);
    }
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
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final docRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('stations')
          .add(station.toJson());
      station.id = docRef.id;
    }
    _stations.add(station);
    await _saveStations();
    await _rebuildAudioSource();
    selectStation(_stations.length - 1);
    notifyListeners();
  }

  Future<void> updateRadioStationName(int index, String name) async {
    if (index >= 0 && index < _stations.length) {
      _stations[index].name = name;
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && _stations[index].id != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('stations')
            .doc(_stations[index].id)
            .update({'name': name});
      }
      await _saveStations();
      notifyListeners();
    }
  }

  Future<void> deleteRadioStation(int index) async {
    if (index >= 0 && index < _stations.length) {
      final wasPlaying = _isPlaying;
      final deletedCurrent = index == _selectedIndex;
      final station = _stations[index];

      final user = FirebaseAuth.instance.currentUser;
      if (user != null && station.id != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('stations')
            .doc(station.id)
            .delete();
      }

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
