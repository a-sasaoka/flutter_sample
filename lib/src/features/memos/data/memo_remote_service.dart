import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'memo_remote_service.g.dart';

/// サーバーやクラウドと通信するためのクラス
/// （今回は本物のサーバーを使わず、Mockを使用）
class MemoRemoteService {
  final List<Map<String, dynamic>> _mockServerData = [];

  /// サーバーからメモのデータを取得する
  Future<List<Map<String, dynamic>>> fetchMemos() async {
    // 実際に通信しているように見せるため、1秒間待つ
    await Future<void>.delayed(const Duration(seconds: 1));

    return _mockServerData;
  }

  /// メモをサーバーに保存（または更新）する
  Future<void> uploadMemo({
    required String id,
    required String title,
    required String content,
    required DateTime createdAt,
    required DateTime updatedAt,
    required bool isDeleted,
  }) async {
    // 実際に通信しているように見せるため、1秒間待つ
    await Future<void>.delayed(const Duration(seconds: 1));

    // すでに同じIDのメモがあれば上書きし、なければ追加する
    final existingIndex = _mockServerData.indexWhere((m) => m['id'] == id);
    final memoData = {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isDeleted': isDeleted,
    };

    if (existingIndex >= 0) {
      _mockServerData[existingIndex] = memoData;
    } else {
      _mockServerData.add(memoData);
    }
  }
}

/// [MemoRemoteService] をアプリのどこからでも簡単に呼び出せるようにするためのプロバイダー
@riverpod
MemoRemoteService memoRemoteService(Ref ref) {
  return MemoRemoteService();
}
