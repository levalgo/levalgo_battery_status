import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:levalgo_battery_status/levalgo_battery_status.dart';
import 'package:levalgo_battery_status/levalgo_battery_status_method_channel.dart';
import 'package:levalgo_battery_status/levalgo_battery_status_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// A fake platform with fixed values, so the public class can be tested
/// without touching the channels or the native layer.
class FakeLevalgoBatteryStatusPlatform
    with MockPlatformInterfaceMixin
    implements LevalgoBatteryStatusPlatform {
  final StreamController<BatteryState> _controller =
      StreamController<BatteryState>.broadcast();

  @override
  Future<int> getBatteryLevel() async => 42;

  @override
  Future<BatteryState> getBatteryState() async => BatteryState.charging;

  @override
  Stream<BatteryState> get onStateChanged => _controller.stream;

  /// Pushes a state onto the stream as if it came from the system.
  void emit(BatteryState state) => _controller.add(state);

  Future<void> close() => _controller.close();
}

void main() {
  final LevalgoBatteryStatusPlatform initialPlatform =
      LevalgoBatteryStatusPlatform.instance;

  test('the default implementation uses channels', () {
    expect(initialPlatform, isA<MethodChannelLevalgoBatteryStatus>());
  });

  group('with a fake platform', () {
    late LevalgoBatteryStatus battery;
    late FakeLevalgoBatteryStatusPlatform fake;

    setUp(() {
      battery = LevalgoBatteryStatus();
      fake = FakeLevalgoBatteryStatusPlatform();
      LevalgoBatteryStatusPlatform.instance = fake;
    });

    tearDown(() async {
      await fake.close();
      LevalgoBatteryStatusPlatform.instance = initialPlatform;
    });

    test('getBatteryLevel delegates to the platform', () async {
      expect(await battery.getBatteryLevel(), 42);
    });

    test('getBatteryState delegates to the platform', () async {
      expect(await battery.getBatteryState(), BatteryState.charging);
    });

    test('onStateChanged re-emits what the platform publishes', () async {
      final received = <BatteryState>[];
      final subscription = battery.onStateChanged.listen(received.add);

      fake.emit(BatteryState.charging);
      fake.emit(BatteryState.full);
      await pumpEventQueue();

      expect(received, [BatteryState.charging, BatteryState.full]);
      await subscription.cancel();
    });
  });
}
