import 'package:dio/dio.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/chat/domain/chat_action_constants.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker_flutter/talker_flutter.dart';

part 'web_search_service.g.dart';

/// Wikipedia API に関連する定数定義
abstract final class WikipediaApiConstants {
  /// Wikipedia 検索エンドポイント
  static const searchEndpoint = 'https://ja.wikipedia.org/w/api.php';

  /// Wikipedia 記事要約（REST）エンドポイント
  static const summaryEndpoint =
      'https://ja.wikipedia.org/api/rest_v1/page/summary/';

  /// Wikipedia 記事のベースWeb URL
  static const articleBaseUrl = 'https://ja.wikipedia.org/wiki/';

  /// 検索結果の最大取得件数
  static const defaultSearchLimit = 1;

  /// User-Agent ヘッダー名
  static const headerUserAgent = 'User-Agent';

  /// アプリ用 User-Agent 文字列
  static const defaultUserAgent =
      'FlutterSampleApp/1.0 (https://github.com/example/flutter_sample)';

  /// リクエストタイムアウト時間
  static const requestTimeout = Duration(seconds: 10);

  /// アクションパラメータ名 ('action')
  static const paramAction = 'action';

  /// クエリアクション指定値 ('query')
  static const paramActionQuery = 'query';

  /// リストパラメータ名 ('list')
  static const paramList = 'list';

  /// 検索リスト指定値 ('search')
  static const paramListSearch = 'search';

  /// 検索文字列パラメータ名 ('srsearch')
  static const paramSrSearch = 'srsearch';

  /// フォーマットパラメータ名 ('format')
  static const paramFormat = 'format';

  /// JSONフォーマット指定値 ('json')
  static const paramFormatJson = 'json';

  /// UTF-8パラメータ名 ('utf8')
  static const paramUtf8 = 'utf8';

  /// 取得上限数パラメータ名 ('srlimit')
  static const paramSrLimit = 'srlimit';

  /// クエリオブジェクトキー ('query')
  static const fieldQuery = 'query';

  /// 検索結果配列キー ('search')
  static const fieldSearch = 'search';

  /// 記事タイトルキー ('title')
  static const fieldTitle = 'title';

  /// スニペットキー ('snippet')
  static const fieldSnippet = 'snippet';

  /// 要約テキストキー ('extract')
  static const fieldExtract = 'extract';

  /// コンテンツURLキー ('content_urls')
  static const fieldContentUrls = 'content_urls';

  /// デスクトップURLキー ('desktop')
  static const fieldDesktop = 'desktop';

  /// ページURLキー ('page')
  static const fieldPage = 'page';
}

/// Web検索（Wikipedia）の1件あたりの検索結果
class WebSearchResult {
  /// コンストラクタ
  const WebSearchResult({
    required this.title,
    required this.snippet,
    required this.url,
  });

  /// 記事タイトル
  final String title;

  /// 要約・スニペット文
  final String snippet;

  /// 記事のWeb URL
  final String url;

  /// AIへの戻り値用のMapに変換する
  Map<String, Object?> toMap() => {
    SearchWebActionKeys.title: title,
    SearchWebActionKeys.snippet: snippet,
    SearchWebActionKeys.url: url,
  };
}

/// Wikipedia API を利用したWeb検索サービスクラス
class WebSearchService {
  /// コンストラクタ
  WebSearchService({required Dio dio, required Talker logger})
    : _dio = dio,
      _logger = logger;

  final Dio _dio;
  final Talker _logger;

  /// 指定したクエリで検索し、最も関連性の高い結果を返す
  Future<List<WebSearchResult>> search(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      return const [];
    }

