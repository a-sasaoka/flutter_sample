import 'dart:convert';

import 'package:checks/checks.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_sample/src/core/config/update_request_provider.dart';
import 'package:flutter_sample/src/core/config/update_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:talker_flutter/talker_flutter.dart';

class MockFirebaseRemoteConfig extends Mock implements FirebaseRemoteConfig {}

class MockPackageInfo extends Mock implements PackageInfo {}

class MockTalker extends Mock implements Talker {}

void main() {
  group('UpdateService', () {
    late MockFirebaseRemoteConfig mockRemoteConfig;
    late MockPackageInfo mockPackageInfo;
    late MockTalker mockTalker;
    late DateTime fixedNow;

    setUp(() {
      mockRemoteConfig = MockFirebaseRemoteConfig();
      mockPackageInfo = MockPackageInfo();
      mockTalker = MockTalker();
      fixedNow = DateTime(2026, 5, 10);
    });

    UpdateService createService() {
      return UpdateService(
        remoteConfig: mockRemoteConfig,
        packageInfo: mockPackageInfo,
        getCurrentDateTime: () => fixedNow,
        talker: mockTalker,
      );
    }

    test('update_info が空の場合、UpdateRequestType.not を返すこと', () async {
      when(() => mockRemoteConfig.getString('update_info')).thenReturn('');
      final service = createService();

      final result = await service.getUpdateRequestType();

      check(result).equals(UpdateRequestType.not);
    });

    test('新バージョンがあり、かつ有効期限を過ぎている場合、適切な種別を返すこと', () async {
      // 1.1.0 が要求されている。現在は 1.0.0。
      final updateInfo = {
        'requiredVersion': '1.1.0',
        'enabledAt': '2026-05-01T00:00:00Z',
        'canCancel': false,
      };
      when(
        () => mockRemoteConfig.getString('update_info'),
      ).thenReturn(json.encode(updateInfo));
      when(() => mockPackageInfo.version).thenReturn('1.0.0');

      final service = createService();
      final result = await service.getUpdateRequestType();

      check(result).equals(UpdateRequestType.forcibly);
    });

    test('新バージョンがあり、有効期限を過ぎているが、キャンセル可能な場合', () async {
      final updateInfo = {
        'requiredVersion': '1.1.0',
        'enabledAt': '2026-05-01T00:00:00Z',
        'canCancel': true,
      };
      when(
        () => mockRemoteConfig.getString('update_info'),
      ).thenReturn(json.encode(updateInfo));
      when(() => mockPackageInfo.version).thenReturn('1.0.0');

      final service = createService();
      final result = await service.getUpdateRequestType();

      check(result).equals(UpdateRequestType.cancelable);
    });

    test('新バージョンがあるが、有効期限前の場合、UpdateRequestType.not を返すこと', () async {
      final updateInfo = {
        'requiredVersion': '1.1.0',
        'enabledAt': '2026-05-20T00:00:00Z', // 未来の日時
        'canCancel': false,
      };
      when(
        () => mockRemoteConfig.getString('update_info'),
      ).thenReturn(json.encode(updateInfo));
      when(() => mockPackageInfo.version).thenReturn('1.0.0');

      final service = createService();
      final result = await service.getUpdateRequestType();

      check(result).equals(UpdateRequestType.not);
    });

    test('バージョンが同じか古い場合、UpdateRequestType.not を返すこと', () async {
      final updateInfo = {
        'requiredVersion': '1.0.0',
        'enabledAt': '2026-05-01T00:00:00Z',
        'canCancel': false,
      };
      when(
        () => mockRemoteConfig.getString('update_info'),
      ).thenReturn(json.encode(updateInfo));
      when(() => mockPackageInfo.version).thenReturn('1.0.0');

      final service = createService();
      final result = await service.getUpdateRequestType();

      check(result).equals(UpdateRequestType.not);
    });

    test('JSONのパースに失敗した場合、例外をキャッチして not を返し、警告ログを出すこと', () async {
      when(
        () => mockRemoteConfig.getString('update_info'),
      ).thenReturn('invalid-json');
      final service = createService();

      final result = await service.getUpdateRequestType();

      check(result).equals(UpdateRequestType.not);
      verify(
        () => mockTalker.warning(any<String>(that: contains('Failed'))),
      ).called(1);
    });
  });
}
