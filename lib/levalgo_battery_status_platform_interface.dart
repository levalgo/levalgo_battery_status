import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'levalgo_battery_status_method_channel.dart';
import 'src/battery_state.dart';

/// The contract every platform implementation of this plugin must satisfy.
///
/// The public [LevalgoBatteryStatus] class forwards every call to [instance].
/// Keeping the contract separate from the implementation lets tests swap the
/// native layer for a fake one without touching the channels.
abstract class LevalgoBatteryStatusPlatform extends PlatformInterface {
  /// Constructs a [LevalgoBatteryStatusPlatform].
  LevalgoBatteryStatusPlatform() : super(token: _token);

  static final Object _token = Object();

  static LevalgoBatteryStatusPlatform _instance =
      MethodChannelLevalgoBatteryStatus();

  /// The active platform implementation.
  ///
  /// Defaults to [MethodChannelLevalgoBatteryStatus].
  static LevalgoBatteryStatusPlatform get instance => _instance;

  /// Registers a platform implementation other than the default one.
  ///
  /// [PlatformInterface.verifyToken] rejects any subclass that skips this
  /// class's constructor, which stops an external package from impersonating
  /// the official implementation.
  static set instance(LevalgoBatteryStatusPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// The current battery level, from 0 to 100.
  Future<int> getBatteryLevel() {
    throw UnimplementedError('getBatteryLevel() has not been implemented.');
  }

  /// The current charging state.
  Future<BatteryState> getBatteryState() {
    throw UnimplementedError('getBatteryState() has not been implemented.');
  }

  /// A stream of charging state changes.
  Stream<BatteryState> get onStateChanged {
    throw UnimplementedError('onStateChanged has not been implemented.');
  }
}
