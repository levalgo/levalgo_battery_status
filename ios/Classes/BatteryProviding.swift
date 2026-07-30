import UIKit

/// Source of battery information.
///
/// The plugin depends on this protocol rather than on `UIDevice` directly.
/// That allows injecting an implementation with fixed values in tests, which
/// is what makes the XCTest suite runnable on the simulator: there, `UIDevice`
/// never reports real battery data.
///
/// The Objective-C version had no such seam. The plugin read `UIDevice`
/// directly, so there was no way to test it without a physical device.
public protocol BatteryProviding {
  /// Charge level, from 0.0 to 1.0.
  ///
  /// Returns a negative value when the system cannot report it.
  var level: Float { get }

  /// The current charging state.
  var state: UIDevice.BatteryState { get }

  /// Switches battery monitoring on.
  ///
  /// This must be called before reading [level] or [state]: without it the
  /// system returns -1.0 and `.unknown` respectively.
  func enableMonitoring()
}

/// The real implementation, backed by the system's `UIDevice`.
public struct DeviceBattery: BatteryProviding {
  public init() {}

  public var level: Float { UIDevice.current.batteryLevel }

  public var state: UIDevice.BatteryState { UIDevice.current.batteryState }

  public func enableMonitoring() {
    let device = UIDevice.current
    // Switched on once and left on for the lifetime of the plugin. Switching
    // it off after each one-off query would switch monitoring off underneath
    // an event stream that was still active.
    if !device.isBatteryMonitoringEnabled {
      device.isBatteryMonitoringEnabled = true
    }
  }
}
