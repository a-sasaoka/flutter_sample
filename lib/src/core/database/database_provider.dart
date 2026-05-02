import 'package:flutter_sample/src/app/database/app_database.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'database_provider.g.dart';

/// アプリ全体で共有するデータベース（AppDatabase）を提供するプロバイダー
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  return AppDatabase();
}
