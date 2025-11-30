import 'dart:async';
import 'package:record/record.dart';

class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();

  Future<void> init() async {
    // No initialization needed for web
  }

  Future<void> startRecording({String? path}) async {
    // The path parameter is ignored on the web, but it's here for consistency.
    await _recorder.start(const RecordConfig(), path: 'myFile.m4a');
  }

  Future<String?> stopRecording() async {
    return await _recorder.stop();
  }

  void dispose() {
    _recorder.dispose();
  }
}
