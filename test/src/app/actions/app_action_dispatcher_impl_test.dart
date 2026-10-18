import 'package:checks/checks.dart';
import 'package:flutter_sample/src/app/actions/app_action_dispatcher_impl.dart';
import 'package:flutter_sample/src/app/actions/app_action_overrides.dart';
import 'package:flutter_sample/src/core/actions/app_action_dispatcher.dart';
import 'package:flutter_sample/src/core/services/web_search_service.dart';
import 'package:flutter_sample/src/core/storage/shared_preferences_provider.dart';
import 'package:flutter_sample/src/core/utils/connectivity_provider.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/auth/application/auth_service.dart';
import 'package:flutter_sample/src/features/memos/application/memo_notifier.dart';
import 'package:flutter_sample/src/features/memos/data/memo_repository.dart';
import 'package:flutter_sample/src/features/memos/domain/memo_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talker_flutter/talker_flutter.dart';

class MockTalker extends Mock implements Talker {}

class MockMemoRepository extends Mock implements MemoRepository {}

class MockSharedPreferencesAsync extends Mock
    implements SharedPreferencesAsync {}

class MockWebSearchService extends Mock implements WebSearchService {}

void main() {
  late MockTalker mockTalker;
  late MockMemoRepository mockMemoRepository;
  late MockSharedPreferencesAsync mockPrefs;
  late MockWebSearchService mockWebSearchService;

  setUp(() {
    mockTalker = MockTalker();
    mockMemoRepository = MockMemoRepository();
    mockPrefs = MockSharedPreferencesAsync();
    mockWebSearchService = MockWebSearchService();

    when(
      () => mockPrefs.getString('theme_mode'),
    ).thenAnswer((_) async => 'system');
    when(() => mockPrefs.setString(any(), any())).thenAnswer((_) async {});
    when(
      () => mockMemoRepository.fetchAndMergeRemoteMemos(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockMemoRepository.watchAllMemos(any()),
    ).thenAnswer((_) => Stream.value([]));
  });

  ProviderContainer createContainer({String? userId = 'test_user'}) {
    final container = ProviderContainer(
      overrides: [
        loggerProvider.overrideWithValue(mockTalker),
        currentUserIdProvider.overrideWithValue(userId),
        memoRepositoryProvider.overrideWithValue(mockMemoRepository),
        sharedPreferencesProvider.overrideWithValue(mockPrefs),
        isOnlineProvider.overrideWithValue(false),
        webSearchServiceProvider.overrideWithValue(mockWebSearchService),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('AppActionDispatcherImpl', () {
    test('未対応のアクション名が渡された場合はエラー結果を返すこと', () async {
      final container = createContainer();
      final dispatcher = AppActionDispatcherImpl(container.read(refProvider));

      final result = await dispatcher.execute(name: 'unknown_tool', args: {});

      check(result['status']).equals('error');
      check(result['error']).equals('Unsupported action: unknown_tool');
    });

    group('createMemo', () {
      test('タイトルがnullまたは空文字の場合はエラーを返すこと', () async {
        final container = createContainer();
        final dispatcher = AppActionDispatcherImpl(container.read(refProvider));

        final resultNull = await dispatcher.execute(
          name: 'createMemo',
          args: {'content': '内容のみ'},
        );
        check(resultNull['status']).equals('error');
        check(resultNull['error']).equals('Title is required for createMemo');

        final resultEmpty = await dispatcher.execute(
          name: 'createMemo',
          args: {'title': '   ', 'content': '内容'},
        );
        check(resultEmpty['status']).equals('error');
        check(resultEmpty['error']).equals('Title is required for createMemo');
      });

      test('未ログイン（userIdがnull）の場合はエラーを返すこと', () async {
        final container = createContainer(userId: null);
        final dispatcher = AppActionDispatcherImpl(container.read(refProvider));

        final result = await dispatcher.execute(
          name: 'createMemo',
          args: {'title': '買い物'},
        );

        check(result['status']).equals('error');
        check(result['error']).equals('User is not logged in');
      });

      test('正常系: メモが追加され、成功結果を返すこと', () async {
        when(
          () => mockMemoRepository.addMemo(any(), any(), any()),
        ).thenAnswer((_) async {});

        final container = createContainer();
        final subscription = container.listen(memoProvider, (_, _) {});
        addTearDown(subscription.close);

        final dispatcher = AppActionDispatcherImpl(container.read(refProvider));

        final result = await dispatcher.execute(
          name: 'createMemo',
          args: {'title': '買い物', 'content': '牛乳'},
        );

        check(result['status']).equals('success');
        check(result['title']).equals('買い物');
        verify(
          () => mockMemoRepository.addMemo('買い物', '牛乳', 'test_user'),
        ).called(1);
      });

      test('例外発生時: ロガーにエラーが送信され、エラー結果を返すこと', () async {
        when(
          () => mockMemoRepository.addMemo(any(), any(), any()),
        ).thenThrow(Exception('DB Error'));

        final container = createContainer();
        final subscription = container.listen(memoProvider, (_, _) {});
        addTearDown(subscription.close);

        final dispatcher = AppActionDispatcherImpl(container.read(refProvider));

        final result = await dispatcher.execute(
          name: 'createMemo',
          args: {'title': '買い物'},
        );

        check(result['status']).equals('error');
        check(result['error'].toString()).contains('DB Error');
        verify(
          () => mockTalker.handle(
            any(),
            any(),
            'Failed to create memo via AI tool',
          ),
        ).called(1);
      });
    });

    group('listMemos', () {
      final dummyMemos = <MemoModel>[
        MemoModel(
          id: 'memo_1',
          userId: 'test_user',
          title: 'Flutter学習',
          content: 'Riverpodの復習',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
        MemoModel(
          id: 'memo_2',
          userId: 'test_user',
          title: '買い物リスト',
          content: 'りんご、バナナ',
          createdAt: DateTime(2026, 1, 2),
          updatedAt: DateTime(2026, 1, 2),
        ),
      ];

      test('未ログイン（userIdがnull）の場合はエラーを返すこと', () async {
        final container = createContainer(userId: null);
        final dispatcher = AppActionDispatcherImpl(container.read(refProvider));

        final result = await dispatcher.execute(name: 'listMemos', args: {});

        check(result['status']).equals('error');
        check(result['error']).equals('User is not logged in');
      });

      test('クエリなし: 全メモを取得して返すこと', () async {
        when(
          () => mockMemoRepository.getAllMemos('test_user'),
        ).thenAnswer((_) async => dummyMemos);

        final container = createContainer();
        final dispatcher = AppActionDispatcherImpl(container.read(refProvider));

        final result = await dispatcher.execute(name: 'listMemos', args: {});

        check(result['status']).equals('success');
        check(result['count']).equals(2);
        final memos = result['memos']! as List<Map<String, Object?>>;
        check(memos.length).equals(2);
        check(memos[0]['id']).equals('memo_1');
        check(memos[1]['id']).equals('memo_2');
      });

      test('クエリあり: 部分一致するメモのみに絞り込まれること', () async {
        when(
          () => mockMemoRepository.getAllMemos('test_user'),
        ).thenAnswer((_) async => dummyMemos);

        final container = createContainer();
        final dispatcher = AppActionDispatcherImpl(container.read(refProvider));

        final result = await dispatcher.execute(
          name: 'listMemos',
          args: {'query': 'りんご'},
        );

        check(result['status']).equals('success');
        check(result['count']).equals(1);
        final memos = result['memos']! as List<Map<String, Object?>>;
        check(memos.length).equals(1);
        check(memos[0]['id']).equals('memo_2');
      });

      test('例外発生時: ロガーにエラーが送信され、エラー結果を返すこと', () async {
        when(
          () => mockMemoRepository.getAllMemos('test_user'),
        ).thenThrow(Exception('Network timeout'));

        final container = createContainer();
        final dispatcher = AppActionDispatcherImpl(container.read(refProvider));

        final result = await dispatcher.execute(name: 'listMemos', args: {});

        check(result['status']).equals('error');
        check(result['error'].toString()).contains('Network timeout');
        verify(
          () => mockTalker.handle(
            any(),
            any(),
            'Failed to list memos via AI tool',
          ),
        ).called(1);
      });
    });

    group('changeThemeMode', () {
      test('不正なテーマ文字列の場合はエラーを返すこと', () async {
        final container = createContainer();
        final dispatcher = AppActionDispatcherImpl(container.read(refProvider));

        final result = await dispatcher.execute(
          name: 'changeThemeMode',
          args: {'theme': 'invalid_theme'},
        );

        check(result['status']).equals('error');
        check(result['error'].toString()).contains('Invalid theme');
      });

      test('正常系: dark / light / system を正しく設定できること', () async {
        final container = createContainer();
        final dispatcher = AppActionDispatcherImpl(container.read(refProvider));

        final resultDark = await dispatcher.execute(
          name: 'changeThemeMode',
          args: {'theme': 'dark'},
        );
        check(resultDark['status']).equals('success');
        check(resultDark['theme']).equals('dark');
        verify(() => mockPrefs.setString('theme_mode', 'dark')).called(1);

        final resultLight = await dispatcher.execute(
          name: 'changeThemeMode',
          args: {'theme': 'light'},
        );
        check(resultLight['status']).equals('success');
        check(resultLight['theme']).equals('light');
        verify(() => mockPrefs.setString('theme_mode', 'light')).called(1);

        final resultSystem = await dispatcher.execute(
          name: 'changeThemeMode',
          args: {'theme': 'system'},
        );
        check(resultSystem['status']).equals('success');
        check(resultSystem['theme']).equals('system');
        verify(() => mockPrefs.setString('theme_mode', 'system')).called(1);
      });

      test('例外発生時: ロガーにエラーが送信され、エラー結果を返すこと', () async {
        when(
          () => mockPrefs.setString('theme_mode', 'dark'),
        ).thenThrow(Exception('Prefs error'));

        final container = createContainer();
        final dispatcher = AppActionDispatcherImpl(container.read(refProvider));

        final result = await dispatcher.execute(
          name: 'changeThemeMode',
          args: {'theme': 'dark'},
        );

        check(result['status']).equals('error');
        check(result['error'].toString()).contains('Prefs error');
        verify(
          () => mockTalker.handle(
            any(),
            any(),
            'Failed to change theme mode via AI tool',
          ),
        ).called(1);
      });
    });

    group('searchWeb', () {
      test('クエリがnullまたは空文字の場合はエラーを返すこと', () async {
        final container = createContainer();
        final dispatcher = AppActionDispatcherImpl(container.read(refProvider));

        final resultNull = await dispatcher.execute(
          name: 'searchWeb',
          args: {},
        );
        check(resultNull['status']).equals('error');
        check(resultNull['error']).equals('Query is required for searchWeb');

        final resultEmpty = await dispatcher.execute(
          name: 'searchWeb',
          args: {'query': '   '},
        );
        check(resultEmpty['status']).equals('error');
        check(resultEmpty['error']).equals('Query is required for searchWeb');
      });

      test('正常系: 記事が見つかった場合は結果リストを返すこと', () async {
        when(() => mockWebSearchService.search('Flutter')).thenAnswer(
          (_) async => [
            const WebSearchResult(
              title: 'Flutter',
              snippet: 'Googleが開発したSDK',
              url: 'https://ja.wikipedia.org/wiki/Flutter',
            ),
          ],
        );

        final container = createContainer();
        final dispatcher = AppActionDispatcherImpl(container.read(refProvider));

        final result = await dispatcher.execute(
          name: 'searchWeb',
          args: {'query': 'Flutter'},
        );

        check(result['status']).equals('success');
        check(result['query']).equals('Flutter');
        final results = result['results'] as List<dynamic>?;
        check(results).isNotNull();
        check(results!).length.equals(1);
        final first = results.first as Map<String, Object?>;
        check(first['title']).equals('Flutter');
        check(first['snippet']).equals('Googleが開発したSDK');
        check(first['url']).equals('https://ja.wikipedia.org/wiki/Flutter');
      });

      test('正常系: 記事が見つからなかった（0件）場合は空リストとメッセージを返すこと', () async {
        when(
          () => mockWebSearchService.search('Unknown'),
        ).thenAnswer((_) async => []);

        final container = createContainer();
        final dispatcher = AppActionDispatcherImpl(container.read(refProvider));

        final result = await dispatcher.execute(
          name: 'searchWeb',
          args: {'query': 'Unknown'},
        );

        check(result['status']).equals('success');
        check(result['query']).equals('Unknown');
        final results = result['results'] as List<dynamic>?;
        check(results).isNotNull();
        check(results!).isEmpty();
        check(result['message']).equals('No articles found for "Unknown".');
      });

      test('異常系: 検索サービスが例外をスローした場合はエラー結果を返すこと', () async {
        when(
          () => mockWebSearchService.search(any()),
        ).thenThrow(Exception('Network error'));

        final container = createContainer();
        final dispatcher = AppActionDispatcherImpl(container.read(refProvider));

        final result = await dispatcher.execute(
          name: 'searchWeb',
          args: {'query': 'Flutter'},
        );

        check(result['status']).equals('error');
        check(result['error'].toString()).contains('Network error');
        verify(
          () => mockTalker.handle(
            any(),
            any(),
            'Failed to search web via AI tool',
          ),
        ).called(1);
      });
    });

    group('getAppActionOverrides', () {
      test('appActionDispatcherProvider が正常にオーバーライドされてインスタンスを取得できること', () {
        final container = ProviderContainer(
          overrides: [...getAppActionOverrides().cast()],
        );
        addTearDown(container.dispose);

        final dispatcher = container.read(appActionDispatcherProvider);
        check(dispatcher).isA<AppActionDispatcherImpl>();
      });
    });
  });
}

/// テスト用のダミーRefを提供するプロバイダー
final refProvider = Provider<Ref>((ref) => ref);
