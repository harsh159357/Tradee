import 'dart:async';

class TimeEngine {
  /// UTC Expiry: Today at 23:59:59 UTC
  DateTime get expiry => DateTime.now().toUtc().copyWith(
    hour: 23,
    minute: 59,
    second: 59,
    millisecond: 0,
    microsecond: 0,
  );

  /// Calculate T (Time to expiry in years)
  double calculateT() {
    final now = DateTime.now().toUtc();
    final remaining = expiry.difference(now);
    
    if (remaining.isNegative) return 0.0;
    
    // T = seconds remaining / seconds in a year
    return remaining.inSeconds / (365 * 24 * 60 * 60);
  }

  /// Stream of T updates every second
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
}

// Extension to help with copyWith on DateTime if needed, 
// though for Dart 2.19+ we can just use manual construction or a helper.
extension DateTimeCopy on DateTime {
  DateTime copyWith({
    int? year,
    int? month,
    int? day,
    int? hour,
    int? minute,
    int? second,
    int? millisecond,
    int? microsecond,
  }) {
    return DateTime.utc(
      year ?? this.year,
      month ?? this.month,
      day ?? this.day,
      hour ?? this.hour,
      minute ?? this.minute,
      second ?? this.second,
      millisecond ?? this.millisecond,
      microsecond ?? this.microsecond,
    );
  }
}
