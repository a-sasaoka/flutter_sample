import 'package:checks/checks.dart';
import 'package:dio/dio.dart';
import 'package:flutter_sample/src/core/exceptions/app_exception.dart';
import 'package:flutter_sample/src/core/network/api_client.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/profile/data/profile_repository.dart';
import 'package:flutter_sample/src/features/profile/domain/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker_flutter/talker_flutter.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockTalker extends Mock implements Talker {}

void main() {
  late MockApiClient mockApi;
  late MockTalker mockTalker;
  late ProfileRepository repository;

  setUp(() {
    mockApi = MockApiClient();
    mockTalker = MockTalker();
    repository = ProfileRepository(api: mockApi, talker: mockTalker);
  });

  group('ProfileRepository Tests', () {
    test('profileRepositoryProvider は ProfileRepository を正しく生成すること', () {
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(mockApi),
          loggerProvider.overrideWithValue(mockTalker),
        ],
      );
      addTearDown(container.dispose);

      final repo = container.read(profileRepositoryProvider);

      check(repo).isA<ProfileRepository>();
      check(repo.api).equals(mockApi);
      check(repo.talker).equals(mockTalker);
    });

    const testProfile = UserProfile(
      name: 'テスト太郎',
      email: 'test@example.com',
      displayName: 'タロウ',
      phone: '09012345678',
    );

    group('fetchProfile', () {
      test('GET /users/me が成功した際、UserProfile を返すこと', () async {
        when(() => mockApi.get<Map<String, dynamic>>('/users/me')).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/users/me'),
            data: testProfile.toJson(),
            statusCode: 200,
          ),
        );

        final result = await repository.fetchProfile();

        check(result).equals(testProfile);
      });

      test(
        'GET /users/me レスポンスデータのパースに失敗した際、AppException.dataParse をスローすること',
        () async {
          when(() => mockApi.get<Map<String, dynamic>>('/users/me')).thenAnswer(
            (_) async => Response(
              requestOptions: RequestOptions(path: '/users/me'),
              statusCode: 200,
            ),
          );

          await check(repository.fetchProfile()).throws<AppException>();
        },
      );
    });

    group('updateProfile', () {
      test('PUT /users/me が成功した際、更新後の UserProfile を返すこと', () async {
        when(
          () => mockApi.put<Map<String, dynamic>>(
            '/users/me',
            data: any(named: 'data'),
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/users/me'),
            data: testProfile.toJson(),
            statusCode: 200,
          ),
        );

        final result = await repository.updateProfile(testProfile);

        check(result).equals(testProfile);
      });

      test(
        'PUT /users/me レスポンスデータのパースに失敗した際、AppException.dataParse をスローすること',
        () async {
          when(
            () => mockApi.put<Map<String, dynamic>>(
              '/users/me',
              data: any(named: 'data'),
            ),
          ).thenAnswer(
            (_) async => Response(
              requestOptions: RequestOptions(path: '/users/me'),
              statusCode: 200,
            ),
          );

          await check(
            repository.updateProfile(testProfile),
          ).throws<AppException>();
        },
      );
    });
  });
}
