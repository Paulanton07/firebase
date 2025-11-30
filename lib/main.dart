import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'radio_player_screen.dart';
import 'radio_provider.dart';
import 'auth_service.dart';
import 'login_screen.dart';
import 'voice_messaging_page.dart';

// Development flag to bypass login
const bool devMode = true;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // We need to initialize Firebase first
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // We are no longer awaiting the radioProvider.init() here.
  // It will be handled by the AppInitializer widget.
  runApp(MyApp(radioProvider: RadioProvider()));
}

enum AppTheme { deepPurple, vibrantGreen, neonBlue }

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  AppTheme _appTheme = AppTheme.deepPurple;

  ThemeMode get themeMode => _themeMode;
  AppTheme get appTheme => _appTheme;

  void setTheme(AppTheme theme) {
    _appTheme = theme;
    notifyListeners();
  }

  void toggleThemeMode() {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  final RadioProvider radioProvider;
  const MyApp({super.key, required this.radioProvider});

  @override
  Widget build(BuildContext context) {
    // The MultiProvider now wraps the entire app structure.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        // The RadioProvider is now created here and available to the whole app
        ChangeNotifierProvider.value(value: radioProvider),
      ],
      child: const AppContent(),
    );
  }
}

class AppContent extends StatelessWidget {
  const AppContent({super.key});

  ThemeData _buildTheme(ColorScheme colorScheme, TextTheme appTextTheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: appTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        titleTextStyle:
            GoogleFonts.oswald(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
    );
  }

  ThemeData _buildNeonTheme(ColorScheme colorScheme, TextTheme appTextTheme) {
    final neonColor = colorScheme.primary;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.black,
      colorScheme: colorScheme.copyWith(
          brightness: Brightness.dark, surface: Colors.black),
      textTheme:
          appTextTheme.apply(bodyColor: neonColor, displayColor: neonColor),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: neonColor,
        elevation: 0,
        titleTextStyle: GoogleFonts.oswald(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: neonColor, blurRadius: 10)]),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      textSelectionTheme: TextSelectionThemeData(cursorColor: neonColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    final TextTheme appTextTheme = TextTheme(
      displayLarge:
          GoogleFonts.oswald(fontSize: 57, fontWeight: FontWeight.bold),
      titleLarge: GoogleFonts.roboto(fontSize: 22, fontWeight: FontWeight.w500),
      headlineMedium:
          GoogleFonts.oswald(fontSize: 34, fontWeight: FontWeight.w600),
      bodyMedium: GoogleFonts.openSans(fontSize: 14),
    );

    final Map<AppTheme, ThemeData> themes = {
      AppTheme.deepPurple: _buildTheme(
          ColorScheme.fromSeed(seedColor: Colors.deepPurple), appTextTheme),
      AppTheme.vibrantGreen: _buildTheme(
          ColorScheme.fromSeed(seedColor: Colors.green), appTextTheme),
      AppTheme.neonBlue: _buildNeonTheme(
          ColorScheme.fromSeed(
              seedColor: Colors.cyanAccent, brightness: Brightness.dark),
          appTextTheme),
    };

    return MaterialApp(
      title: 'Flutter Radio App',
      theme: themes[themeProvider.appTheme],
      darkTheme: themes[themeProvider.appTheme],
      themeMode: themeProvider.themeMode,
      debugShowCheckedModeBanner: false,
      // The home is now our new initializer widget
      home: const AppInitializer(),
    );
  }
}

// This is the new widget that handles async initialization
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Get the provider and call init
    final radioProvider = Provider.of<RadioProvider>(context, listen: false);
    await radioProvider.init();

    // After init, navigate to the correct screen.
    // Using `mounted` check is a good practice.
    if (mounted) {
       // Based on devMode, decide where to go.
      Widget nextScreen = devMode
          ? const MainScreen()
          : StreamBuilder<User?>(
              stream: AuthService().authStateChanges,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                      body: Center(child: CircularProgressIndicator()));
                }
                return snapshot.hasData ? const MainScreen() : const LoginScreen();
              },
            );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => nextScreen),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // While initializing, show a loading spinner
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  static const List<Widget> _widgetOptions = <Widget>[
    RadioPlayerScreen(),
    VoiceMessagingPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
          child: _widgetOptions.elementAt(_selectedIndex),
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.radio),
              label: 'Radio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.mic),
              label: 'Messages',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      );
  }
}

