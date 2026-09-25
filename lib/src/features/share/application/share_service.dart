import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/app_lock/application/app_lock_service.dart';
import 'package:flutter_sample/src/features/share/domain/share_config.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

part 'share_service.g.dart';

/// 共有機能（OS標準シェアシート・特定SNS直接共有）を提供するサービスクラス
class ShareService {
  /// コンストラクタ
  ShareService({
    required this.appLockService,
    required this.logger,
    SharePlus? sharePlus,
  }) : _sharePlus = sharePlus ?? SharePlus.instance;

  /// アプリロック誤作動防止用のサービス
  final AppLockService appLockService;

  /// ロガー
  final Talker logger;

  /// share_plus インスタンス
  final SharePlus _sharePlus;

  /// OS標準シェアシートでテキスト・URLを共有する
  Future<ShareResult> shareText({
    required String text,
    String? subject,
    Rect? sharePositionOrigin,
  }) async {
    final origin =
        sharePositionOrigin ?? ShareConfig.defaultSharePositionOrigin;
    logger.info('📤 [ShareService] shareText: "$text", subject: "$subject"');

    final result = await appLockService.runWithLockSuppression<ShareResult>(
      () => _sharePlus.share(
        ShareParams(text: text, subject: subject, sharePositionOrigin: origin),
      ),
    );

    _logShareResult('shareText', result);
    return result;
  }

  /// OS標準シェアシートで画像・ファイルを共有する
  Future<ShareResult> shareXFiles({
    required List<XFile> files,
    String? text,
    String? subject,
    Rect? sharePositionOrigin,
  }) async {
    final origin =
        sharePositionOrigin ?? ShareConfig.defaultSharePositionOrigin;
    logger.info(
      '📤 [ShareService] shareXFiles: ${files.length} files, text: "$text"',
    );

    final result = await appLockService.runWithLockSuppression<ShareResult>(
      () => _sharePlus.share(
        ShareParams(
          files: files,
          text: text,
          subject: subject,
          sharePositionOrigin: origin,
        ),
      ),
    );

    _logShareResult('shareXFiles', result);
    return result;
  }

  /// X (旧Twitter) の投稿画面をWeb Intent経由で直接開く
  Future<bool> shareToX({
    required String text,
    String? url,
    List<String>? hashtags,
  }) async {
    final queryParameters = <String, String>{
      'text': text,
      if (url != null && url.isNotEmpty) 'url': url,
      if (hashtags != null && hashtags.isNotEmpty)
        'hashtags': hashtags.map((t) => t.replaceAll('#', '')).join(','),
    };

    final uri = Uri.https(
      ShareConfig.xIntentHost,
      ShareConfig.xIntentPath,
      queryParameters,
    );
    logger.info('📤 [ShareService] shareToX: $uri');

    final launched = await appLockService.runWithLockSuppression<bool>(
      () => launchUrl(uri, mode: LaunchMode.externalApplication),
    );

    if (!launched) {
      logger.warning('⚠️ [ShareService] Could not launch X intent: $uri');
    }
    return launched;
  }

  /// LINE のメッセージ送信画面を直接開く
  Future<bool> shareToLine({required String text}) async {
    final encoded = Uri.encodeComponent(text);
    final uri = Uri.parse('${ShareConfig.lineMessageBaseUrl}$encoded');
    logger.info('📤 [ShareService] shareToLine: $uri');

    final launched = await appLockService.runWithLockSuppression<bool>(
      () => launchUrl(uri, mode: LaunchMode.externalApplication),
    );

    if (!launched) {
      logger.warning('⚠️ [ShareService] Could not launch LINE intent: $uri');
    }
    return launched;
  }

  /// サンプルPNG画像をメモリ上に生成して返す
  Future<XFile> createSampleImage() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 400, 400));
    final bgPaint = Paint()..color = const Color(0xFF02569B);
    canvas.drawRect(const Rect.fromLTWH(0, 0, 400, 400), bgPaint);

    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Flutter Sample\nShare Demo',
        style: TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: 360);

    textPainter.paint(
      canvas,
      Offset((400 - textPainter.width) / 2, (400 - textPainter.height) / 2),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(400, 400);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    picture.dispose();
    image.dispose();

    return XFile.fromData(
      byteData!.buffer.asUint8List(),
      mimeType: 'image/png',
      name: 'flutter_sample_share.png',
    );
  }

  /// [ShareResult] の結果に応じた適切なログを出力する
  void _logShareResult(String actionName, ShareResult result) {
    switch (result.status) {
      case ShareResultStatus.success:
        logger.info(
          '📤 [ShareService] $actionName succeeded (raw: ${result.raw})',
        );
      case ShareResultStatus.dismissed:
        logger.info('ℹ️ [ShareService] $actionName was dismissed by user');
      case ShareResultStatus.unavailable:
        logger.warning(
          '⚠️ [ShareService] $actionName is unavailable on this platform',
        );
    }
  }
}

/// [ShareService] を提供するプロバイダー
@riverpod
ShareService shareService(Ref ref) {
  return ShareService(
    appLockService: ref.watch(appLockServiceProvider.notifier),
    logger: ref.watch(loggerProvider),
  );
}
