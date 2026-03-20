import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'date_time_provider.g.dart';

/// 現在の日時を提供するプロバイダー
/// テスト時にはこのプロバイダーを override することで、任意の日時でテストが可能になります。
@riverpod
DateTime currentDateTime(Ref ref) {
  return DateTime.now();
}
