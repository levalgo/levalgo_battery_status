# levalgo_battery_status example

Minimal app showing the battery level, the charging state, and subscribing to
the stream of state changes.

## Running it

A physical device is required. On the iOS simulator the battery level is not
available, and the app says so on screen instead of showing a percentage.

```bash
flutter run
```

## What to look at in the code

`lib/main.dart` is deliberately short. The parts worth reading:

- the initial state is read with `getBatteryState()`, because the stream only
  emits on changes and not on subscription;
- the subscription is cancelled in `dispose()`, which is what makes the native
  layer remove its `NSNotificationCenter` observer;
- the `UNAVAILABLE` error is caught and explained rather than left to blow up.
