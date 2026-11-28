import 'dart:convert';
import 'dart:typed_data';

import 'package:checks/checks.dart';
import 'package:dio/dio.dart';
import 'package:flutter_sample/src/core/exceptions/app_exception.dart';
import 'package:flutter_sample/src/core/exceptions/reauth_exception.dart';
import 'package:flutter_sample/src/core/network/api_client.dart';
import 'package:flutter_sample/src/core/network/dio_interceptor.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/profile/data/profile_repository.dart';
import 'package:flutter_sample/src/features/profile/domain/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker_flutter/talker_flutter.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockTalker extends Mock implements Talker {}

class _StubHttpClientAdapter implements HttpClientAdapter {
  _StubHttpClientAdapter(this._onFetch);

  final Future<ResponseBody> Function(RequestOptions options) _onFetch;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => _onFetch(options);

  @override
  void close({bool force = false}) {}
}

void main() {
  setUpAll(() {
    registerFallbackValue(StackTrace.current);
    registerFallbackValue(const AppException.dataParse());
  });

  late MockApiClient mockApi;
  late MockTalker mockTalker;
  late ProfileRepository repository;

  setUp(() {
    mockApi = MockApiClient();
    mockTalker = MockTalker();
    when(() => mockTalker.debug(any<dynamic>())).thenReturn(null);
    when(
      () =>
          mockTalker.handle(any<Object>(), any<StackTrace?>(), any<dynamic>()),
    ).thenReturn(null);
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
        'GET /users/me レスポンスデータが null (not Map) の際、AppException.dataParse をスローすること',
        () async {
          when(() => mockApi.get<Map<String, dynamic>>('/users/me')).thenAnswer(
            (_) async => Response(
              requestOptions: RequestOptions(path: '/users/me'),
              statusCode: 200,
            ),
          );

          await check(repository.fetchProfile()).throws<DataParseException>();
          verify(
            () => mockTalker.handle(
              const AppException.dataParse(),
              any<StackTrace>(),
              any<String>(that: contains('Failed to parse profile data')),
            ),
          ).called(1);
        },
      );

      test(
        'GET /users/me レスポンスデータが Map だが不正な型を含む際、AppException.dataParse をスローし実際の例外をログすること',
        () async {
          when(() => mockApi.get<Map<String, dynamic>>('/users/me')).thenAnswer(
            (_) async => Response(
              requestOptions: RequestOptions(path: '/users/me'),
              data: {'name': 12345}, // name が String ではなく int
              statusCode: 200,
            ),
          );

          await check(repository.fetchProfile()).throws<DataParseException>();
          verify(
            () => mockTalker.handle(
              any<Object>(),
              any<StackTrace>(),
              any<String>(that: contains('Failed to parse UserProfile')),
            ),
          ).called(1);
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
          ).throws<DataParseException>();
          verify(
            () => mockTalker.handle(
              const AppException.dataParse(),
              any<StackTrace>(),
              any<String>(
                that: contains('Failed to parse updated profile data'),
              ),
            ),
          ).called(1);
        },
      );
    });

    group('deleteMyAccountData', () {
      test('DELETE /users/me が成功した際、正常に完了すること', () async {
        when(() => mockApi.delete<void>('/users/me')).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/users/me'),
            statusCode: 200,
          ),
        );

        await check(repository.deleteMyAccountData()).completes();

        verify(() => mockApi.delete<void>('/users/me')).called(1);
      });

      test('DELETE /users/me が失敗した際、例外がそのまま再スローされること', () async {
        when(
          () => mockApi.delete<void>('/users/me'),
        ).thenThrow(const AppException.server(statusCode: 500));

        await check(repository.deleteMyAccountData()).throws<ServerException>();
      });

      test(
        'DELETE /users/me が 403 (requires-recent-login) を返した場合、 '
        'DioInterceptor 経由でも ReauthRequiresRecentLoginException を投げること',
        () async {
          final adapter = _StubHttpClientAdapter(
            (_) async => ResponseBody.fromString(
              jsonEncode(const {'code': 'requires-recent-login'}),
              403,
              headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType],
              },
            ),
          );
          final container = ProviderContainer(
            overrides: [loggerProvider.overrideWithValue(mockTalker)],
          );
          addTearDown(container.dispose);

          final dio = Dio(BaseOptions(baseUrl: 'https://test.example.com'))
            ..httpClientAdapter = adapter
            ..interceptors.add(container.read(dioInterceptorProvider));
          final wiredRepo = ProfileRepository(
            api: DioApiClient(dio),
            talker: mockTalker,
          );

          await check(
            wiredRepo.deleteMyAccountData(),
          ).throws<ReauthRequiresRecentLoginException>();
          verify(() => mockTalker.warning(any<dynamic>())).called(1);
        },
      );

      test('DELETE /users/me が通常の 403 (requires-recent-login 以外) を返した場合、 '
          'UnauthorizedException のまま再スローされること', () async {
        final adapter = _StubHttpClientAdapter(
          (_) async => ResponseBody.fromString(
            jsonEncode(const {'error': 'Forbidden'}),
            403,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          ),
        );
        final container = ProviderContainer(
          overrides: [loggerProvider.overrideWithValue(mockTalker)],
        );
        addTearDown(container.dispose);

        final dio = Dio(BaseOptions(baseUrl: 'https://test.example.com'))
          ..httpClientAdapter = adapter
          ..interceptors.add(container.read(dioInterceptorProvider));
        final wiredRepo = ProfileRepository(
          api: DioApiClient(dio),
          talker: mockTalker,
        );

        await check(wiredRepo.deleteMyAccountData()).throws<DioException>(
          (e) => e
            ..has((x) => x.error, 'error').isA<UnauthorizedException>()
            ..has((x) => x.response?.statusCode, 'statusCode').equals(403),
        );
      });
    });
  });
}
