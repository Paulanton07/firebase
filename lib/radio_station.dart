class RadioStation {
  String name;
  final String url;

  RadioStation({required this.name, required this.url});

  // Method to convert a RadioStation instance to a map
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'url': url,
    };
  }

  // Factory constructor to create a RadioStation instance from a map
  factory RadioStation.fromJson(Map<String, dynamic> json) {
    return RadioStation(
      name: json['name'],
      url: json['url'],
    );
  }
}
