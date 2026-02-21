import 'dart:async';

class TimeEngine {
  final DateTime? _customExpiry;

  /// [customExpiry] allows future multi-expiry support.
  /// Defaults to today 23:59:59 UTC when null.
  TimeEngine({DateTime? customExpiry}) : _customExpiry = customExpiry;

  DateTime get expiry => _customExpiry ?? _todayExpiry();

  static DateTime _todayExpiry() {
    final now = DateTime.now().toUtc();
    return DateTime.utc(now.year, now.month, now.day, 23, 59, 59);
  }

  double calculateT() {
    final now = DateTime.now().toUtc();
    final remaining = expiry.difference(now);

    if (remaining.isNegative) return 0.0;

    return remaining.inSeconds / (365 * 24 * 60 * 60);
  }

  Stream<double> tStream() {
    return Stream.periodic(const Duration(seconds: 1), (_) => calculateT());
  }

  /// Formatted countdown string (HH:mm:ss)
  String getCountdown() {
    final now = DateTime.now().toUtc();
    final diff = expiry.difference(now);
    if (diff.isNegative) return "00:00:00";

    final h = diff.inHours.toString().padLeft(2, '0');
    final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final s = (diff.inSeconds % 60).toString().padLeft(2, '0');

    return "$h:$m:$s";
  }

  /// Countdown in IST display format (HH:mm:ss IST)
  String getCountdownIST() {
    final nowUtc = DateTime.now().toUtc();
    final diff = expiry.difference(nowUtc);
    if (diff.isNegative) return "00:00:00";

    final h = diff.inHours.toString().padLeft(2, '0');
    final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final s = (diff.inSeconds % 60).toString().padLeft(2, '0');

    return "$h:$m:$s";
  }

  /// Returns the expiry time formatted in IST (UTC+5:30)
  String get expiryIST {
    final ist = expiry.add(const Duration(hours: 5, minutes: 30));
    final h = ist.hour.toString().padLeft(2, '0');
    final m = ist.minute.toString().padLeft(2, '0');
    return '$h:$m IST';
  }
}
