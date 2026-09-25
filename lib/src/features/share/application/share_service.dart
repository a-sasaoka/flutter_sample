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
    final hasSubject = subject != null && subject.isNotEmpty;
    logger.info(
      '📤 [ShareService] shareText: length=${text.length}, '
      'hasSubject=$hasSubject',
    );

    return await _safeShare(
      'shareText',
      ShareParams(text: text, subject: subject, sharePositionOrigin: origin),
    );
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
    final textLen = text?.length ?? 0;
    logger.info(
      '📤 [ShareService] shareXFiles: ${files.length} files, '
      'textLength=$textLen',
    );

    return await _safeShare(
      'shareXFiles',
      ShareParams(
        files: files,
        text: text,
        subject: subject,
        sharePositionOrigin: origin,
      ),
    );
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
    final hasUrl = url != null && url.isNotEmpty;
    logger.info(
      '📤 [ShareService] shareToX: host=${uri.host}, '
      'textLength=${text.length}, hasUrl=$hasUrl',
    );

    return await _safeLaunchUrl('X', uri);
  }

  /// LINE のメッセージ送信画面を直接開く
  Future<bool> shareToLine({required String text}) async {
    final encoded = Uri.encodeComponent(text);
    final uri = Uri.parse('${ShareConfig.lineMessageBaseUrl}$encoded');
    logger.info(
      '📤 [ShareService] shareToLine: host=${uri.host}, '
      'textLength=${text.length}',
    );

    return await _safeLaunchUrl('LINE', uri);
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

  /// OS標準シェア処理を安全に実行し、例外発生時は [ShareResultStatus.unavailable] を返す
  Future<ShareResult> _safeShare(String actionName, ShareParams params) async {
    ShareResult result;
    try {
      result = await appLockService.runWithLockSuppression<ShareResult>(
        () => _sharePlus.share(params),
      );
    } on Object {
      logger.error('❌ [ShareService] $actionName failed with exception');
      result = const ShareResult('', ShareResultStatus.unavailable);
    }

    _logShareResult(actionName, result);
    return result;
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

  /// URL起動を安全に実行し、起動失敗または例外発生時は false を返す
  Future<bool> _safeLaunchUrl(String serviceName, Uri uri) async {
    try {
      final launched = await appLockService.runWithLockSuppression<bool>(
        () => launchUrl(uri, mode: LaunchMode.externalApplication),
      );

      if (!launched) {
        logger.warning(
          '⚠️ [ShareService] Could not launch $serviceName intent: '
          'host=${uri.host}',
        );
      }
      return launched;
    } on Object {
      logger.warning(
        '⚠️ [ShareService] Failed to launch $serviceName intent: '
        'host=${uri.host}',
      );
      return false;
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
