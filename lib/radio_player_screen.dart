
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'radio_provider.dart';
import 'radio_station.dart';
import 'auth_service.dart';

class RadioPlayerScreen extends StatefulWidget {
  const RadioPlayerScreen({super.key});

  @override
  State<RadioPlayerScreen> createState() => _RadioPlayerScreenState();
}

class _RadioPlayerScreenState extends State<RadioPlayerScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    final radioProvider = Provider.of<RadioProvider>(context, listen: false);
    _pageController = PageController(
      viewportFraction: 0.7,
      initialPage: radioProvider.selectedIndex,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radioProvider = Provider.of<RadioProvider>(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Radio'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => AuthService().signOut(),
          ),
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'Manage Stations',
            onPressed: () => _showStationsList(context, radioProvider),
          ),
        ],
      ),
      body: radioProvider.stations.isEmpty
          ? _buildEmptyState(context)
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  flex: 3,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        iconSize: 30,
                        onPressed: () {
                          _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                        },
                      ),
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: radioProvider.stations.length,
                          onPageChanged: (index) {
                            radioProvider.selectStation(index);
                          },
                          itemBuilder: (context, index) {
                            final station = radioProvider.stations[index];
                            final isSelected = radioProvider.selectedIndex == index;
                            return AnimatedScale(
                              scale: isSelected ? 1.0 : 0.8,
                              duration: const Duration(milliseconds: 300),
                              child: Center(
                                child: Text(
                                  station.name,
                                  style: textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? colorScheme.primary
                                        : colorScheme.onSurface.withAlpha(150),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios_rounded),
                        iconSize: 30,
                        onPressed: () {
                           _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: _buildCentralPlayButton(radioProvider, colorScheme),
                ),
                 const Spacer(flex: 1),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add Radio Station',
        onPressed: () => _showAddStationDialog(context, radioProvider),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCentralPlayButton(RadioProvider radioProvider, ColorScheme colorScheme) {
    final isSelectedStationPlaying = radioProvider.isPlaying && radioProvider.selectedIndex == radioProvider.playingIndex;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            if (isSelectedStationPlaying) {
              radioProvider.pause();
            } else {
              radioProvider.play();
            }
          },
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: colorScheme.primary.withAlpha(30),
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.primary, width: 4),
            ),
            child: Center(
              child: Icon(
                  isSelectedStationPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 80,
                  color: colorScheme.primary,
                ),
            ),
          ),
        ),
      ],
    );
  }

   Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.radio, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          Text(
            'No Stations Added',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          const Text('Tap the + button to add your first radio station.'),
        ],
      ),
    );
  }


  void _showAddStationDialog(BuildContext context, RadioProvider radioProvider) {
    final nameController = TextEditingController();
    final urlController = TextEditingController();
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
                autofocus: true,
              ),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(labelText: 'Station URL'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                if (nameController.text.isNotEmpty && urlController.text.isNotEmpty) {
                  radioProvider.addRadioStation(RadioStation(name: nameController.text, url: urlController.text));
                  Navigator.pop(context);
                   WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_pageController.hasClients) {
                      _pageController.jumpToPage(radioProvider.stations.length - 1);
                    }
                  });
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showEditStationDialog(BuildContext context, RadioProvider radioProvider, int index) {
    final station = radioProvider.stations[index];
    final nameController = TextEditingController(text: station.name);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Station Name'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Station Name'),
            autofocus: true,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  radioProvider.updateRadioStationName(index, nameController.text);
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showStationsList(BuildContext context, RadioProvider radioProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          builder: (BuildContext context, ScrollController scrollController) {
            return Consumer<RadioProvider>(
              builder: (context, radio, child) {
                return Material(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: radio.stations.length,
                    itemBuilder: (context, index) {
                      final station = radio.stations[index];
                      final isSelected = index == radio.selectedIndex;
                      return ListTile(
                        title: Text(station.name),
                        subtitle: Text(station.url, maxLines: 1, overflow: TextOverflow.ellipsis),
                        selected: isSelected,
                        tileColor: isSelected ? Theme.of(context).colorScheme.primary.withAlpha(50) : null,
                        onTap: () {
                          radio.playAtIndex(index);
                          Navigator.pop(context);
                          _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                        },
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: 'Edit Name',
                              onPressed: () => _showEditStationDialog(context, radio, index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              tooltip: 'Delete Station',
                              onPressed: () => radio.deleteRadioStation(index),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
