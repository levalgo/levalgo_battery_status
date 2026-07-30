# Changelog

## 0.1.0

First published version. iOS only, with the native layer written in
Objective-C.

### Added

- `getBatteryLevel()`: battery level as an integer from 0 to 100. Throws a
  `PlatformException` with code `UNAVAILABLE` when the system cannot report
  it, which is always the case on the iOS simulator.
- `getBatteryState()`: charging state as a `BatteryState` (`full`, `charging`,
  `discharging`, `unknown`).
- `onStateChanged`: stream of state changes over an `EventChannel`.

### Notes

- Requires iOS 13.0.
- The native layer switches battery monitoring on lazily and removes its
  `NSNotificationCenter` observer when the subscription is cancelled.
- State identifiers the Dart layer does not recognise map to
  `BatteryState.unknown`, so future states can be added without breaking
  consumers already depending on this version.
