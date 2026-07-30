// Integration test: runs inside a full Flutter app, so it crosses the
// channels and actually executes the plugin's native code.
//
// Requires a physical device. On the iOS simulator the battery level is not
// available and getBatteryLevel throws UNAVAILABLE by design.
//
// To run it:
//   cd example && flutter test integration_test
//
// See https://flutter.dev/to/integration-testing

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:levalgo_battery_status/levalgo_battery_status.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final LevalgoBatteryStatus battery = LevalgoBatteryStatus();

  testWidgets('getBatteryLevel returns a percentage between 0 and 100', (
    WidgetTester tester,
  ) async {
    final level = await battery.getBatteryLevel();

    expect(level, inInclusiveRange(0, 100));
  });

  testWidgets('getBatteryState returns a known state', (
    WidgetTester tester,
  ) async {
    final state = await battery.getBatteryState();

    // On a real device monitoring is on, so the system always knows whether
    // it is charging or discharging.
    expect(state, isNot(BatteryState.unknown));
  });

  testWidgets('onStateChanged can be subscribed to and cancelled', (
    WidgetTester tester,
  ) async {
    final subscription = battery.onStateChanged.listen((_) {});
    await Future<void>.delayed(const Duration(milliseconds: 200));

    // A state change cannot be forced from a test (it would mean plugging in
    // a cable), so what this checks is that the full subscribe/unsubscribe
    // cycle of the native observer does not break anything.
    await expectLater(subscription.cancel(), completes);
  });
}
