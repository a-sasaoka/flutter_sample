// lib/src/features/splash/presentation/splash_screen.dart
import 'package:flutter/material.dart';

/// スプラッシュ画面
class SplashScreen extends StatelessWidget {
  /// コンストラクタ
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
