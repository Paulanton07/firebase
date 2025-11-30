
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'radio_station.dart';

class RadioProvider with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<RadioStation> _stations = [];
  int _currentStationIndex = 0;
  bool _isPlaying = false;
  double _volume = 1.0;

  List<RadioStation> get stations => _stations;
  int get currentStationIndex => _currentStationIndex;
  bool get isPlaying => _isPlaying;
  double get volume => _volume;

  set currentStationIndex(int index) {
    _currentStationIndex = index;
    play();
    notifyListeners();
  }

  RadioProvider() {
    init();
  }

  Future<void> init() async {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      _loadStations(user);
    });
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.playing) {
        _isPlaying = true;
      } else {
        _isPlaying = false;
      }
      notifyListeners();
    });
  }

  Future<void> _loadStations(User? user) async {
    if (user != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('stations')
          .get();
      _stations = snapshot.docs.map((doc) => RadioStation.fromFirestore(doc)).toList();
    } else {
      final prefs = await SharedPreferences.getInstance();
      final stationsJson = prefs.getStringList('stations') ?? [];
      _stations = stationsJson.map((json) => RadioStation.fromJson(jsonDecode(json))).toList();
    }
    notifyListeners();
  }

  Future<void> _saveStations() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final batch = FirebaseFirestore.instance.batch();
      final stationCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('stations');
      
      // Delete all existing stations for the user
      final snapshot = await stationCollection.get();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Add all current stations
      for (var station in _stations) {
        final docRef = stationCollection.doc(station.id);
        batch.set(docRef, station.toFirestore());
      }
      await batch.commit();
    } else {
      final prefs = await SharedPreferences.getInstance();
      final stationsJson = _stations.map((station) => jsonEncode(station.toJson())).toList();
      await prefs.setStringList('stations', stationsJson);
    }
  }

  Future<void> addStation(RadioStation station) async {
    _stations.add(station);
    await _saveStations();
    notifyListeners();
  }

  Future<void> removeStation(RadioStation station) async {
    if (_isPlaying && _stations[_currentStationIndex] == station) {
      await _audioPlayer.stop();
    }
    _stations.remove(station);
    await _saveStations();
    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await play();
    }
  }

  Future<void> play() async {
    if (_stations.isNotEmpty) {
      final station = _stations[_currentStationIndex];
      await _audioPlayer.play(UrlSource(station.streamUrl));
    }
  }

  Future<void> setVolume(double newVolume) async {
    _volume = newVolume;
    await _audioPlayer.setVolume(_volume);
    notifyListeners();
  }
}
