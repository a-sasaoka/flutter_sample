import 'package:checks/checks.dart';
import 'package:dio/dio.dart';
import 'package:flutter_sample/src/core/exceptions/app_exception.dart';
import 'package:flutter_sample/src/core/network/api_client.dart';
import 'package:flutter_sample/src/features/memos/data/memo_remote_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}

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
        (_) async => Response(
          requestOptions: RequestOptions(path: '/memos'),
        ),
      );

      final result = await service.fetchMemos();
      check(result).isEmpty();
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
        (_) async => Response(
          requestOptions: RequestOptions(path: '/memos/memo1'),
        ),
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
        (_) async => Response(
          requestOptions: RequestOptions(path: '/memos'),
        ),
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

    test(
      'uploadMemo: PUTが404エラー（responseがnullでe.errorがAppExceptionの場合） '
      'でも、POSTが呼ばれること',
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

        when(
          () => mockApiClient.post<void>('/memos', data: memoData),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '/memos'),
          ),
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
      },
    );

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
  });

  group('memoRemoteServiceProvider', () {
    test('Provider経由でMemoRemoteServiceのインスタンスを取得できること', () {
      final mockApiClient = MockApiClient();
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(mockApiClient),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(memoRemoteServiceProvider);
      check(service).isA<MemoRemoteService>();
    });
  });
}
