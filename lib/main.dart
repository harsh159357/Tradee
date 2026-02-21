import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'data/storage_service.dart';
import 'ui/theme.dart';
import 'ui/asset_selection_screen.dart';

import 'ui/navigation_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  runApp(const ProviderScope(child: TradeeApp()));
}

class TradeeApp extends StatelessWidget {
  const TradeeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tradee',
      theme: AppTheme.darkTheme,
      home: const MainNavigationWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}
