import 'package:hive_flutter/hive_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../core/constants.dart';

abstract class StorageInterface {
  Box openBox(String name);
}

class StorageService implements StorageInterface {
  static const String boxAccount = 'account';
  static const String boxPositions = 'positions';
  static const String boxHistory = 'history';
  static const String boxSettings = 'settings';

  static final StorageService _instance = StorageService._();

  StorageService._();

  static Future<void> init() async {
    await Hive.initFlutter();

    await Hive.openBox(boxAccount);
    await Hive.openBox(boxPositions);
    await Hive.openBox(boxHistory);
    await Hive.openBox(boxSettings);

    final settingsBox = Hive.box(boxSettings);
    final accountBox = Hive.box(boxAccount);
    final positionsBox = Hive.box(boxPositions);

    final now = DateTime.now().toUtc();
    final todayExpiry = DateTime.utc(now.year, now.month, now.day, 23, 59, 59);

    final lastExpiryStr = settingsBox.get('last_expiry');
    if (lastExpiryStr != null) {
      final lastExpiry = DateTime.parse(lastExpiryStr);
      if (now.isAfter(lastExpiry)) {
        await positionsBox.clear();
        await accountBox.put('balance', AppConstants.initialBalance);
      }
    }

    await settingsBox.put('last_expiry', todayExpiry.toIso8601String());

    if (accountBox.get('balance') == null) {
      await accountBox.put('balance', AppConstants.initialBalance);
    }
  }

  /// Static accessor for existing code. For new code/tests, use [storageProvider].
  static Box getBox(String name) => Hive.box(name);

  @override
  Box openBox(String name) => Hive.box(name);
}

/// Injectable storage provider. Override in tests with mock.
final storageProvider = Provider<StorageInterface>((ref) {
  return StorageService._instance;
});
