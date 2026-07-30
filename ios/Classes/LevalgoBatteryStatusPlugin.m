#import "LevalgoBatteryStatusPlugin.h"

#import <UIKit/UIKit.h>
#import <math.h>

#pragma mark - Constants

/// Channel names. These must match, character for character, the ones
/// declared in levalgo_battery_status_method_channel.dart: if they diverge,
/// Dart gets a MissingPluginException and no compiler error warns about it.
static NSString *const kMethodChannelName = @"levalgo_battery_status";
static NSString *const kEventChannelName = @"levalgo_battery_status/state";

/// State identifiers understood by the Dart layer.
///
/// They travel as strings rather than integers so the contract between the
/// two layers reads for itself and does not depend on an enum's ordering.
static NSString *const kStateFull = @"full";
static NSString *const kStateCharging = @"charging";
static NSString *const kStateDischarging = @"discharging";
static NSString *const kStateUnknown = @"unknown";

/// Error code the Dart layer turns into a PlatformException.
static NSString *const kErrorUnavailable = @"UNAVAILABLE";

@implementation LevalgoBatteryStatusPlugin {
  /// Sink used to push events towards Dart.
  ///
  /// It is nil while nobody is subscribed. It is a block, and assigning it to
  /// a strong ivar makes ARC copy it from the stack to the heap, which is
  /// what allows invoking it later from a notification.
  FlutterEventSink _eventSink;

  /// Token returned by NSNotificationCenter when the observer is registered.
  ///
  /// It must be kept: the block-based variant of the API cannot be
  /// unregistered by selector, only by passing this object to
  /// removeObserver:.
  id<NSObject> _batteryStateObserver;
}

#pragma mark - Registration

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  LevalgoBatteryStatusPlugin *instance =
      [[LevalgoBatteryStatusPlugin alloc] init];

  FlutterMethodChannel *methodChannel =
      [FlutterMethodChannel methodChannelWithName:kMethodChannelName
                                  binaryMessenger:[registrar messenger]];
  // The registrar retains the instance, so there is no need to keep it here.
  [registrar addMethodCallDelegate:instance channel:methodChannel];

  FlutterEventChannel *eventChannel =
      [FlutterEventChannel eventChannelWithName:kEventChannelName
                                binaryMessenger:[registrar messenger]];
  [eventChannel setStreamHandler:instance];
}

- (void)dealloc {
  // Safety net in case the instance dies without Dart having cancelled the
  // subscription. Leaving a live observer pointing at a deallocated object is
  // the classic NSNotificationCenter leak.
  [self stopObservingBatteryState];
}

#pragma mark - FlutterPlugin

- (void)handleMethodCall:(FlutterMethodCall *)call
                  result:(FlutterResult)result {
  // The literal goes first on purpose: if call.method were nil, the
  // comparison returns NO instead of blowing up.
  if ([@"getBatteryLevel" isEqualToString:call.method]) {
    [self respondWithBatteryLevel:result];
  } else if ([@"getBatteryState" isEqualToString:call.method]) {
    result([self currentStateIdentifier]);
  } else {
    // Flutter's contract: anything unrecognised is answered with this
    // sentinel, which surfaces on the Dart side as MissingPluginException.
    result(FlutterMethodNotImplemented);
  }
}

#pragma mark - FlutterStreamHandler

- (FlutterError *_Nullable)onListenWithArguments:(id _Nullable)arguments
                                       eventSink:(FlutterEventSink)events {
  _eventSink = events;
  [self startObservingBatteryState];
  // Returning nil means the subscription was accepted.
  return nil;
}

- (FlutterError *_Nullable)onCancelWithArguments:(id _Nullable)arguments {
  [self stopObservingBatteryState];
  // Releasing the block is what frees whatever the block had captured.
  _eventSink = nil;
  return nil;
}

#pragma mark - Device readings

/// Switches battery monitoring on if it was not already.
///
/// Without this, `batteryLevel` returns -1.0 and `batteryState` returns
/// Unknown, which is exactly the symptom seen on the simulator.
///
/// Once on, it stays on for the lifetime of the plugin. Switching it off
/// after each one-off query would be tidier in theory, but in practice a
/// single reading would switch monitoring off underneath an active stream.
- (void)enableBatteryMonitoring {
  UIDevice *device = UIDevice.currentDevice;
  if (!device.batteryMonitoringEnabled) {
    device.batteryMonitoringEnabled = YES;
  }
}

- (void)respondWithBatteryLevel:(FlutterResult)result {
  [self enableBatteryMonitoring];

  // Arrives as a fraction from 0.0 to 1.0, or -1.0 if the system does not
  // know.
  const float level = UIDevice.currentDevice.batteryLevel;

  if (level < 0.0f) {
    result([FlutterError
        errorWithCode:kErrorUnavailable
              message:@"The system does not report a battery level. It is "
                      @"never available on the iOS simulator: try a physical "
                      @"device."
              details:nil]);
    return;
  }

  // Rounding happens here rather than in Dart so the native layer already
  // hands over the 0 to 100 integer the public API promises.
  result(@((int)lroundf(level * 100.0f)));
}

/// Translates `UIDeviceBatteryState` into the identifier Dart expects.
- (NSString *)currentStateIdentifier {
  [self enableBatteryMonitoring];

  switch (UIDevice.currentDevice.batteryState) {
    case UIDeviceBatteryStateFull:
      return kStateFull;
    case UIDeviceBatteryStateCharging:
      return kStateCharging;
    case UIDeviceBatteryStateUnplugged:
      return kStateDischarging;
    case UIDeviceBatteryStateUnknown:
      break;
  }
  return kStateUnknown;
}

#pragma mark - NSNotificationCenter observer

- (void)startObservingBatteryState {
  // Idempotent: if an observer already exists, a second one would emit every
  // change twice.
  if (_batteryStateObserver != nil) {
    return;
  }

  [self enableBatteryMonitoring];

  // self is captured weakly on purpose. The notification center retains the
  // block and the block would retain self: without __weak that is a cycle
  // keeping the plugin alive long after anyone needs it.
  __weak __typeof__(self) weakSelf = self;

  // Only the state change is observed, not the level change
  // (UIDeviceBatteryLevelDidChangeNotification). The public stream is one of
  // BatteryState, and the level changes far more often without the state
  // changing, so observing it would produce repeated events.
  _batteryStateObserver = [NSNotificationCenter.defaultCenter
      addObserverForName:UIDeviceBatteryStateDidChangeNotification
                  object:nil
                   queue:NSOperationQueue.mainQueue
              usingBlock:^(__unused NSNotification *_Nonnull notification) {
                // The notification does not carry the new state, it only
                // announces that it changed, so UIDevice must be asked again.
                [weakSelf emitCurrentState];
              }];
}

- (void)stopObservingBatteryState {
  if (_batteryStateObserver == nil) {
    return;
  }

  [NSNotificationCenter.defaultCenter removeObserver:_batteryStateObserver];
  _batteryStateObserver = nil;
}

- (void)emitCurrentState {
  // This check is mandatory: sending a message to nil is a no-op, but
  // invoking a block that is nil crashes the process.
  if (_eventSink == nil) {
    return;
  }
  _eventSink([self currentStateIdentifier]);
}

@end
