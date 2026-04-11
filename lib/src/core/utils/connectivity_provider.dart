import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_provider.g.dart';

// coverage:ignore-start
/// ネットワークの接続状態を監視するStreamProvider
@riverpod
Stream<List<ConnectivityResult>> connectivity(Ref ref) {
  return Connectivity().onConnectivityChanged;
}
// coverage:ignore-end

/// 「現在オンラインかどうか」だけを返すProvider
@riverpod
bool isOnline(Ref ref) {
  // 最新の接続状態を取得
  final connectivityStatus = ref.watch(connectivityProvider).value;
  if (connectivityStatus == null) {
    return true; // 判定前はとりあえずtrueにしておく
  }

  // どれにも繋がっていない（none）でなければオンラインと判定
  return connectivityStatus.isNotEmpty &&
      !connectivityStatus.contains(ConnectivityResult.none);
}
