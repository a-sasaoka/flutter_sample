import 'package:flutter_sample/src/features/app_lock/application/app_lock_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:url_launcher/url_launcher.dart';

part 'url_launcher_service.g.dart';

/// URL起動を担当するサービスクラス
class UrlLauncherService {
  /// コンストラクタ
  const UrlLauncherService({this.appLockService});

  /// 誤ロック防止用のアプリロックサービス
  final AppLockService? appLockService;

  /// 文字列が有効な Web URL (http/https) かどうかを判定する
  bool isWebUrl(String urlString) {
    final uri = Uri.tryParse(urlString.trim());
    return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  /// 外部ブラウザでURLを開く
  Future<bool> openUrl(String urlString) async {
    final uri = Uri.tryParse(urlString.trim());
    if (uri == null) {
      return false;
    }
    final lockService = appLockService;
    if (lockService != null) {
      return await lockService.runWithLockSuppression(
        () => launchUrl(uri, mode: LaunchMode.externalApplication),
      );
    }
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// [UrlLauncherService] を提供するプロバイダー
@riverpod
UrlLauncherService urlLauncherService(Ref ref) {
  return UrlLauncherService(
    appLockService: ref.watch(appLockServiceProvider.notifier),
  );
}
