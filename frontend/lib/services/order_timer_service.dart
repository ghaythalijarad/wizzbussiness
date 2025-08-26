class OrderTimerService {
  static final Map<String, DateTime> _orderTimers = {};
  static const int autoRejectTimeMinutes = 30;

  static void startTimer(String orderId) {
    _orderTimers[orderId] = DateTime.now();
  }

  static void stopTimer(String orderId) {
    _orderTimers.remove(orderId);
  }

  static int getRemainingSeconds(String orderId) {
    final startTime = _orderTimers[orderId];
    if (startTime == null) return 0;

    final elapsed = DateTime.now().difference(startTime);
    final totalSeconds = autoRejectTimeMinutes * 60;
    final remainingSeconds = totalSeconds - elapsed.inSeconds;

    return remainingSeconds > 0 ? remainingSeconds : 0;
  }

  static bool shouldAutoReject(String orderId) {
    return getRemainingSeconds(orderId) <= 0;
  }

  static String formatRemainingTime(String orderId) {
    final remainingSeconds = getRemainingSeconds(orderId);
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  static void clearAllTimers() {
    _orderTimers.clear();
  }
}
