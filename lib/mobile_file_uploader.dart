import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

Future<void> uploadFile(Reference ref, String path) async {
  final file = File(path);
  if (await file.exists()) {
    await ref.putFile(file);
  }
}
