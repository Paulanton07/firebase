import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_voice_messenger/auth_service.dart';
import 'package:flutter_voice_messenger/firebase_options.dart';
import 'package:flutter_voice_messenger/voice_messaging_page.dart';
import 'package:flutter_voice_messenger/radio_page.dart';
import 'package:flutter_voice_messenger/services/audio_service.dart';
import 'package:flutter_voice_messenger/services/just_audio_service.dart';
import 'package:flutter_voice_messenger/providers/audio_view_model.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        StreamProvider<User?>(
          create: (context) => context.read<AuthService>().user,
          initialData: null,
        ),
        Provider<AudioService>(
          create: (_) => JustAudioService(),
        ),
        ChangeNotifierProvider<AudioViewModel>(
          create: (context) => AudioViewModel(context.read<AudioService>()),
        ),
      ],
      child: MaterialApp(
        title: 'Flutter Voice Messenger',
        theme: ThemeData(
          primarySwatch: Colors.deepPurple,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          textTheme: GoogleFonts.poppinsTextTheme(
            Theme.of(context).textTheme,
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Call signInAnonymously only once when the widget is initialized
    context.read<AuthService>().signInAnonymously();
  }

  @override
  Widget build(BuildContext context) {
    final firebaseUser = context.watch<User?>();

    if (firebaseUser != null) {
      return const MyHomePage();
    } else {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    VoiceMessagingPage(),
    RadioPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: SalomonBottomBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: [
          /// Voice Messages
          SalomonBottomBarItem(
            icon: const Icon(Icons.mic),
            title: const Text("Voice Messages"),
            selectedColor: Colors.purple,
          ),

          /// Radio
          SalomonBottomBarItem(
            icon: const Icon(Icons.radio),
            title: const Text("Radio"),
            selectedColor: Colors.pink,
          ),
        ],
      ),
    );
  }
}
