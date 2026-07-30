#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

/// iOS implementation of the levalgo_battery_status plugin.
///
/// A single instance serves both channels declared by the Dart layer:
///
///  - a `FlutterMethodChannel` for one-off queries (`getBatteryLevel` and
///    `getBatteryState`), hence `FlutterPlugin`;
///  - a `FlutterEventChannel` for the stream of state changes, hence
///    `FlutterStreamHandler`.
///
/// Every device reading goes through `UIDevice`, which requires battery
/// monitoring to be switched on before it returns real data.
///
/// The header only declares the class. It exposes nothing else because nobody
/// outside the plugin needs to construct it: `registerWithRegistrar:` does
/// that, and Flutter calls it from the generated registrant.
@interface LevalgoBatteryStatusPlugin
    : NSObject <FlutterPlugin, FlutterStreamHandler>
@end

NS_ASSUME_NONNULL_END