    try {
      // 1. Wikipedia検索APIでキーワードに合致する記事を検索（上位1件）
      final searchResponse = await _dio.get<Map<String, dynamic>>(
        WikipediaApiConstants.searchEndpoint,
        queryParameters: {
          WikipediaApiConstants.paramAction:
              WikipediaApiConstants.paramActionQuery,
          WikipediaApiConstants.paramList:
              WikipediaApiConstants.paramListSearch,
          WikipediaApiConstants.paramSrSearch: trimmedQuery,
          WikipediaApiConstants.paramFormat:
              WikipediaApiConstants.paramFormatJson,
          WikipediaApiConstants.paramUtf8: 1,
          WikipediaApiConstants.paramSrLimit:
              WikipediaApiConstants.defaultSearchLimit,
        },
        options: Options(
          headers: {
            WikipediaApiConstants.headerUserAgent:
                WikipediaApiConstants.defaultUserAgent,
          },
        ),
      );

      final searchData = searchResponse.data;
      if (searchData == null) {
        return const [];
      }

      final queryMap =
          searchData[WikipediaApiConstants.fieldQuery] as Map<String, dynamic>?;
      final searchList =
          queryMap?[WikipediaApiConstants.fieldSearch] as List<dynamic>?;
      if (searchList == null || searchList.isEmpty) {
        return const [];
      }

      final firstItem = searchList.first as Map<String, dynamic>;
      final title =
          firstItem[WikipediaApiConstants.fieldTitle] as String? ?? '';
      if (title.isEmpty) {
        return const [];
      }

      // 2. 記事の要約（summary）APIを取得してきれいな要約文とURLを取得
      try {
        final summaryUrl =
            '${WikipediaApiConstants.summaryEndpoint}'
            '${Uri.encodeComponent(title)}';
        final summaryResponse = await _dio.get<Map<String, dynamic>>(
          summaryUrl,
          options: Options(
            headers: {
              WikipediaApiConstants.headerUserAgent:
                  WikipediaApiConstants.defaultUserAgent,
            },
          ),
        );
        final summaryData = summaryResponse.data;
        if (summaryData != null) {
          final extract =
              summaryData[WikipediaApiConstants.fieldExtract] as String? ?? '';
          final contentUrls =
              summaryData[WikipediaApiConstants.fieldContentUrls]
                  as Map<String, dynamic>?;
          final desktop =
              contentUrls?[WikipediaApiConstants.fieldDesktop]
                  as Map<String, dynamic>?;
          final fallbackUrl =
              '${WikipediaApiConstants.articleBaseUrl}'
              '${Uri.encodeComponent(title)}';
          final pageUrl =
              desktop?[WikipediaApiConstants.fieldPage] as String? ??
              fallbackUrl;

          return [
            WebSearchResult(
              title: title,
              snippet: extract.isNotEmpty
                  ? extract
                  : _cleanSnippet(
                      firstItem[WikipediaApiConstants.fieldSnippet]
                              as String? ??
                          '',
                    ),
              url: pageUrl,
            ),
          ];
        }
      } on DioException catch (e, st) {
        _logger.warning(
          'Failed to fetch Wikipedia summary for $title, fallback to snippet: '
          '$e',
          e,
          st,
        );
      }

      // フォールバック: 検索APIのsnippetを利用
      final rawSnippet =
          firstItem[WikipediaApiConstants.fieldSnippet] as String? ?? '';
      final fallbackUrl =
          '${WikipediaApiConstants.articleBaseUrl}'
          '${Uri.encodeComponent(title)}';
      return [
        WebSearchResult(
          title: title,
          snippet: _cleanSnippet(rawSnippet),
          url: fallbackUrl,
        ),
      ];
    } on Exception catch (e, st) {
      _logger.handle(
        e,
        st,
        'Failed to execute Wikipedia search for query: $trimmedQuery',
      );
      rethrow;
    }
  }

  /// HTMLタグ（例: <span class="searchmatch">...</span>）を除去するヘルパー
  String _cleanSnippet(String rawSnippet) {
    return rawSnippet.replaceAll(RegExp('<[^>]*>'), '').trim();
  }
}

/// [WebSearchService] を提供するプロバイダー
@Riverpod(keepAlive: true)
WebSearchService webSearchService(Ref ref) {
  final logger = ref.watch(loggerProvider);
  final dio = Dio(
    BaseOptions(
      connectTimeout: WikipediaApiConstants.requestTimeout,
      receiveTimeout: WikipediaApiConstants.requestTimeout,
      sendTimeout: WikipediaApiConstants.requestTimeout,
    ),
  );
  return WebSearchService(dio: dio, logger: logger);
}
