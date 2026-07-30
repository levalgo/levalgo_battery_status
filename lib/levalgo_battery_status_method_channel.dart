import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'levalgo_battery_status_platform_interface.dart';
import 'src/battery_state.dart';

/// A channel-based implementation of [LevalgoBatteryStatusPlatform].
///
/// One-off queries go over a [MethodChannel] and the continuous stream of
/// state changes over an [EventChannel]. They are two different channels
/// because they solve two different problems: one is request/response, the
/// other is a subscription the native side keeps feeding.
class MethodChannelLevalgoBatteryStatus extends LevalgoBatteryStatusPlatform {
  /// The method channel used for one-off queries.
  @visibleForTesting
  final MethodChannel methodChannel = const MethodChannel(
    'levalgo_battery_status',
  );

  /// The event channel used for the stream of state changes.
  @visibleForTesting
  final EventChannel eventChannel = const EventChannel(
    'levalgo_battery_status/state',
  );

  Stream<BatteryState>? _onStateChanged;

  @override
  Future<int> getBatteryLevel() async {
    final level = await methodChannel.invokeMethod<int>('getBatteryLevel');
    if (level == null) {
      throw PlatformException(
        code: 'UNAVAILABLE',
        message: 'The platform did not return a battery level.',
      );
    }
    return level;
  }

  @override
  Future<BatteryState> getBatteryState() async {
    final state = await methodChannel.invokeMethod<String>('getBatteryState');
    return _parseState(state);
  }

  @override
  Stream<BatteryState> get onStateChanged {
    // The stream is cached because every call to receiveBroadcastStream()
    // returns a new one, and each would send its own listen/cancel to the
    // native side over the same channel.
    return _onStateChanged ??= eventChannel.receiveBroadcastStream().map(
      (event) => _parseState(event as String?),
    );
  }

  /// Translates the identifier sent by the native layer.
  ///
  /// Anything unrecognised falls back to [BatteryState.unknown], so a future
  /// version of the native layer can add states without breaking consumers
  /// that are already published.
  BatteryState _parseState(String? value) => switch (value) {
    'full' => BatteryState.full,
    'charging' => BatteryState.charging,
    'discharging' => BatteryState.discharging,
    _ => BatteryState.unknown,
  };
}
