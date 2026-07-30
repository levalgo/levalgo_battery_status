import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:levalgo_battery_status/levalgo_battery_status.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final LevalgoBatteryStatus _battery = LevalgoBatteryStatus();
  StreamSubscription<BatteryState>? _subscription;

  int? _level;
  BatteryState _state = BatteryState.unknown;
  String? _error;

  @override
  void initState() {
    super.initState();
    _readInitialState();

    // The stream only emits on changes, which is why the initial state is
    // read separately above.
    _subscription = _battery.onStateChanged.listen((state) {
      if (!mounted) return;
      setState(() => _state = state);
      _readLevel();
    });
  }

  @override
  void dispose() {
    // Cancelling makes the native side remove its NSNotificationCenter
    // observer. Without this, the observer outlives the widget.
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _readInitialState() async {
    final state = await _battery.getBatteryState();
    if (!mounted) return;
    setState(() => _state = state);
    await _readLevel();
  }

  Future<void> _readLevel() async {
    try {
      final level = await _battery.getBatteryLevel();
      if (!mounted) return;
      setState(() {
        _level = level;
        _error = null;
      });
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() {
        _level = null;
        _error = e.code == 'UNAVAILABLE'
            ? 'Level unavailable. This is always the case on the iOS '
                  'simulator: try a physical device.'
            : 'Platform error: ${e.code}';
      });
    }
  }

  String get _stateLabel => switch (_state) {
    BatteryState.full => 'Fully charged',
    BatteryState.charging => 'Charging',
    BatteryState.discharging => 'Discharging',
    BatteryState.unknown => 'Unknown',
  };

  IconData get _stateIcon => switch (_state) {
    BatteryState.full => Icons.battery_full,
    BatteryState.charging => Icons.battery_charging_full,
    BatteryState.discharging => Icons.battery_5_bar,
    BatteryState.unknown => Icons.battery_unknown,
  };

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'levalgo_battery_status',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(title: const Text('Battery status')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_stateIcon, size: 96),
                const SizedBox(height: 16),
                Text(
                  _level == null ? '--' : '$_level%',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  _stateLabel,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                FilledButton.tonalIcon(
                  onPressed: _readInitialState,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Read again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
