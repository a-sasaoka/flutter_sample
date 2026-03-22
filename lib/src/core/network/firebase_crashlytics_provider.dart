// coverage:ignore-file
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'firebase_crashlytics_provider.g.dart';

/// Firebase Crashlytics のインスタンスを提供するプロバイダー
@riverpod
FirebaseCrashlytics firebaseCrashlytics(Ref ref) {
  return FirebaseCrashlytics.instance;
}
