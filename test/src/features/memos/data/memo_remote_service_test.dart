import 'dart:typed_data';

import 'package:checks/checks.dart';
import 'package:dio/dio.dart';
import 'package:flutter_sample/src/core/exceptions/app_exception.dart';
import 'package:flutter_sample/src/core/network/api_client.dart';
import 'package:flutter_sample/src/core/network/dio_interceptor.dart';
import 'package:flutter_sample/src/core/network/dio_provider.dart';
import 'package:flutter_sample/src/core/network/request_auth_pin.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/auth/data/token_interceptor.dart';
import 'package:flutter_sample/src/features/auth/data/token_storage.dart';
import 'package:flutter_sample/src/features/memos/data/memo_remote_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker_flutter/talker_flutter.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockTokenStorage extends Mock implements TokenStorage {}

class _RecordingHttpClientAdapter implements HttpClientAdapter {
  _RecordingHttpClientAdapter(this._onFetch);

  final Future<ResponseBody> Function(RequestOptions options) _onFetch;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return _onFetch(options);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('MemoRemoteService', () {
    late MockApiClient mockApiClient;
    late MemoRemoteService service;

    setUp(() {
      mockApiClient = MockApiClient();
      service = MemoRemoteService(mockApiClient);
    });

    test('fetchMemos: 正常系', () async {
      final now = DateTime(2026, 5, 2);
      final mockData = [
        {
          'id': 'memo1',
          'title': 'テストタイトル',
          'content': 'テストコンテンツ',
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
          'isDeleted': false,
        },
      ];

      when(() => mockApiClient.get<List<dynamic>>('/memos')).thenAnswer(
        (_) async => Response(
          data: mockData,
          requestOptions: RequestOptions(path: '/memos'),
        ),
      );

      final result = await service.fetchMemos();

      check(result.length).equals(1);
      check(result.first['id']).equals('memo1');
      check(result.first['title']).equals('テストタイトル');
      check(result.first['content']).equals('テストコンテンツ');
      check(result.first['createdAt']).equals(now);
      check(result.first['updatedAt']).equals(now);
      check(result.first['isDeleted']).equals(false);

      verify(() => mockApiClient.get<List<dynamic>>('/memos')).called(1);
    });

    test('fetchMemos: データがnullの場合、空のリストを返すこと', () async {
      when(() => mockApiClient.get<List<dynamic>>('/memos')).thenAnswer(
        (_) async => Response(requestOptions: RequestOptions(path: '/memos')),
      );

      final result = await service.fetchMemos();
      check(result).isEmpty();
    });

    test('fetchMemos: 日付が不正な形式の場合はパースをスキップし、元の文字列を保持すること', () async {
      final mockData = [
        {
          'id': 'memo1',
          'title': 'テストタイトル',
          'content': 'テストコンテンツ',
          'createdAt': 'invalid-date-string',
          'updatedAt': 'invalid-date-string',
          'isDeleted': false,
        },
      ];

      when(() => mockApiClient.get<List<dynamic>>('/memos')).thenAnswer(
        (_) async => Response(
          data: mockData,
          requestOptions: RequestOptions(path: '/memos'),
        ),
      );

      final result = await service.fetchMemos();

      check(result.length).equals(1);
      check(result.first['createdAt']).equals('invalid-date-string');
      check(result.first['updatedAt']).equals('invalid-date-string');
    });

    test('uploadMemo: PUTが成功した場合、POSTは呼ばれないこと', () async {
      final now = DateTime(2026, 5, 2);
      final memoData = {
        'id': 'memo1',
        'title': 'タイトル',
        'content': 'コンテンツ',
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'isDeleted': false,
      };

      when(
        () => mockApiClient.put<void>('/memos/memo1', data: memoData),
      ).thenAnswer(
        (_) async =>
            Response(requestOptions: RequestOptions(path: '/memos/memo1')),
      );

      await service.uploadMemo(
        id: 'memo1',
        title: 'タイトル',
        content: 'コンテンツ',
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
      );

      verify(
        () => mockApiClient.put<void>('/memos/memo1', data: memoData),
      ).called(1);
      verifyNever(
        () => mockApiClient.post<void>(any(), data: any(named: 'data')),
      );
    });

    test('uploadMemo: PUTが404エラーの場合、POSTが呼ばれること', () async {
      final now = DateTime(2026, 5, 2);
      final memoData = {
        'id': 'memo1',
        'title': 'タイトル',
        'content': 'コンテンツ',
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'isDeleted': false,
      };

      // PUTの段階で404エラーをスローさせる
      when(
        () => mockApiClient.put<void>('/memos/memo1', data: memoData),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/memos/memo1'),
          response: Response(
            statusCode: 404,
            requestOptions: RequestOptions(path: '/memos/memo1'),
          ),
        ),
      );

      when(() => mockApiClient.post<void>('/memos', data: memoData)).thenAnswer(
        (_) async => Response(requestOptions: RequestOptions(path: '/memos')),
      );

      await service.uploadMemo(
        id: 'memo1',
        title: 'タイトル',
        content: 'コンテンツ',
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
      );

      verify(
        () => mockApiClient.put<void>('/memos/memo1', data: memoData),
      ).called(1);
      verify(
        () => mockApiClient.post<void>('/memos', data: memoData),
      ).called(1);
    });

    test('uploadMemo: PUTが404エラー（responseがnullでe.errorがAppExceptionの場合） '
        'でも、POSTが呼ばれること', () async {
      final now = DateTime(2026, 5, 2);
      final memoData = {
        'id': 'memo1',
        'title': 'タイトル',
        'content': 'コンテンツ',
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'isDeleted': false,
      };

      // responseがnullで、errorにAppException.badRequest(statusCode: 404)が
      // 入った状態をシミュレートします
      when(
        () => mockApiClient.put<void>('/memos/memo1', data: memoData),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/memos/memo1'),
          error: const AppException.badRequest(statusCode: 404),
        ),
      );

      when(() => mockApiClient.post<void>('/memos', data: memoData)).thenAnswer(
        (_) async => Response(requestOptions: RequestOptions(path: '/memos')),
      );

      await service.uploadMemo(
        id: 'memo1',
        title: 'タイトル',
        content: 'コンテンツ',
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
      );

      verify(
        () => mockApiClient.put<void>('/memos/memo1', data: memoData),
      ).called(1);
      verify(
        () => mockApiClient.post<void>(any(), data: any(named: 'data')),
      ).called(1);
    });

