import 'package:record/record.dart';

class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();

  Future<void> init() async {
    // No specific initialization is needed for the mobile version of the service,
    // but we're keeping this method for consistency with the web implementation.
  }

  Future<void> startRecording({String? path}) async {
    if (path == null) {
      throw ArgumentError.notNull('path');
    }
    await _recorder.start(const RecordConfig(), path: path);
  }

  Future<String?> stopRecording() async {
    return await _recorder.stop();
  }

  void dispose() {
    _recorder.dispose();
  }
}
