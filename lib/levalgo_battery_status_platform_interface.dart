import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'levalgo_battery_status_method_channel.dart';

abstract class LevalgoBatteryStatusPlatform extends PlatformInterface {
  /// Constructs a LevalgoBatteryStatusPlatform.
  LevalgoBatteryStatusPlatform() : super(token: _token);

  static final Object _token = Object();

  static LevalgoBatteryStatusPlatform _instance = MethodChannelLevalgoBatteryStatus();

  /// The default instance of [LevalgoBatteryStatusPlatform] to use.
  ///
  /// Defaults to [MethodChannelLevalgoBatteryStatus].
  static LevalgoBatteryStatusPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [LevalgoBatteryStatusPlatform] when
  /// they register themselves.
  static set instance(LevalgoBatteryStatusPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