    test('uploadMemo: PUTが404以外のエラーの場合、例外がそのままスローされること', () async {
      final now = DateTime(2026, 5, 2);
      final memoData = {
        'id': 'memo1',
        'title': 'タイトル',
        'content': 'コンテンツ',
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'isDeleted': false,
      };

      when(
        () => mockApiClient.put<void>('/memos/memo1', data: memoData),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/memos/memo1'),
          response: Response(
            statusCode: 500,
            requestOptions: RequestOptions(path: '/memos/memo1'),
          ),
        ),
      );

      await check(
        service.uploadMemo(
          id: 'memo1',
          title: 'タイトル',
          content: 'コンテンツ',
          createdAt: now,
          updatedAt: now,
          isDeleted: false,
        ),
      ).throws<DioException>();

      verify(
        () => mockApiClient.put<void>('/memos/memo1', data: memoData),
      ).called(1);
      verifyNever(
        () => mockApiClient.post<void>(any(), data: any(named: 'data')),
      );
    });

    test('uploadMemo: IDに特殊文字が含まれる場合、URLエンコードされたパスでPUTされること', () async {
      final now = DateTime(2026, 5, 2);
      final memoData = {
        'id': 'memo 1',
        'title': 'タイトル',
        'content': 'コンテンツ',
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'isDeleted': false,
      };

      when(
        () => mockApiClient.put<void>('/memos/memo%201', data: memoData),
      ).thenAnswer(
        (_) async =>
            Response(requestOptions: RequestOptions(path: '/memos/memo%201')),
      );

      await service.uploadMemo(
        id: 'memo 1',
        title: 'タイトル',
        content: 'コンテンツ',
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
      );

      verify(
        () => mockApiClient.put<void>('/memos/memo%201', data: memoData),
      ).called(1);
    });

    test(
      'uploadMemo: expectedUserId指定時はPUTと404後POSTで同一のRequestAuthPinが渡されること',
      () async {
        final now = DateTime(2026, 5, 2);
        final memoData = {
          'id': 'memo1',
          'title': 'タイトル',
          'content': 'コンテンツ',
          'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String(),
          'isDeleted': false,
        };
        Options? putOptions;
        Options? postOptions;

        when(
          () => mockApiClient.put<void>(
            '/memos/memo1',
            data: memoData,
            options: any(named: 'options'),
          ),
        ).thenAnswer((invocation) async {
          putOptions = invocation.namedArguments[#options] as Options?;
          throw DioException(
            requestOptions: RequestOptions(path: '/memos/memo1'),
            response: Response(
              statusCode: 404,
              requestOptions: RequestOptions(path: '/memos/memo1'),
            ),
          );
        });
        when(
          () => mockApiClient.post<void>(
            '/memos',
            data: memoData,
            options: any(named: 'options'),
          ),
        ).thenAnswer((invocation) async {
          postOptions = invocation.namedArguments[#options] as Options?;
          return Response(requestOptions: RequestOptions(path: '/memos'));
        });

        await service.uploadMemo(
          id: 'memo1',
          title: 'タイトル',
          content: 'コンテンツ',
          createdAt: now,
          updatedAt: now,
          isDeleted: false,
          expectedUserId: 'user-a',
        );

        final putPin =
            putOptions?.extra?[RequestAuthPin.extraKey] as RequestAuthPin?;
        final postPin =
            postOptions?.extra?[RequestAuthPin.extraKey] as RequestAuthPin?;
        check(putPin).isNotNull();
        check(putPin?.expectedUserId).equals('user-a');
        check(identical(putPin, postPin)).isTrue();
      },
    );
  });

  group('TokenInterceptor連携時の認証情報固定', () {
    late MockTokenStorage mockStorage;
    late Talker quietTalker;

    setUp(() {
      mockStorage = MockTokenStorage();
      quietTalker = Talker(
        settings: TalkerSettings(useConsoleLogs: false, useHistory: false),
      );
    });

    (MemoRemoteService, ProviderContainer) createWiredService({
      required List<(String method, String path, String? authHeader)> sentLog,
      required Future<ResponseBody> Function(RequestOptions options) onFetch,
      Future<bool> Function()? refreshCallback,
    }) {
      final adapter = _RecordingHttpClientAdapter((options) async {
        sentLog.add((
          options.method,
          options.path,
          options.headers['Authorization'] as String?,
        ));
        return await onFetch(options);
      });

      late ProviderContainer container;
      final baseDio = Dio(BaseOptions(baseUrl: 'https://example.com'))
        ..httpClientAdapter = adapter;
      container = ProviderContainer(
        overrides: [
          loggerProvider.overrideWithValue(quietTalker),
          tokenStorageInternalProvider.overrideWithValue(mockStorage),
          baseDioProvider.overrideWithValue(baseDio),
          tokenRefreshCallbackProvider.overrideWithValue(
            refreshCallback ?? () async => false,
          ),
        ],
      );
      baseDio.interceptors.add(container.read(dioInterceptorProvider));

      final mainDio = Dio(BaseOptions(baseUrl: 'https://example.com'))
        ..httpClientAdapter = adapter
        ..interceptors.addAll([
          container.read(tokenInterceptorProvider),
          container.read(dioInterceptorProvider),
        ]);
      return (MemoRemoteService(DioApiClient(mainDio)), container);
    }

    test('PUTが404を返した後に別ユーザーへ切り替わっても、後続POSTは元のユーザーの固定トークンで送信されること', () async {
      var currentUserId = 'user-a';
      var currentToken = 'token-a';
      when(
        () => mockStorage.getUserId(),
      ).thenAnswer((_) async => currentUserId);
      when(
        () => mockStorage.getAccessToken(),
      ).thenAnswer((_) async => currentToken);

      final sentLog = <(String, String, String?)>[];
      final (wiredService, container) = createWiredService(
        sentLog: sentLog,
        onFetch: (options) async {
          if (options.method == 'PUT') {
            // PUT の 404 応答時〜POST 送信前に別ユーザーへ切り替わる
            currentUserId = 'user-b';
            currentToken = 'token-b';
            return ResponseBody.fromString('', 404);
          }
          return ResponseBody.fromString('', 200);
        },
      );
      addTearDown(container.dispose);

      final now = DateTime(2026, 5, 2);
      await wiredService.uploadMemo(
        id: 'memo1',
        title: 'タイトル',
        content: '内容',
        createdAt: now,
        updatedAt: now,
        isDeleted: false,
        expectedUserId: 'user-a',
      );

      check(sentLog).deepEquals([
        ('PUT', '/memos/memo1', 'Bearer token-a'),
        ('POST', '/memos', 'Bearer token-a'),
      ]);
      // POST ではトークンストレージを再参照していないこと
      verify(() => mockStorage.getAccessToken()).called(1);
    });

    test('認証情報取得前に別ユーザーへ切り替わっていた場合、HTTP送信を行わず拒否すること', () async {
      when(() => mockStorage.getUserId()).thenAnswer((_) async => 'user-b');
      when(
        () => mockStorage.getAccessToken(),
      ).thenAnswer((_) async => 'token-b');

      final sentLog = <(String, String, String?)>[];
      final (wiredService, container) = createWiredService(
        sentLog: sentLog,
        onFetch: (_) async => ResponseBody.fromString('', 200),
      );
      addTearDown(container.dispose);

      final now = DateTime(2026, 5, 2);
      await check(
        wiredService.uploadMemo(
          id: 'memo1',
          title: 'タイトル',
          content: '内容',
          createdAt: now,
          updatedAt: now,
          isDeleted: false,
          expectedUserId: 'user-a',
        ),
      ).throws<DioException>();

      check(sentLog).isEmpty();
      verifyNever(() => mockStorage.getAccessToken());
    });

    test(
      '401発生後に別ユーザーへ切り替わった場合は再試行せず、同一ユーザー時のみ新トークンで404後POSTも継続できること',
      () async {
        var currentUserId = 'user-a';
        var currentToken = 'expired-token-a';
        var refreshCalls = 0;
        when(
          () => mockStorage.getUserId(),
        ).thenAnswer((_) async => currentUserId);
        when(
          () => mockStorage.getAccessToken(),
        ).thenAnswer((_) async => currentToken);

        // 1. 401応答中に別ユーザーへ切り替わるケース → リフレッシュも再試行もされない
        final blockedLog = <(String, String, String?)>[];
        final (blockedService, blockedContainer) = createWiredService(
          sentLog: blockedLog,
          refreshCallback: () async {
            refreshCalls++;
            return true;
          },
          onFetch: (_) async {
            currentUserId = 'user-b';
            currentToken = 'token-b';
            return ResponseBody.fromString('', 401);
          },
        );
        addTearDown(blockedContainer.dispose);

        final now = DateTime(2026, 5, 2);
        await check(
          blockedService.uploadMemo(
            id: 'memo1',
            title: 'タイトル',
            content: '内容',
            createdAt: now,
            updatedAt: now,
            isDeleted: false,
            expectedUserId: 'user-a',
          ),
        ).throws<DioException>();

        check(
          blockedLog,
        ).deepEquals([('PUT', '/memos/memo1', 'Bearer expired-token-a')]);
        check(refreshCalls).equals(0);

        // 2. 同一ユーザーで401→リフレッシュ成功→PUTリトライ404→別ユーザー切替→POSTが新トークンAを使うケース
        currentUserId = 'user-a';
        currentToken = 'expired-token-a';
        var putAttempts = 0;
        final refreshedLog = <(String, String, String?)>[];
        final (refreshedService, refreshedContainer) = createWiredService(
          sentLog: refreshedLog,
          refreshCallback: () async {
            refreshCalls++;
            currentToken = 'new-token-a';
            return true;
          },
          onFetch: (options) async {
            if (options.method == 'PUT') {
              putAttempts++;
              if (putAttempts == 1) {
                return ResponseBody.fromString('', 401);
              }
              // 再試行後のPUTが404を返し、その後別ユーザーへ切り替わる
              currentUserId = 'user-b';
              currentToken = 'token-b';
              return ResponseBody.fromString('', 404);
            }
            return ResponseBody.fromString('', 200);
          },
        );
        addTearDown(refreshedContainer.dispose);

        await refreshedService.uploadMemo(
          id: 'memo1',
          title: 'タイトル',
          content: '内容',
          createdAt: now,
          updatedAt: now,
          isDeleted: false,
          expectedUserId: 'user-a',
        );

        check(refreshCalls).equals(1);
        check(refreshedLog).deepEquals([
          ('PUT', '/memos/memo1', 'Bearer expired-token-a'),
          ('PUT', '/memos/memo1', 'Bearer new-token-a'),
          ('POST', '/memos', 'Bearer new-token-a'),
        ]);
      },
    );
  });

  group('memoRemoteServiceProvider', () {
    test('Provider経由でMemoRemoteServiceのインスタンスを取得できること', () {
      final mockApiClient = MockApiClient();
      final container = ProviderContainer(
        overrides: [apiClientProvider.overrideWithValue(mockApiClient)],
      );
      addTearDown(container.dispose);

      final service = container.read(memoRemoteServiceProvider);
      check(service).isA<MemoRemoteService>();
    });
  });
}
