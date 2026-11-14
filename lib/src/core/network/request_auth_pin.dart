/// リクエスト単位で送信元ユーザーIDと固定済み認証ヘッダーを共有するコンテキスト
class RequestAuthPin {
  /// コンストラクタ
  RequestAuthPin({required this.expectedUserId});

  /// `RequestOptions.extra` に格納する際のキー
  static const extraKey = 'request_auth_pin';

  /// このリクエストの送信元ユーザーID
  final String expectedUserId;

  /// 一度検証・確定された Authorization ヘッダー値（404後のPOST等で引き継ぐ）
  String? authorizationHeader;
}
