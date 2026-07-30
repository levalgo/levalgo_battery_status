# levalgo_battery_status

Flutter plugin for iOS exposing the battery level, the charging state, and a
stream of state changes.

> ### What this package is
>
> A portfolio package. It exists to hand-write the native layer of a Flutter
> plugin and then migrate it in two isolated steps: Objective-C to Swift, and
> CocoaPods to Swift Package Manager. Each step lives in its own git tag so the
> diff can be read on its own.
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
  levalgo_battery_status: ^0.1.0
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

| Tag      | State                   | What the diff shows        |
| -------- | ----------------------- | -------------------------- |
| `v0.1.0` | Objective-C + CocoaPods | The legacy starting point  |

Next up: Swift, and then Swift Package Manager alongside CocoaPods, each in
its own tag.

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

## License

MIT. See [LICENSE](LICENSE).
