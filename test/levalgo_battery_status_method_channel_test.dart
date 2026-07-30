import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:levalgo_battery_status/levalgo_battery_status_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelLevalgoBatteryStatus platform = MethodChannelLevalgoBatteryStatus();
  const MethodChannel channel = MethodChannel('levalgo_battery_status');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
