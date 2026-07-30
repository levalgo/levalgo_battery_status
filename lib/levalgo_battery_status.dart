import 'levalgo_battery_status_platform_interface.dart';
import 'src/battery_state.dart';

export 'src/battery_state.dart';

/// Reads the device's battery level and charging state.
///
/// Example:
///
/// ```dart
/// final battery = LevalgoBatteryStatus();
///
/// final level = await battery.getBatteryLevel();
/// print('Battery at $level%');
///
/// final subscription = battery.onStateChanged.listen((state) {
///   print('New state: $state');
/// });
///
/// // When you are done, so the native side releases its observer.
/// await subscription.cancel();
/// ```
class LevalgoBatteryStatus {
  /// The current battery level, as an integer from 0 to 100.
  ///
  /// Throws a [PlatformException] with code `UNAVAILABLE` when the system
  /// cannot report the level. On iOS that is always the case on the simulator,
  /// which reports -1 instead of a real reading.
  Future<int> getBatteryLevel() {
    return LevalgoBatteryStatusPlatform.instance.getBatteryLevel();
  }

  /// The current charging state.
  ///
  /// Returns [BatteryState.unknown] rather than throwing when the system
  /// cannot determine it: unlike the level, "we don't know" is a legitimate
  /// state and is already represented in the enum.
  Future<BatteryState> getBatteryState() {
    return LevalgoBatteryStatusPlatform.instance.getBatteryState();
  }

  /// Emits whenever the charging state changes.
  ///
  /// The first event arrives on the first change, not on subscription. Call
  /// [getBatteryState] to read the initial state.
  ///
  /// Cancelling the subscription is what makes the native side remove its
  /// system observer, so cancel it once you stop using it.
  Stream<BatteryState> get onStateChanged {
    return LevalgoBatteryStatusPlatform.instance.onStateChanged;
  }
}
