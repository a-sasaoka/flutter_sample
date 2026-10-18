import 'package:checks/checks.dart';
import 'package:dio/dio.dart';
import 'package:flutter_sample/src/core/services/web_search_service.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/chat/domain/chat_action_constants.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker_flutter/talker_flutter.dart';

class MockDio extends Mock implements Dio {}

class MockTalker extends Mock implements Talker {}

void main() {
  late MockDio mockDio;
  late MockTalker mockTalker;
  late WebSearchService service;

  setUp(() {
    mockDio = MockDio();
    mockTalker = MockTalker();
    service = WebSearchService(dio: mockDio, logger: mockTalker);
  });

  group('WebSearchResult', () {
    test('toMap: 正しいMap表現に変換できること', () {
      const result = WebSearchResult(
        title: 'Flutter',
        snippet: 'Googleが開発したUI SDK',
        url: 'https://ja.wikipedia.org/wiki/Flutter',
      );

      final map = result.toMap();

      check(map[SearchWebActionKeys.title]).equals('Flutter');
      check(map[SearchWebActionKeys.snippet]).equals('Googleが開発したUI SDK');
      check(
        map[SearchWebActionKeys.url],
      ).equals('https://ja.wikipedia.org/wiki/Flutter');
    });
  });

  group('WebSearchService.search', () {
    test('クエリが空文字または空白の場合はAPIリクエストを行わずに空リストを返すこと', () async {
      final resultEmpty = await service.search('');
      final resultWhitespace = await service.search('   ');

      check(resultEmpty).isEmpty();
      check(resultWhitespace).isEmpty();
      verifyNever(
        () => mockDio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      );
    });

    test('正常系: 検索結果が見つかりsummary APIから要約とURLを取得できること', () async {
      when(
        () => mockDio.get<Map<String, dynamic>>(
          WikipediaApiConstants.searchEndpoint,
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(
            path: WikipediaApiConstants.searchEndpoint,
          ),
          data: {
            'query': {
              'search': [
                {
                  'title': 'Flutter',
                  'snippet':
                      '<span class="searchmatch">Flutter</span>はUIツールキットです',
                },
              ],
            },
          },
        ),
      );

      when(
        () => mockDio.get<Map<String, dynamic>>(
          '${WikipediaApiConstants.summaryEndpoint}Flutter',
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(
            path: '${WikipediaApiConstants.summaryEndpoint}Flutter',
          ),
          data: {
            'extract': 'FlutterはGoogleによって開発されたオープンソースUIツールキットである。',
            'content_urls': {
              'desktop': {'page': 'https://ja.wikipedia.org/wiki/Flutter'},
            },
          },
        ),
      );

      final results = await service.search('Flutter');

      check(results).length.equals(1);
      final first = results.first;
      check(first.title).equals('Flutter');
      check(first.snippet).equals('FlutterはGoogleによって開発されたオープンソースUIツールキットである。');
      check(first.url).equals('https://ja.wikipedia.org/wiki/Flutter');
    });

    test('検索結果のレスポンスdataがnullの場合は空リストを返すこと', () async {
      when(
        () => mockDio.get<Map<String, dynamic>>(
          WikipediaApiConstants.searchEndpoint,
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(
            path: WikipediaApiConstants.searchEndpoint,
          ),
        ),
      );

      final results = await service.search('Flutter');

      check(results).isEmpty();
    });

    test('検索結果のリストが空（0件）の場合は空リストを返すこと', () async {
      when(
        () => mockDio.get<Map<String, dynamic>>(
          WikipediaApiConstants.searchEndpoint,
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(
            path: WikipediaApiConstants.searchEndpoint,
          ),
          data: {
            'query': {'search': <dynamic>[]},
          },
        ),
      );

      final results = await service.search('nonexistent_query_xyz');

      check(results).isEmpty();
    });

    test('検索結果のtitleが空の場合は空リストを返すこと', () async {
      when(
        () => mockDio.get<Map<String, dynamic>>(
          WikipediaApiConstants.searchEndpoint,
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(
            path: WikipediaApiConstants.searchEndpoint,
          ),
          data: {
            'query': {
              'search': [
                {'title': '', 'snippet': '何か'},
              ],
            },
          },
        ),
      );

      final results = await service.search('empty_title');

      check(results).isEmpty();
    });

    test('summary APIがDioExceptionをスローした場合は検索snippetでフォールバックすること', () async {
      when(
        () => mockDio.get<Map<String, dynamic>>(
          WikipediaApiConstants.searchEndpoint,
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(
            path: WikipediaApiConstants.searchEndpoint,
          ),
          data: {
            'query': {
              'search': [
                {
                  'title': 'Dart',
                  'snippet': '<span class="searchmatch">Dart</span>は言語です。',
                },
              ],
            },
          },
        ),
      );

      when(
        () => mockDio.get<Map<String, dynamic>>(
          '${WikipediaApiConstants.summaryEndpoint}Dart',
          options: any(named: 'options'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: 'summary'),
          error: 'Summary 404',
        ),
      );

      final results = await service.search('Dart');

      check(results).length.equals(1);
      final first = results.first;
      check(first.title).equals('Dart');
      check(first.snippet).equals('Dartは言語です。');
      check(first.url).equals('https://ja.wikipedia.org/wiki/Dart');
      verify(
        () => mockTalker.warning(
          any<dynamic>(),
          any<Object?>(),
          any<StackTrace?>(),
        ),
      ).called(1);
    });

    test('summary APIのextractが空文字の場合は検索snippetでフォールバックすること', () async {
      when(
        () => mockDio.get<Map<String, dynamic>>(
          WikipediaApiConstants.searchEndpoint,
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(
            path: WikipediaApiConstants.searchEndpoint,
          ),
          data: {
            'query': {
              'search': [
                {
                  'title': 'EmptyExtract',
                  'snippet': '<p><span class="searchmatch">タグ付き</span>テキスト</p>',
                },
              ],
            },
          },
        ),
      );

      when(
        () => mockDio.get<Map<String, dynamic>>(
          '${WikipediaApiConstants.summaryEndpoint}EmptyExtract',
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: 'summary'),
          data: {
            'extract': '',
            'content_urls': {
              'desktop': {'page': 'https://ja.wikipedia.org/wiki/EmptyExtract'},
            },
          },
        ),
      );

      final results = await service.search('EmptyExtract');

      check(results).length.equals(1);
      final first = results.first;
      check(first.title).equals('EmptyExtract');
      check(first.snippet).equals('タグ付きテキスト');
      check(first.url).equals('https://ja.wikipedia.org/wiki/EmptyExtract');
    });

    test('検索API自体が例外をスローした場合はlogger.handleを呼び出してrethrowすること', () async {
      final exception = DioException(
        requestOptions: RequestOptions(path: 'search'),
        error: 'Network failure',
      );

      when(
        () => mockDio.get<Map<String, dynamic>>(
          WikipediaApiConstants.searchEndpoint,
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        ),
      ).thenThrow(exception);

      await check(service.search('fail_query')).throws<DioException>();

      verify(
        () => mockTalker.handle(
          exception,
          any<StackTrace?>(),
          'Failed to execute Wikipedia search for query: fail_query',
        ),
      ).called(1);
    });
  });

  group('webSearchServiceProvider', () {
    test('ProviderContainerからWebSearchServiceを正常に取得できること', () {
      final container = ProviderContainer(
        overrides: [loggerProvider.overrideWithValue(mockTalker)],
      );
      addTearDown(container.dispose);

      final searchService = container.read(webSearchServiceProvider);

      check(searchService).isA<WebSearchService>();
    });
  });
}
