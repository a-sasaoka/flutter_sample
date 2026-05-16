import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'date_time_provider.g.dart';

/// 現在の日時を取得する関数を提供するプロバイダー
///
/// 以前の方式（DateTimeを直接返す）では、一度取得した値がキャッシュされてしまい
/// 時間が更新されない問題がありましたが、この方式（関数を返す）にすることで
/// 呼び出すたびに最新の時刻を取得できます。
@Riverpod(keepAlive: true)
DateTime Function() clock(Ref ref) {
  return DateTime.now;
}
