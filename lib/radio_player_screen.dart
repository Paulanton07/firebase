
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'radio_provider.dart';
import 'radio_station.dart';

class RadioPlayerScreen extends StatelessWidget {
  const RadioPlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final radioProvider = Provider.of<RadioProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Radio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddStationDialog(context, radioProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          if (radioProvider.stations.isNotEmpty)
            CarouselSlider.builder(
              itemCount: radioProvider.stations.length,
              itemBuilder: (context, index, realIndex) {
                final station = radioProvider.stations[index];
                return RadioCard(station: station);
              },
              options: CarouselOptions(
                height: 400,
                enlargeCenterPage: true,
                onPageChanged: (index, reason) {
                  radioProvider.currentStationIndex = index;
                },
              ),
            )
          else
            const Center(
              child: Text('No stations available. Add one to get started.'),
            ),
          const SizedBox(height: 20),
          if (radioProvider.stations.isNotEmpty)
            const PlayerControls(),
        ],
      ),
    );
  }

  void _showAddStationDialog(BuildContext context, RadioProvider radioProvider) {
    final nameController = TextEditingController();
    final urlController = TextEditingController();
    final imageUrlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Radio Station'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Station Name'),
              ),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(labelText: 'Stream URL'),
              ),
              TextField(
                controller: imageUrlController,
                decoration: const InputDecoration(labelText: 'Image URL'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text;
                final url = urlController.text;
                final imageUrl = imageUrlController.text;
                if (name.isNotEmpty && url.isNotEmpty) {
                  radioProvider.addStation(RadioStation(
                    name: name,
                    streamUrl: url,
                    imageUrl: imageUrl,
                  ));
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}

class RadioCard extends StatelessWidget {
  final RadioStation station;

  const RadioCard({super.key, required this.station});

  @override
  Widget build(BuildContext context) {
    final radioProvider = Provider.of<RadioProvider>(context, listen: false);
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                station.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.radio, size: 100, color: Colors.grey),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(station.name, style: Theme.of(context).textTheme.titleLarge),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              radioProvider.removeStation(station);
            },
          ),
        ],
      ),
    );
  }
}

class PlayerControls extends StatelessWidget {
  const PlayerControls({super.key});

  @override
  Widget build(BuildContext context) {
    final radioProvider = Provider.of<RadioProvider>(context);

    return Column(
      children: [
        IconButton(
          icon: Icon(
            radioProvider.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
            size: 64,
            color: Theme.of(context).primaryColor,
          ),
          onPressed: () {
            radioProvider.togglePlayPause();
          },
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.volume_down),
            Slider(
              value: radioProvider.volume,
              onChanged: (newVolume) {
                radioProvider.setVolume(newVolume);
              },
              min: 0.0,
              max: 1.0,
            ),
            const Icon(Icons.volume_up),
          ],
        ),
      ],
    );
  }
}
