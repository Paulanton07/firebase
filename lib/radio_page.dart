import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_voice_messenger/providers/audio_view_model.dart';

// Model for a radio station
class RadioStation {
  final String name;
  final String streamUrl;
  final String imageUrl;

  RadioStation({
    required this.name,
    required this.streamUrl,
    required this.imageUrl,
  });
}

class RadioPage extends StatelessWidget {
  const RadioPage({super.key});

  // Example list of radio stations
  static final List<RadioStation> _radioStations = [
    RadioStation(
      name: 'Studio Brussel',
      streamUrl: 'https://icecast.vrt.be/stubru-high.mp3',
      imageUrl: 'https://picsum.photos/seed/stubru/400/400',
    ),
    RadioStation(
      name: 'BBC Radio 1',
      streamUrl: 'http://stream.live.vc.bbcmedia.co.uk/bbc_radio_one',
      imageUrl: 'https://picsum.photos/seed/bbc1/400/400',
    ),
    RadioStation(
      name: 'KEXP',
      streamUrl: 'https://kexp-mp3-128.streamguys1.com/kexp128.mp3',
      imageUrl: 'https://picsum.photos/seed/kexp/400/400',
    ),
    RadioStation(
      name: 'NTS Radio',
      streamUrl: 'http://stream-relay-geo.ntslive.net/stream',
      imageUrl: 'https://picsum.photos/seed/nts/400/400',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final audioViewModel = Provider.of<AudioViewModel>(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface.withAlpha((255 * 0.95).round()),
      appBar: AppBar(
        title: const Text('Live Radio'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.textTheme.bodyLarge?.color,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12.0),
        itemCount: _radioStations.length,
        itemBuilder: (context, index) {
          final station = _radioStations[index];
          final bool isCurrentlyPlaying = audioViewModel.isPlaying &&
              audioViewModel.isRadioMode &&
              audioViewModel.currentUrl == station.streamUrl;

          return Card(
            elevation: 5.0,
            margin: const EdgeInsets.symmetric(vertical: 10.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(20.0),
              onTap: () {
                if (isCurrentlyPlaying) {
                  audioViewModel.pause();
                } else {
                  audioViewModel.play(station.streamUrl, isRadio: true);
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15.0),
                      child: Image.network(
                        station.imageUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.radio, size: 80),
                      ),
                    ),
                    const SizedBox(width: 15.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            station.name,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5.0),
                          Text(
                            isCurrentlyPlaying ? 'Now Playing...' : 'Tap to listen',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isCurrentlyPlaying ? theme.primaryColor : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 15.0),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCurrentlyPlaying ? theme.primaryColor.withAlpha((255 * 0.1).round()) : Colors.grey.shade200,
                        boxShadow: isCurrentlyPlaying
                            ? [
                                BoxShadow(
                                  color: theme.primaryColor.withAlpha((255 * 0.4).round()),
                                  spreadRadius: 2,
                                  blurRadius: 8,
                                ),
                              ]
                            : [],
                      ),
                      child: Icon(
                        isCurrentlyPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        size: 45.0,
                        color: isCurrentlyPlaying ? theme.primaryColor : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
