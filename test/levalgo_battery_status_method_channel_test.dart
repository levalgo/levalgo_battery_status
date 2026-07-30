import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:levalgo_battery_status/levalgo_battery_status.dart';
import 'package:levalgo_battery_status/levalgo_battery_status_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final TestDefaultBinaryMessenger messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late MethodChannelLevalgoBatteryStatus platform;
  late List<MethodCall> calls;

  setUp(() {
    platform = MethodChannelLevalgoBatteryStatus();
    calls = <MethodCall>[];
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(platform.methodChannel, null);
  });

  /// Installs a fixed reply for the method channel and records the calls it
  /// receives, so tests can also assert on the method name.
  void replyWith(Object? reply) {
    messenger.setMockMethodCallHandler(platform.methodChannel, (
      MethodCall call,
    ) async {
      calls.add(call);
      return reply;
    });
  }

  group('getBatteryLevel', () {
    test('returns the integer sent by the platform', () async {
      replyWith(87);

      expect(await platform.getBatteryLevel(), 87);
      expect(calls.single.method, 'getBatteryLevel');
    });

    test('throws UNAVAILABLE when the platform returns nothing', () {
      replyWith(null);

      expect(
        platform.getBatteryLevel(),
        throwsA(
          isA<PlatformException>().having((e) => e.code, 'code', 'UNAVAILABLE'),
        ),
      );
    });
  });

  group('getBatteryState', () {
    const cases = <String, BatteryState>{
      'full': BatteryState.full,
      'charging': BatteryState.charging,
      'discharging': BatteryState.discharging,
      'unknown': BatteryState.unknown,
    };

    for (final entry in cases.entries) {
      test('translates "${entry.key}" to ${entry.value}', () async {
        replyWith(entry.key);

        expect(await platform.getBatteryState(), entry.value);
        expect(calls.single.method, 'getBatteryState');
      });
    }

    test('an unrecognised identifier falls back to unknown', () async {
      replyWith('a_state_from_a_future_version');

      expect(await platform.getBatteryState(), BatteryState.unknown);
    });
  });

  group('onStateChanged', () {
    // The event channel is intercepted by declaring a MethodChannel with the
    // same name: underneath, both speak the same codec over the same binary
    // messenger.
    late MethodChannel eventChannel;

    setUp(() {
      eventChannel = MethodChannel(platform.eventChannel.name);
      messenger.setMockMethodCallHandler(eventChannel, (call) async {
        calls.add(call);
        return null;
      });
    });

    tearDown(() {
      messenger.setMockMethodCallHandler(eventChannel, null);
    });

    /// Pushes an event over the channel as if the native layer sent it.
    Future<void> emit(String state) {
      return messenger.handlePlatformMessage(
        eventChannel.name,
        const StandardMethodCodec().encodeSuccessEnvelope(state),
        (_) {},
      );
    }

    test('translates native events into BatteryState', () async {
      final received = <BatteryState>[];
      final subscription = platform.onStateChanged.listen(received.add);
      await pumpEventQueue();

      await emit('charging');
      await emit('full');
      await pumpEventQueue();

      expect(received, [BatteryState.charging, BatteryState.full]);
      await subscription.cancel();
    });

    test('subscribes to the native channel with listen', () async {
      final subscription = platform.onStateChanged.listen((_) {});
      await pumpEventQueue();

      expect(calls.single.method, 'listen');
      await subscription.cancel();
    });

    test('reuses the same stream across calls', () {
      expect(platform.onStateChanged, same(platform.onStateChanged));
    });
  });
}
