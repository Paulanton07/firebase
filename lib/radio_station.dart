import 'package:cloud_firestore/cloud_firestore.dart';

class RadioStation {
  String? id;
  String name;
  final String streamUrl;
  final String imageUrl;

  RadioStation({
    this.id,
    required this.name,
    required this.streamUrl,
    required this.imageUrl,
  });

  factory RadioStation.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return RadioStation(
      id: doc.id,
      name: data['name'] ?? '',
      streamUrl: data['streamUrl'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'streamUrl': streamUrl,
      'imageUrl': imageUrl,
    };
  }

  factory RadioStation.fromJson(Map<String, dynamic> json) {
    return RadioStation(
      id: json['id'],
      name: json['name'],
      streamUrl: json['streamUrl'],
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'streamUrl': streamUrl,
      'imageUrl': imageUrl,
    };
  }
}
