import 'package:checks/checks.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/notification/data/push_notification_service.dart';
import 'package:flutter_sample/src/features/notification/data/push_notification_service_provider.dart';
import 'package:flutter_sample/src/features/notification/domain/notification_payload.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker_flutter/talker_flutter.dart';

class MockTalker extends Mock implements Talker {}

void main() {
  test(
    'pushNotificationServiceProvider が PushNotificationService インスタンスを提供すること',
    () {
      final mockTalker = MockTalker();
      final container = ProviderContainer(
        overrides: [
          loggerProvider.overrideWithValue(mockTalker),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(pushNotificationServiceProvider);
      check(service).isA<PushNotificationService>();
      check(service.channelName).isNotEmpty();
      check(service.channelDescription).isNotEmpty();
      check(service.defaultTitle).isNotEmpty();

      // onNotificationTap コールバックの実行をテスト
      const payload = NotificationPayload(title: 'Test', body: 'Test Body');
      service.onNotificationTap?.call(payload);
    },
  );
}
