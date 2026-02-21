import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../ui/navigation_wrapper.dart';
import '../ui/trading_screen.dart';

final navigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: navigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MainNavigationWrapper(),
    ),
    GoRoute(
      path: '/trade',
      builder: (context, state) => const TradingScreen(),
    ),
  ],
);
