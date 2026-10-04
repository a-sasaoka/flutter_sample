import 'package:flutter_sample/src/core/services/lock_suppression_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:url_launcher/url_launcher.dart';

part 'url_launcher_service.g.dart';

/// URL起動を担当するサービスクラス
class UrlLauncherService {
  /// コンストラクタ
  const UrlLauncherService({required this.lockSuppressionRunner});

  /// アプリ復帰時の誤ロック防止用ランナー
  final LockSuppressionRunner lockSuppressionRunner;

  /// 文字列が有効な Web URL (http/https) かどうかを判定する
  bool isWebUrl(String urlString) {
    final uri = Uri.tryParse(urlString.trim());
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.hasAuthority &&
        uri.host.isNotEmpty;
  }

  /// 外部ブラウザでURLを開く
  Future<bool> openUrl(String urlString) async {
    final trimmed = urlString.trim();
    if (!isWebUrl(trimmed)) {
      return false;
    }
    final uri = Uri.parse(trimmed);
    return await lockSuppressionRunner(
      () => launchUrl(uri, mode: LaunchMode.externalApplication),
    );
  }
}

/// [UrlLauncherService] を提供するプロバイダー
@riverpod
UrlLauncherService urlLauncherService(Ref ref) {
  return UrlLauncherService(
    lockSuppressionRunner: ref.watch(lockSuppressionRunnerProvider),
  );
}
