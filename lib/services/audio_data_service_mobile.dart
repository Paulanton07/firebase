import 'dart:io';
import 'dart:typed_data';

class AudioDataService {
  Future<Uint8List> getAudioData(String path) async {
    final file = File(path);
    return await file.readAsBytes();
  }
}
