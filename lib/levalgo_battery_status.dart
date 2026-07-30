
import 'levalgo_battery_status_platform_interface.dart';

class LevalgoBatteryStatus {
  Future<String?> getPlatformVersion() {
    return LevalgoBatteryStatusPlatform.instance.getPlatformVersion();
  }
}
