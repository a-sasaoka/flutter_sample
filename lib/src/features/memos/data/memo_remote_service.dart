import 'package:dio/dio.dart';
import 'package:flutter_sample/src/core/exceptions/app_exception.dart';
import 'package:flutter_sample/src/core/network/api_client.dart';
import 'package:flutter_sample/src/core/network/request_auth_pin.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'memo_remote_service.g.dart';

/// アップロード応答から取得したサーバー採番タイムスタンプ
typedef UploadedMemoTimestamps = ({DateTime? createdAt, DateTime? updatedAt});

/// サーバーやクラウドと通信するためのクラス
class MemoRemoteService {
  /// ApiClientを受け取って初期化します
  MemoRemoteService(this._api);

  final ApiClient _api;

  static DateTime? _parseTimestamp(Object? value) {
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  static UploadedMemoTimestamps? _extractUploadedTimestamps(Object? data) {
    if (data is! Map) {
      return null;
    }
    final createdAt = _parseTimestamp(data['createdAt']);
    final updatedAt = _parseTimestamp(data['updatedAt']);
    if (createdAt == null && updatedAt == null) {
      return null;
    }
    return (createdAt: createdAt, updatedAt: updatedAt);
  }

  Options? _buildPinnedAuthOptions(String? expectedUserId) {
    if (expectedUserId == null) {
      return null;
    }
    return Options(
      extra: {
        RequestAuthPin.extraKey: RequestAuthPin(expectedUserId: expectedUserId),
      },
    );
  }

  /// サーバーからメモのデータを取得する
  Future<List<Map<String, dynamic>>> fetchMemos({
    String? expectedUserId,
    CancelToken? cancelToken,
  }) async {
    // サーバーの /memos エンドポイントからデータを取得します
    final response = await _api.get<List<dynamic>>(
      '/memos',
      options: _buildPinnedAuthOptions(expectedUserId),
      cancelToken: cancelToken,
    );
    final data = response.data;
    if (data == null) {
      return [];
    }

    // JSONの日付文字列を DateTime 型に復元してリストにして返します
    return data.map((e) {
      final map = Map<String, dynamic>.from(e as Map);
      if (_parseTimestamp(map['createdAt']) case final parsed?) {
        map['createdAt'] = parsed;
      }
      if (_parseTimestamp(map['updatedAt']) case final parsed?) {
        map['updatedAt'] = parsed;
      }
      return map;
    }).toList();
  }

  /// メモをサーバーに保存（または更新）し、サーバー採番のタイムスタンプを返す
  Future<UploadedMemoTimestamps?> uploadMemo({
    required String id,
    required String title,
    required String content,
    required DateTime createdAt,
    required DateTime updatedAt,
    required bool isDeleted,
    String? expectedUserId,
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

    // PUT〜404後のPOST〜401再試行まで送信元ユーザーと認証ヘッダーを共有固定する
    final requestOptions = _buildPinnedAuthOptions(expectedUserId);

    try {
      // まずはPUTリクエストで既存メモの更新を試みます
      final response = await _api.put<dynamic>(
        '/memos/${Uri.encodeComponent(id)}',
        data: memoData,
        options: requestOptions,
      );
      return _extractUploadedTimestamps(response.data);
    } on DioException catch (e) {
      // サーバーからの直接の返事、または共通処理で包み直された独自エラーからステータスコードを取り出します（二重チェック）
      final error = e.error;
      final statusCode =
          e.response?.statusCode ??
          (error is AppException ? error.statusCode : null);

      // 404 (データが見つからない) エラーの場合のみ、POSTリクエストで新規登録を行います
      if (statusCode == 404) {
        final response = await _api.post<dynamic>(
          '/memos',
          data: memoData,
          options: requestOptions,
        );
        return _extractUploadedTimestamps(response.data);
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
