abstract class AudioService {
  Stream<bool> get onPlayerStateChanged;
  Future<void> play(String url);
  Future<void> pause();
  Future<void> stop();
  Future<void> record();
  Future<String?> stopRecording();
  void dispose();
}
