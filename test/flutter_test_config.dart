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
      // 通常フォントとして登録
      final loader = FontLoader('NotoSansJP')
        ..addFont(Future.value(ByteData.view(fontData.buffer)));
      await loader.load();

      // monospace（等幅）指定時のトーフ化を防ぐために登録
      final loaderMonospace = FontLoader('monospace')
        ..addFont(Future.value(ByteData.view(fontData.buffer)));
      await loaderMonospace.load();
    }
  });

  // CI環境（GitHub Actionsなど）かどうかを判定する
  final isRunningInCi = Platform.environment.containsKey('CI');

  // Alchemistの設定を適用してテストを実行する
  return AlchemistConfig.runWithConfig(
    config: AlchemistConfig(
      platformGoldensConfig: PlatformGoldensConfig(
        enabled: !isRunningInCi,
        diffThreshold: 0, // Macローカルは厳しく完全一致
      ),
      ciGoldensConfig: const CiGoldensConfig(
        diffThreshold: 0.02, // CI環境は2.0%以内の微小なズレを許容する
      ),
    ),
    run: testMain,
  );
}
