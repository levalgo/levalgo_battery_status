import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'levalgo_battery_status_platform_interface.dart';

/// An implementation of [LevalgoBatteryStatusPlatform] that uses method channels.
class MethodChannelLevalgoBatteryStatus extends LevalgoBatteryStatusPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('levalgo_battery_status');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
