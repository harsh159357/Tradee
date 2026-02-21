import 'package:hive_flutter/hive_flutter.dart';

class StorageService {
  static const String boxAccount = 'account';
  static const String boxPositions = 'positions';
  static const String boxHistory = 'history';
  static const String boxSettings = 'settings';

  static Future<void> init() async {
    await Hive.initFlutter();
    
    await Hive.openBox(boxAccount);
    await Hive.openBox(boxPositions);
    await Hive.openBox(boxHistory);
    await Hive.openBox(boxSettings);
    
    // Auto-Reset Check
    final settingsBox = Hive.box(boxSettings);
    final accountBox = Hive.box(boxAccount);
    final positionsBox = Hive.box(boxPositions);
    
    final now = DateTime.now().toUtc();
    final todayExpiry = DateTime.utc(now.year, now.month, now.day, 23, 59, 59);
    
    final lastExpiryStr = settingsBox.get('last_expiry');
    if (lastExpiryStr != null) {
      final lastExpiry = DateTime.parse(lastExpiryStr);
      if (now.isAfter(lastExpiry)) {
        // Daily reset triggered
        await positionsBox.clear();
        await accountBox.put('balance', 100000.0);
      }
    }
    
    // Always update to today's expiry for next launch
    await settingsBox.put('last_expiry', todayExpiry.toIso8601String());

    // Initialize default balance if empty
    if (accountBox.get('balance') == null) {
      await accountBox.put('balance', 100000.0);
    }
  }

  static Box getBox(String name) => Hive.box(name);
}
