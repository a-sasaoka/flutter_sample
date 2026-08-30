// coverage:ignore-file
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'firebase_performance_provider.g.dart';

/// Firebase Performance Monitoring のインスタンスを提供するプロバイダー（未初期化時は null）
@Riverpod(keepAlive: true)
FirebasePerformance? firebasePerformance(Ref ref) {
  return Firebase.apps.isNotEmpty ? FirebasePerformance.instance : null;
}
