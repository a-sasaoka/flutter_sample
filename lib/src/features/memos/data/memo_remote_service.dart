import 'package:dio/dio.dart';
import 'package:flutter_sample/src/core/exceptions/app_exception.dart';
import 'package:flutter_sample/src/core/network/api_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'memo_remote_service.g.dart';

/// サーバーやクラウドと通信するためのクラス
class MemoRemoteService {
  /// ApiClientを受け取って初期化します
  MemoRemoteService(this._api);

  final ApiClient _api;

  /// サーバーからメモのデータを取得する
  Future<List<Map<String, dynamic>>> fetchMemos() async {
    // サーバーの /memos エンドポイントからデータを取得します
    final response = await _api.get<List<dynamic>>('/memos');
    final data = response.data;
    if (data == null) {
      return [];
    }

    // JSONの日付文字列を DateTime 型に復元してリストにして返します
    return data.map((e) {
      final map = Map<String, dynamic>.from(e as Map);
      if (map['createdAt'] is String) {
        map['createdAt'] = DateTime.parse(map['createdAt'] as String);
      }
      if (map['updatedAt'] is String) {
        map['updatedAt'] = DateTime.parse(map['updatedAt'] as String);
      }
      return map;
    }).toList();
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
    // サーバーに送信するためのMap形式データを作ります。日付は文字列に変換します。
    final memoData = {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isDeleted': isDeleted,
    };

    try {
      // まずはPUTリクエストで既存メモの更新を試みます
      await _api.put<void>('/memos/$id', data: memoData);
    } on DioException catch (e) {
      // サーバーからの直接の返事、または共通処理で包み直された独自エラーからステータスコードを取り出します（二重チェック）
      final error = e.error;
      final statusCode =
          e.response?.statusCode ??
          (error is AppException ? error.statusCode : null);

      // 404 (データが見つからない) エラーの場合のみ、POSTリクエストで新規登録を行います
      if (statusCode == 404) {
        await _api.post<void>('/memos', data: memoData);
      } else {
        rethrow;
      }
    }
  }
}

/// [MemoRemoteService] をアプリのどこからでも簡単に呼び出せるようにするためのプロバイダー
@riverpod
MemoRemoteService memoRemoteService(Ref ref) {
  return MemoRemoteService(ref.watch(apiClientProvider));
}
