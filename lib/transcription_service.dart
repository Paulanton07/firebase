
import 'dart:io';
import 'package:firebase_ai/firebase_ai.dart' as fb_ai;
import 'package:mime/mime.dart';

Future<String> transcribeAudio(String audioPath) async {
  final file = File(audioPath);
  final audioBytes = await file.readAsBytes();
  final mimeType = lookupMimeType(file.path);

  if (mimeType == null) {
    throw Exception('Could not determine MIME type of the audio file.');
  }

  final model = fb_ai.FirebaseVertexAI.instance.generativeModel(model: 'gemini-1.5-flash');

  final content = fb_ai.Content.multi([
    const fb_ai.TextPart("Transcribe the following audio:"),
    fb_ai.DataPart(mimeType, audioBytes),
  ]);

  final response = await model.generateContent([content]);
  return response.text ?? 'No response from model.';
}
