import 'package:flutter_test/flutter_test.dart';
import 'package:levalgo_battery_status/levalgo_battery_status.dart';
import 'package:levalgo_battery_status/levalgo_battery_status_platform_interface.dart';
import 'package:levalgo_battery_status/levalgo_battery_status_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockLevalgoBatteryStatusPlatform
    with MockPlatformInterfaceMixin
    implements LevalgoBatteryStatusPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final LevalgoBatteryStatusPlatform initialPlatform = LevalgoBatteryStatusPlatform.instance;

  test('$MethodChannelLevalgoBatteryStatus is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelLevalgoBatteryStatus>());
  });

  test('getPlatformVersion', () async {
    LevalgoBatteryStatus levalgoBatteryStatusPlugin = LevalgoBatteryStatus();
    MockLevalgoBatteryStatusPlatform fakePlatform = MockLevalgoBatteryStatusPlatform();
    LevalgoBatteryStatusPlatform.instance = fakePlatform;

    expect(await levalgoBatteryStatusPlugin.getPlatformVersion(), '42');
  });
}
