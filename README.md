# levalgo_battery_status

Flutter plugin for iOS exposing the battery level, the charging state, and a
stream of state changes.

> ### What this package is
>
> A portfolio package. It exists to hand-write the native layer of a Flutter
> plugin and then migrate it in two isolated steps: Objective-C to Swift, and
> CocoaPods to Swift Package Manager. Each step lives in its own git tag so the
> diff can be read on its own, and [MIGRATION.md](MIGRATION.md) explains what
> changed at each one.
>
> **If you need this in production, use
> [`battery_plus`](https://pub.dev/packages/battery_plus).** It is maintained
> by Flutter Community, covers more platforms, and has years of real use behind
> it. This package does not try to compete with it, and its code is written
> from scratch without copying theirs.

## Platforms

| Platform  | Support                  |
| --------- | ------------------------ |
| iOS 13.0+ | Yes, own native layer    |
| Android   | No                       |

Android is deliberately not declared: declaring a platform without
implementing it leaves a `MissingPluginException` waiting for the first person
who installs it.

## Install

```yaml
dependencies:
  levalgo_battery_status: ^0.2.0
```

## Usage

```dart
import 'package:levalgo_battery_status/levalgo_battery_status.dart';

final battery = LevalgoBatteryStatus();

// Current level, from 0 to 100.
final level = await battery.getBatteryLevel();

// Current state: full, charging, discharging or unknown.
final state = await battery.getBatteryState();

// State changes. The stream emits on changes, not on subscription: call
// getBatteryState() for the initial value.
final subscription = battery.onStateChanged.listen((state) {
  print('New state: $state');
});

// On cancel, the native layer removes its system observer.
await subscription.cancel();
```

## API

| Member                | Returns                | Notes                                                  |
| --------------------- | ---------------------- | ------------------------------------------------------ |
| `getBatteryLevel()`   | `Future<int>`          | 0 to 100. Throws `PlatformException` with `UNAVAILABLE`. |
| `getBatteryState()`   | `Future<BatteryState>` | Returns `unknown` rather than throwing.                 |
| `onStateChanged`      | `Stream<BatteryState>` | Only emits on state changes.                            |

`BatteryState` has four values: `full`, `charging`, `discharging` and
`unknown`.

## The simulator reports no battery

On the iOS simulator, `UIDevice.batteryLevel` always returns `-1.0` and
`batteryState` returns `unknown`, no matter what the plugin does. That is why
`getBatteryLevel()` throws a `PlatformException` with code `UNAVAILABLE`
instead of inventing a number:

```dart
try {
  final level = await battery.getBatteryLevel();
} on PlatformException catch (e) {
  if (e.code == 'UNAVAILABLE') {
    // Almost certainly: you are on the simulator.
  }
}
```

**Test on a physical device.**

## Migration path

The value of this repository is in its history, not only in the current code.

| Tag      | State                   | What the diff shows           |
| -------- | ----------------------- | ----------------------------- |
| `v0.1.0` | Objective-C + CocoaPods | The legacy starting point     |
| `v0.2.0` | Swift + CocoaPods       | The Swift migration, isolated |

Read the diff directly:
[`v0.1.0...v0.2.0`](https://github.com/levalgo/levalgo_battery_status/compare/v0.1.0...v0.2.0)

**[MIGRATION.md](MIGRATION.md) walks through what changed and why**: the
podspec keys that came and went, why the Swift class has to be `public` and
`NSObject`-derived for the generated registrant to find it, how the
`NSNotificationCenter` teardown changed shape, and the protocol that made the
native layer testable.

Next up: Swift Package Manager alongside CocoaPods, in its own tag.

The Objective-C code stays reachable after the migration, at tag `v0.1.0` and
on the `objc-implementation` branch.

## Testing the native layer

Device readings sit behind the `BatteryProviding` protocol, which the plugin
takes through its initializer:

```swift
public init(
  battery: BatteryProviding = DeviceBattery(),
  notificationCenter: NotificationCenter = .default
)
```

Production code gets `DeviceBattery()`; tests inject a stub with fixed values.
That is what lets the whole XCTest suite run on the simulator, where `UIDevice`
reports no real battery data.

## Development

```bash
# Dart analysis and tests
flutter analyze
flutter test

# The example app, on a physical device
cd example && flutter run

# Integration tests, which do cross the native layer
cd example && flutter test integration_test

# Validate the podspec
pod lib lint ios/levalgo_battery_status.podspec --configuration=Debug --skip-tests
```

The Swift layer's XCTests live in the example app's `RunnerTests` target. Run
them from Xcode with **Product > Test**, or from the terminal:

```bash
cd example && flutter build ios --config-only --no-codesign
xcodebuild test \
  -workspace example/ios/Runner.xcworkspace \
  -scheme Runner \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

## License

MIT. See [LICENSE](LICENSE).
