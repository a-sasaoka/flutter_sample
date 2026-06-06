import 'dart:async';
import 'dart:io';
import 'package:alchemist/alchemist.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// すべてのテスト実行前に自動で呼び出される設定関数
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  setUpAll(() async {
    // 日本語フォント (Noto Sans JP) をロードする
    final fontFile = File('test/assets/fonts/NotoSansJP-Regular.ttf');
    if (fontFile.existsSync()) {
      final fontData = fontFile.readAsBytesSync();
      final loader = FontLoader('NotoSansJP')
        ..addFont(Future.value(ByteData.view(fontData.buffer)));
      await loader.load();
    }
  });

  // CI環境（GitHub Actionsなど）かどうかを判定する
  final isRunningInCi = Platform.environment.containsKey('CI');

  // Alchemistの設定を適用してテストを実行する
  return AlchemistConfig.runWithConfig(
    config: AlchemistConfig(
      platformGoldensConfig: PlatformGoldensConfig(
        enabled: !isRunningInCi,
      ),
    ),
    run: testMain,
  );
}
