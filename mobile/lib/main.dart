import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/animation_screen.dart';
import 'theme.dart';

void main() {
  runApp(const ProviderScope(child: QuickDeliveryApp()));
}

class QuickDeliveryApp extends StatelessWidget {
  const QuickDeliveryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuickDelivery',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}