import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/main.dart';
import 'package:myapp/radio_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';

// This is the recommended way to mock Firebase for tests.
// It uses a mock handler for the Firebase core channel.
void setupFirebaseCoreMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Create a mock handler for the MethodChannel
  Future<Object?> handler(MethodCall call) async {
    if (call.method == 'Firebase#initializeApp') {
      return {
        'name': call.arguments['appName'],
        'options': call.arguments['options'],
        'pluginConstants': {},
      };
    }
    if (call.method == 'Firebase#initializeCore') {
      return [
        {
          'name': defaultFirebaseAppName,
          'options': {
            'apiKey': '123',
            'appId': '123',
            'messagingSenderId': '123',
            'projectId': '123',
          },
          'pluginConstants': {},
        }
      ];
    }
    return null;
  }

  // Set the mock handler on the channel
  const MethodChannel('plugins.flutter.io/firebase_core')
      .setMockMethodCallHandler(handler);
}

void main() {
  setupFirebaseCoreMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
  });

  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    final radioProvider = RadioProvider();
    await radioProvider.init();
    await tester.pumpWidget(MyApp(radioProvider: radioProvider));

    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
