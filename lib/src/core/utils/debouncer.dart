import 'dart:async';
import 'package:flutter/foundation.dart';

/// ⏱️ 指定された待機時間の間、新しい処理が来なければコールバックを実行するデバウンス制御クラス
class Debouncer {
  /// コンストラクタ
  ///
  /// [delay] で待機時間（デフォルト: 400ミリ秒）を指定します。
  Debouncer({this.delay = const Duration(milliseconds: 400)});

  /// 待機時間
  final Duration delay;

  /// 実行待機中のタイマー
  Timer? _timer;

  /// タイマーが現在待機中（実行前）かどうか
  bool get isActive => _timer?.isActive ?? false;

  /// コールバックを予約して実行します。
  ///
  /// 待機中に再度呼び出された場合は直前の予約をキャンセルし、
  /// 再度 [delay] 時間待機してから [action] を実行します。
  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// 待機中のタイマーをキャンセルします。
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// タイマーを破棄します。画面破棄時（StateのdisposeやuseEffectのクリーンアップ）に呼び出します。
  void dispose() {
    cancel();
  }
}
