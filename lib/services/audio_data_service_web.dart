import 'dart:typed_data';
import 'package:http/http.dart' as http;

class AudioDataService {
  Future<Uint8List> getAudioData(String path) async {
    final response = await http.get(Uri.parse(path));
    return response.bodyBytes;
  }
}
