// 「機能（feature）」配下の画面サンプル。
// 後で Riverpod の Provider や API 通信をここに繋げていきます。

import 'package:flutter/material.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';

/// SampleScreen ウィジェット
class SampleScreen extends StatelessWidget {
  /// コンストラクタ
  const SampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.sampleTitle)),
      body: Center(
        child: Text(AppLocalizations.of(context)!.sampleDescription),
      ),
    );
  }
}
