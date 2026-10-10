import 'dart:async';

import 'package:flutter_sample/src/core/utils/connectivity_provider.dart';
import 'package:flutter_sample/src/features/auth/application/auth_service.dart';
import 'package:flutter_sample/src/features/home_widget/application/home_widget_service.dart';
import 'package:flutter_sample/src/features/home_widget/application/home_widget_sync_coordinator.dart';
import 'package:flutter_sample/src/features/memos/application/memo_notifier.dart';
import 'package:flutter_sample/src/features/memos/data/memo_repository.dart';
import 'package:flutter_sample/src/features/memos/domain/memo_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

class MockHomeWidgetService extends Mock implements HomeWidgetService {}

class MockMemoRepository extends Mock implements MemoRepository {}

class TestUserIdNotifier extends Notifier<String?> {
  @override
  String? build() => 'initial-user';
  String? get userId => state;
  set userId(String? id) => state = id;
}

final testUserIdProvider = NotifierProvider<TestUserIdNotifier, String?>(
  TestUserIdNotifier.new,
);

class TestAuthNotifier extends Notifier<bool> {
  @override
  bool build() => true;
  bool get isAuthenticated => state;
  set isAuthenticated(bool value) => state = value;
}

final testAuthNotifierProvider = NotifierProvider<TestAuthNotifier, bool>(
  TestAuthNotifier.new,
);

