import 'package:checks/checks.dart';
import 'package:flutter_sample/src/features/notification/domain/notification_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationPayload', () {
    test('デフォルト値でインスタンス化できること', () {
      const payload = NotificationPayload();
      check(payload.path).isNull();
      check(payload.title).isNull();
      check(payload.body).isNull();
      check(payload.data).isEmpty();
      check(payload.isNavigable).isFalse();
    });

    test('fromMap で各フィールドが正しく抽出されること (pathキー)', () {
      final payload = NotificationPayload.fromMap(
        {'path': '/chat', 'key': 'value'},
        title: 'Title',
        body: 'Body',
      );

      check(payload.path).equals('/chat');
      check(payload.title).equals('Title');
      check(payload.body).equals('Body');
      check(payload.data['key']).equals('value');
      check(payload.isNavigable).isTrue();
    });

    test('fromMap で route や deep_link キーからフォールバック抽出されること', () {
      final payloadRoute = NotificationPayload.fromMap({'route': '/memos'});
      check(payloadRoute.path).equals('/memos');
      check(payloadRoute.isNavigable).isTrue();

      final payloadDeepLink = NotificationPayload.fromMap({
        'deep_link': '/profile',
      });
      check(payloadDeepLink.path).equals('/profile');
      check(payloadDeepLink.isNavigable).isTrue();
    });

    test('fromJson / toJson で相互変換できること', () {
      final json = {
        'path': '/dev-tools',
        'title': 'Test Title',
        'body': 'Test Body',
        'data': {'foo': 'bar'},
      };

      final payload = NotificationPayload.fromJson(json);
      check(payload.path).equals('/dev-tools');
      check(payload.title).equals('Test Title');
      check(payload.body).equals('Test Body');
      check(payload.data['foo']).equals('bar');

      final serialized = payload.toJson();
      check(serialized['path']).equals('/dev-tools');
      check(serialized['title']).equals('Test Title');
      check(serialized['body']).equals('Test Body');
    });

    test('isNavigable が空文字や空白のみの場合は false を返すこと', () {
      const emptyPayload = NotificationPayload(path: '');
      check(emptyPayload.isNavigable).isFalse();

      const whitespacePayload = NotificationPayload(path: '   ');
      check(whitespacePayload.isNavigable).isFalse();
    });
  });
}
