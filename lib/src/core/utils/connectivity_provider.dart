import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_provider.g.dart';

/// ネットワーク接続状態の判定ロジックを管理するサービス
class ConnectivityService {
  /// 現在の接続状態リストから、オンラインかどうかを判定する
  bool isOnline(List<ConnectivityResult> results) {
    // どの接続手段（Wi-Fi, モバイル等）も確立されていない（none）でなければオンライン
    return results.isNotEmpty && !results.contains(ConnectivityResult.none);
  }
}

/// [ConnectivityService] を提供するプロバイダー
@Riverpod(keepAlive: true)
ConnectivityService connectivityService(Ref ref) {
  return ConnectivityService();
}

// coverage:ignore-start
/// ネットワークの接続状態を監視するStreamProvider
@Riverpod(keepAlive: true)
Stream<List<ConnectivityResult>> connectivity(Ref ref) {
  return Connectivity().onConnectivityChanged;
}
// coverage:ignore-end

/// 「現在オンラインかどうか」をリアクティブに返すProvider
@riverpod
bool isOnline(Ref ref) {
  final results = ref.watch(connectivityProvider).value;
  if (results == null) {
    return true; // 初期状態（ロード中）はとりあえずtrueとして扱う
  }

  return ref.watch(connectivityServiceProvider).isOnline(results);
}
