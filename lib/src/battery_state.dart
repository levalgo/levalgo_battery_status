/// Battery charging state as reported by the operating system.
///
/// The values mirror `UIDeviceBatteryState` on iOS.
enum BatteryState {
  /// The battery is fully charged.
  full,

  /// The device is plugged into a power source and charging.
  charging,

  /// The device is running on battery and draining.
  discharging,

  /// The system could not determine the state.
  ///
  /// On iOS this happens when battery monitoring is disabled, and always on
  /// the simulator, which exposes no real power information.
  unknown,
}
