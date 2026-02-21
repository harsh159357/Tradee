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
    
    // Initialize default balance if empty
    final accountBox = Hive.box(boxAccount);
    if (accountBox.get('balance') == null) {
      await accountBox.put('balance', 100000.0);
    }
  }

  static Box getBox(String name) => Hive.box(name);
}
