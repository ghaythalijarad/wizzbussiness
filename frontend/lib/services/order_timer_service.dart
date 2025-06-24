import 'dart:async';

/// A service to manage countdown timers for orders.
/// Provides start, cancel, and expired callback functionality.
class OrderTimerService {
  // Active timers by order ID
  static final Map<String, Timer> _activeTimers = {};

  // StreamControllers emitting remaining seconds
  static final Map<String, StreamController<int>> _timerControllers = {};

  // Callback invoked when an order expires
  static void Function(String orderId)? _onOrderExpired;

  // Record timer start timestamps
  static final Map<String, DateTime> _startTimes = {};

  /// Register a callback to be called when any order timer expires.
  static void setOrderExpiredCallback(void Function(String) callback) {
    _onOrderExpired = callback;
  }

  /// Start a 2-minute countdown for the given order ID.
  static void startOrderTimer(String orderId) {
    // Cancel any existing timer for this order
    cancelOrderTimer(orderId);

    // Track start time
    _startTimes[orderId] = DateTime.now();

    final controller = StreamController<int>.broadcast();
    _timerControllers[orderId] = controller;

    int remainingSeconds = 120;

    // Emit initial remaining time immediately
    controller.add(remainingSeconds);

    // Periodic countdown every second
    _activeTimers[orderId] = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        remainingSeconds--;
        controller.add(remainingSeconds);
        if (remainingSeconds <= 0) {
          timer.cancel();
          _expireOrder(orderId);
        }
      },
    );
  }

  /// Returns remaining seconds for the countdown (0 if expired or not started)
  static int getRemainingSeconds(String orderId) {
    final start = _startTimes[orderId];
    if (start == null) return 0;
    final elapsed = DateTime.now().difference(start).inSeconds;
    final remaining = 120 - elapsed;
    return remaining >= 0 ? remaining : 0;
  }

  /// Cancel and clean up the timer and stream for the given order ID.
  static void cancelOrderTimer(String orderId) {
    _activeTimers.remove(orderId)?.cancel();
    _timerControllers.remove(orderId)?.close();
    _startTimes.remove(orderId);
  }

  /// Returns a broadcast stream of remaining seconds for the order.
  static Stream<int>? getTimerStream(String orderId) {
    return _timerControllers[orderId]?.stream;
  }

  /// Whether a timer is currently running for the order.
  static bool hasActiveTimer(String orderId) {
    return _activeTimers.containsKey(orderId);
  }

  /// Clean up all timers and streams (e.g., on app dispose).
  static void dispose() {
    for (final t in _activeTimers.values) {
      t.cancel();
    }
    _activeTimers.clear();
    for (final c in _timerControllers.values) {
      c.close();
    }
    _timerControllers.clear();
    _startTimes.clear();
  }

  /// Internal helper to expire the order and invoke callback.
  static void _expireOrder(String orderId) {
    cancelOrderTimer(orderId);
    _onOrderExpired?.call(orderId);
  }
}
