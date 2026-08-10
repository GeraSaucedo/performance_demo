import 'dart:async';

import 'package:flutter/foundation.dart';

/// Long-lived global objects. Because they are global, any object that
/// subscribes or registers a listener here and does NOT unregister will stay
/// retained by these instances for the entire lifetime of the app.
class GlobalBus {
  GlobalBus._();

  static final GlobalBus instance = GlobalBus._();

  /// Emits a "system event" every second. Broadcast: supports multiple
  /// subscribers. Used by Demo 5.
  final StreamController<int> events = StreamController<int>.broadcast();

  /// "Theme" notifier that listeners register on. Used by Demo 6.
  final ValueNotifier<int> ticker = ValueNotifier<int>(0);

  Timer? _heartbeat;
  int _counter = 0;

  /// Starts the global heartbeat (idempotent). Called once from the main flow
  /// the first time a demo needs it.
  void ensureStarted() {
    _heartbeat ??= Timer.periodic(const Duration(seconds: 1), (_) {
      _counter++;
      events.add(_counter);
      ticker.value = _counter;
    });
  }
}