void main() {
  group('HomeWidgetSyncCoordinator', () {
    late MockHomeWidgetService mockService;
    late MockMemoRepository mockMemoRepository;

    setUp(() {
      mockService = MockHomeWidgetService();
      mockMemoRepository = MockMemoRepository();

      when(() => mockService.initialize()).thenAnswer((_) async {});
      when(
        () => mockService.updateMemoWidget(memos: any(named: 'memos')),
      ).thenAnswer((_) async {});
      when(
        () => mockMemoRepository.fetchAndMergeRemoteMemos(),
      ).thenAnswer((_) async {});
    });

    test('初期化時に service.initialize() が呼び出されること', () async {
      when(
        () => mockMemoRepository.watchAllMemos(),
      ).thenAnswer((_) => const Stream.empty());

      final container = ProviderContainer(
        overrides: [
          homeWidgetServiceProvider.overrideWithValue(mockService),
          memoRepositoryProvider.overrideWithValue(mockMemoRepository),
          isOnlineProvider.overrideWithValue(false),
        ],
      );
      addTearDown(container.dispose);

      container.read(homeWidgetSyncCoordinatorProvider);

      verify(() => mockService.initialize()).called(1);
    });

    test(
      'memoProvider から新しいメモ一覧（AsyncData）が通知されたとき updateMemoWidget が呼ばれること',
      () async {
        final controller = StreamController<List<MemoModel>>.broadcast();
        addTearDown(controller.close);

        when(
          () => mockMemoRepository.watchAllMemos(),
        ).thenAnswer((_) => controller.stream);

        final container = ProviderContainer(
          overrides: [
            homeWidgetServiceProvider.overrideWithValue(mockService),
            memoRepositoryProvider.overrideWithValue(mockMemoRepository),
            isOnlineProvider.overrideWithValue(false),
            isAuthenticatedProvider.overrideWithValue(true),
          ],
        );
        addTearDown(container.dispose);

        // AutoDisposeプロバイダーの早期破棄を防ぐため listen しておく
        container
          ..listen(memoProvider, (_, _) {})
          ..read(homeWidgetSyncCoordinatorProvider);

        final testMemos = [
          MemoModel(
            id: 'memo-1',
            title: 'テスト',
            content: '内容',
            createdAt: DateTime(2026, 9, 27),
            updatedAt: DateTime(2026, 9, 27),
          ),
        ];

        // データを流す
        controller.add(testMemos);

        // 非同期イベントの処理を待機
        await pumpEventQueue();

        verify(() => mockService.updateMemoWidget(memos: testMemos)).called(1);
      },
    );

    test('未ログイン状態（isAuthenticated が false）のときは memoProvider が更新されても '
        'updateMemoWidget が呼ばれないこと', () async {
      final controller = StreamController<List<MemoModel>>.broadcast();
      addTearDown(controller.close);

      when(
        () => mockMemoRepository.watchAllMemos(),
      ).thenAnswer((_) => controller.stream);

      final container = ProviderContainer(
        overrides: [
          homeWidgetServiceProvider.overrideWithValue(mockService),
          memoRepositoryProvider.overrideWithValue(mockMemoRepository),
          isOnlineProvider.overrideWithValue(false),
          isAuthenticatedProvider.overrideWithValue(false),
        ],
      );
      addTearDown(container.dispose);

      container
        ..listen(memoProvider, (_, _) {})
        ..read(homeWidgetSyncCoordinatorProvider);

      final testMemos = [
        MemoModel(
          id: 'memo-1',
          title: 'テスト',
          content: '内容',
          createdAt: DateTime(2026, 9, 27),
          updatedAt: DateTime(2026, 9, 27),
        ),
      ];

      controller.add(testMemos);
      await pumpEventQueue();

      verifyNever(
        () => mockService.updateMemoWidget(memos: any(named: 'memos')),
      );
    });

    test(
      'currentUserIdProvider の変化（アカウント切り替え）時に clearWidgetData が呼ばれること',
      () async {
        when(
          () => mockMemoRepository.watchAllMemos(),
        ).thenAnswer((_) => const Stream.empty());
        when(() => mockService.clearWidgetData()).thenAnswer((_) async {});

        final container = ProviderContainer(
          overrides: [
            homeWidgetServiceProvider.overrideWithValue(mockService),
            memoRepositoryProvider.overrideWithValue(mockMemoRepository),
            isOnlineProvider.overrideWithValue(false),
            currentUserIdProvider.overrideWith(
              (ref) => ref.watch(testUserIdProvider),
            ),
            isAuthenticatedProvider.overrideWith(
              (ref) => ref.watch(testAuthNotifierProvider),
            ),
          ],
        );
        addTearDown(container.dispose);

        container.read(homeWidgetSyncCoordinatorProvider);

        // ユーザーIDを変更（アカウント切り替え）
        container.read(testUserIdProvider.notifier).userId = 'changed-user';
        container.read(currentUserIdProvider);

        await pumpEventQueue();

        verify(() => mockService.clearWidgetData()).called(1);
      },
    );

    test(
      'isAuthenticatedProvider の変化（ログアウト）時に clearWidgetData が呼ばれること',
      () async {
        when(
          () => mockMemoRepository.watchAllMemos(),
        ).thenAnswer((_) => const Stream.empty());
        when(() => mockService.clearWidgetData()).thenAnswer((_) async {});

        final container = ProviderContainer(
          overrides: [
            homeWidgetServiceProvider.overrideWithValue(mockService),
            memoRepositoryProvider.overrideWithValue(mockMemoRepository),
            isOnlineProvider.overrideWithValue(false),
            currentUserIdProvider.overrideWith(
              (ref) => ref.watch(testUserIdProvider),
            ),
            isAuthenticatedProvider.overrideWith(
              (ref) => ref.watch(testAuthNotifierProvider),
            ),
          ],
        );
        addTearDown(container.dispose);

        container.read(homeWidgetSyncCoordinatorProvider);

        // ログアウト（isAuthenticated: false）
        container.read(testAuthNotifierProvider.notifier).isAuthenticated =
            false;
        container.read(isAuthenticatedProvider);

        await pumpEventQueue();

        verify(() => mockService.clearWidgetData()).called(1);
      },
    );

    test('currentUserIdProvider と isAuthenticatedProvider が同時に変化した際にも '
        'clearWidgetData が1回だけ呼ばれること', () async {
      when(
        () => mockMemoRepository.watchAllMemos(),
      ).thenAnswer((_) => const Stream.empty());
      when(() => mockService.clearWidgetData()).thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [
          homeWidgetServiceProvider.overrideWithValue(mockService),
          memoRepositoryProvider.overrideWithValue(mockMemoRepository),
          isOnlineProvider.overrideWithValue(false),
          currentUserIdProvider.overrideWith(
            (ref) => ref.watch(testUserIdProvider),
          ),
          isAuthenticatedProvider.overrideWith(
            (ref) => ref.watch(testAuthNotifierProvider),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(homeWidgetSyncCoordinatorProvider);

      // 同時に変化
      container.read(testUserIdProvider.notifier).userId = null;
      container.read(testAuthNotifierProvider.notifier).isAuthenticated = false;
      container
        ..read(currentUserIdProvider)
        ..read(isAuthenticatedProvider);

      await pumpEventQueue();

      verify(() => mockService.clearWidgetData()).called(1);
    });

    test(
      'updateMemoWidget 実行中に認証状態が変化した場合、Fencing により clearWidgetData が呼び出されること',
      () async {
        final controller = StreamController<List<MemoModel>>.broadcast();
        final completer = Completer<void>();
        addTearDown(controller.close);

        when(
          () => mockMemoRepository.watchAllMemos(),
        ).thenAnswer((_) => controller.stream);
        when(
          () => mockService.updateMemoWidget(memos: any(named: 'memos')),
        ).thenAnswer((_) => completer.future);
        when(() => mockService.clearWidgetData()).thenAnswer((_) async {});

        final container = ProviderContainer(
          overrides: [
            homeWidgetServiceProvider.overrideWithValue(mockService),
            memoRepositoryProvider.overrideWithValue(mockMemoRepository),
            isOnlineProvider.overrideWithValue(false),
            currentUserIdProvider.overrideWith(
              (ref) => ref.watch(testUserIdProvider),
            ),
            isAuthenticatedProvider.overrideWith(
              (ref) => ref.watch(testAuthNotifierProvider),
            ),
          ],
        );
        addTearDown(container.dispose);

        container
          ..listen(memoProvider, (_, _) {})
          ..read(homeWidgetSyncCoordinatorProvider);

        final testMemos = [
          MemoModel(
            id: 'memo-1',
            title: 'テスト',
            content: '内容',
            createdAt: DateTime(2026, 9, 27),
            updatedAt: DateTime(2026, 9, 27),
          ),
        ];

        // 1. メモ更新を開始（completer.future により未完了状態）
        controller.add(testMemos);
        await pumpEventQueue();

        // 2. 更新の最中にアカウント変更が発生
        container.read(testUserIdProvider.notifier).userId = 'another-user';
        container.read(currentUserIdProvider);
        await pumpEventQueue();

        // アカウント変更によって1回目の clearWidgetData が呼ばれている
        verify(() => mockService.clearWidgetData()).called(1);

        // 3. 遅れて最初の updateMemoWidget が完了
        completer.complete();
        await pumpEventQueue();

        // Fencing により、世代不一致を検知して再度 clearWidgetData が呼ばれ、上書きを防止
        verify(() => mockService.clearWidgetData()).called(1);
      },
    );
  });
}
