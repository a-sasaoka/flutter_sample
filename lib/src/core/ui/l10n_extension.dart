import 'package:flutter/material.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';

/// AppLocalizations へのアクセスを簡略化する拡張
extension AppLocalizationsX on BuildContext {
  /// [AppLocalizations] を取得します。
  ///
  /// 取得できない場合は [FlutterError] をスローします。
  /// 本来 [MaterialApp] の localizationsDelegates が正しく設定されていれば
  /// null になることはありません。
  AppLocalizations get l10n {
    final l10n = AppLocalizations.of(this);
    if (l10n == null) {
      throw FlutterError(
        'AppLocalizations not found in the current context. '
        'Make sure to wrap your widget tree with a Localizations widget.',
      );
    }
    return l10n;
  }
}
