import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;

Future<void> uploadFile(Reference ref, String path) async {
  final response = await http.get(Uri.parse(path));
  await ref.putData(response.bodyBytes);
}
