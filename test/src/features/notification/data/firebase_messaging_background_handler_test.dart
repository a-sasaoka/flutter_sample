import 'package:checks/checks.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_sample/src/features/notification/data/firebase_messaging_background_handler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('firebaseMessagingBackgroundHandler', () {
    test('RemoteMessage を受け取って例外なく完了すること', () async {
      const message = RemoteMessage(
        messageId: 'bg_msg_123',
        data: {'key': 'value'},
      );
      await check(
        firebaseMessagingBackgroundHandler(message),
      ).completes();
    });
  });
}
