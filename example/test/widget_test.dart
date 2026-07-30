// Widget test for the example app.
//
// There is no native layer inside a widget test, so both channels are
// intercepted with fixed replies. What this checks is that the app renders
// what the platform reports, not that the platform works.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:levalgo_battery_status_example/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final TestDefaultBinaryMessenger messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  const MethodChannel methodChannel = MethodChannel('levalgo_battery_status');
  const MethodChannel eventChannel = MethodChannel(
    'levalgo_battery_status/state',
  );

  void installFakePlatform({required Object? level, required String state}) {
    messenger.setMockMethodCallHandler(methodChannel, (call) async {
      return switch (call.method) {
        'getBatteryLevel' => level,
        'getBatteryState' => state,
        _ => null,
      };
    });
    // The EventChannel answers listen and cancel over the same mechanism.
    messenger.setMockMethodCallHandler(eventChannel, (_) async => null);
  }

  tearDown(() {
    messenger.setMockMethodCallHandler(methodChannel, null);
    messenger.setMockMethodCallHandler(eventChannel, null);
  });

  testWidgets('shows the level and state reported by the platform', (
    WidgetTester tester,
  ) async {
    installFakePlatform(level: 76, state: 'charging');

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('76%'), findsOneWidget);
    expect(find.text('Charging'), findsOneWidget);
  });

  testWidgets('explains the simulator case when there is no level', (
    WidgetTester tester,
  ) async {
    installFakePlatform(level: null, state: 'unknown');

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('--'), findsOneWidget);
    expect(find.textContaining('physical device'), findsOneWidget);
  });
}
