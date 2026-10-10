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

    test('updateMemoWidget 実行中に認証状態が変化した場合、 '
        '直列化キューにより updateMemoWidget 完了直後に clearWidgetData が呼び出されること', () async {
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

      // 直列化キューにより、updateMemoWidget が完了するまでは clearWidgetData は待機する
      verifyNever(() => mockService.clearWidgetData());

      // 3. updateMemoWidget が完了
      completer.complete();
      await pumpEventQueue();

      // 直列化キューにより、updateMemoWidget 完了直後に clearWidgetData が確実に呼ばれて空表示に確定する
      verify(() => mockService.clearWidgetData()).called(1);
    });

    test('メモ更新タスクがキュー待機中にアカウント変更が発生した場合、 '
        '実行順が回ってきた際にメモ更新がスキップされ、clearWidgetData のみが実行されること', () async {
      final controller = StreamController<List<MemoModel>>.broadcast();
      final firstMemoCompleter = Completer<void>();
      addTearDown(controller.close);

      when(
        () => mockMemoRepository.watchAllMemos(),
      ).thenAnswer((_) => controller.stream);
      when(
        () => mockService.updateMemoWidget(memos: any(named: 'memos')),
      ).thenAnswer((_) => firstMemoCompleter.future);
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

      final firstMemos = [
        MemoModel(
          id: 'memo-1',
          title: '最初のメモ',
          content: '内容',
          createdAt: DateTime(2026, 9, 27),
          updatedAt: DateTime(2026, 9, 27),
        ),
      ];

      // 1. 最初（タスク1）のメモ更新を開始（completer.future で実行中）
      controller.add(firstMemos);
      await pumpEventQueue();

      // 2. タスク1が実行中の状態で、2つ目（タスク2）のメモ更新をキューに追加
      final secondMemos = [
        MemoModel(
          id: 'memo-2',
          title: '2つ目のメモ',
          content: '内容',
          createdAt: DateTime(2026, 9, 27),
          updatedAt: DateTime(2026, 9, 27),
        ),
      ];
      controller.add(secondMemos);
      await pumpEventQueue();

      // 3. タスク2が待機中の間にアカウント変更が発生
      container.read(testUserIdProvider.notifier).userId = 'another-user';
      container.read(currentUserIdProvider);
      await pumpEventQueue();

      // 4. タスク1を完了させる
      firstMemoCompleter.complete();
      await pumpEventQueue();

      // タスク2は taskGen != _syncGeneration によりスキップされるため、
      // updateMemoWidget は最初の1回しか呼ばれていない
      verify(() => mockService.updateMemoWidget(memos: firstMemos)).called(1);
      verifyNever(() => mockService.updateMemoWidget(memos: secondMemos));

      // clearWidgetData が実行されている
      verify(() => mockService.clearWidgetData()).called(1);
    });

    test('直列化キュー内のタスクがエラーをスローしてもチェーンが破断せず後続のタスクが正常に実行されること', () async {
      when(
        () => mockMemoRepository.watchAllMemos(),
      ).thenAnswer((_) => const Stream.empty());
      var callCount = 0;
      when(() => mockService.clearWidgetData()).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          throw Exception('Simulated widget clear failure');
        }
      });

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

      // 1回目のアカウント変更（例外が発生する）
      container.read(testUserIdProvider.notifier).userId = 'user-2';
      container.read(currentUserIdProvider);
      await pumpEventQueue();

      // 2回目のアカウント変更（破断せず実行されること）
      container.read(testUserIdProvider.notifier).userId = 'user-3';
      container.read(currentUserIdProvider);
      await pumpEventQueue();

      verify(() => mockService.clearWidgetData()).called(2);
    });

    test(
      'アカウント切り替え後に旧ユーザーのメモが通知されても updateMemoWidget が呼ばれないこと（同期停止の維持）',
      () async {
        final controller = StreamController<List<MemoModel>>.broadcast();
        addTearDown(controller.close);

        when(
          () => mockMemoRepository.watchAllMemos(),
        ).thenAnswer((_) => controller.stream);
        when(() => mockService.clearWidgetData()).thenAnswer((_) async {});
        when(
          () => mockService.updateMemoWidget(memos: any(named: 'memos')),
        ).thenAnswer((_) async {});

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

        // 1. 初期ユーザー（user-1）で起動
        container.read(testUserIdProvider.notifier).userId = 'user-1';
        container
          ..listen(memoProvider, (_, _) {})
          ..read(homeWidgetSyncCoordinatorProvider);

        final initialMemos = [
          MemoModel(
            id: 'memo-user1',
            title: 'ユーザー1のメモ',
            content: '内容',
            createdAt: DateTime(2026, 9, 27),
            updatedAt: DateTime(2026, 9, 27),
          ),
        ];

        // ユーザー1のメモは正常に同期される
        controller.add(initialMemos);
        await pumpEventQueue();
        verify(
          () => mockService.updateMemoWidget(memos: initialMemos),
        ).called(1);

        // 2. ユーザー2へアカウントを切り替え
        container.read(testUserIdProvider.notifier).userId = 'user-2';
        container.read(currentUserIdProvider);
        await pumpEventQueue();

        // アカウント切り替えによってウィジェットデータがクリアされる
        verify(() => mockService.clearWidgetData()).called(1);

        // 3. 切り替え後に、SQLiteに残存する旧メモ（ユーザー1のメモ）が通知される
        final oldMemos = [
          MemoModel(
            id: 'memo-user1-old',
            title: '旧ユーザーの残存メモ',
            content: '内容',
            createdAt: DateTime(2026, 9, 27),
            updatedAt: DateTime(2026, 9, 27),
          ),
        ];
        controller.add(oldMemos);
        await pumpEventQueue();

        // 同期が停止されているため、updateMemoWidget は呼ばれないこと
        verifyNever(() => mockService.updateMemoWidget(memos: oldMemos));

        // 4. 新ユーザー（user-2）のメモ確認が完了して同期を再開（未確認の旧メモは書き込まれないこと）
        container
            .read(homeWidgetSyncCoordinatorProvider.notifier)
            .resumeSyncForCurrentUser();
        await pumpEventQueue();

        // 再開処理によって oldMemos が書き込まれていないこと
        verifyNever(() => mockService.updateMemoWidget(memos: oldMemos));

        // 5. 新ユーザーのメモが通知された場合、正常に同期されること
        final newMemos = [
          MemoModel(
            id: 'memo-user2',
            title: 'ユーザー2の新メモ',
            content: '内容',
            createdAt: DateTime(2026, 9, 28),
            updatedAt: DateTime(2026, 9, 28),
          ),
        ];
        controller.add(newMemos);
        await pumpEventQueue();

        verify(() => mockService.updateMemoWidget(memos: newMemos)).called(1);

        // 再開後・新メモ通知後も含めて oldMemos は一度も書き込まれていないこと
        verifyNever(() => mockService.updateMemoWidget(memos: oldMemos));
      },
    );

    test(
      'resumeSyncForCurrentUser に verifiedMemos を渡した場合は直ちにその確認済みメモが同期されること',
      () async {
        when(
          () => mockMemoRepository.watchAllMemos(),
        ).thenAnswer((_) => const Stream.empty());
        when(
          () => mockService.updateMemoWidget(memos: any(named: 'memos')),
        ).thenAnswer((_) async {});

        final container = ProviderContainer(
          overrides: [
            homeWidgetServiceProvider.overrideWithValue(mockService),
            memoRepositoryProvider.overrideWithValue(mockMemoRepository),
            isOnlineProvider.overrideWithValue(false),
            currentUserIdProvider.overrideWith((ref) => 'user-verified'),
            isAuthenticatedProvider.overrideWith((ref) => true),
          ],
        );
        addTearDown(container.dispose);

        final verifiedMemos = [
          MemoModel(
            id: 'memo-verified',
            title: '確認済みメモ',
            content: '内容',
            createdAt: DateTime(2026, 9, 28),
            updatedAt: DateTime(2026, 9, 28),
          ),
        ];

        container
            .read(homeWidgetSyncCoordinatorProvider.notifier)
            .resumeSyncForCurrentUser(verifiedMemos: verifiedMemos);

        await pumpEventQueue();

        verify(
          () => mockService.updateMemoWidget(memos: verifiedMemos),
        ).called(1);
      },
    );

    test('未ログイン状態では resumeSyncForCurrentUser を呼び出しても同期が再開されないこと', () async {
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
          currentUserIdProvider.overrideWith((ref) => null),
          isAuthenticatedProvider.overrideWith((ref) => false),
        ],
      );
      addTearDown(container.dispose);

      container
        ..listen(memoProvider, (_, _) {})
        ..read(
          homeWidgetSyncCoordinatorProvider.notifier,
        ).resumeSyncForCurrentUser();

      await pumpEventQueue();

      final testMemos = [
        MemoModel(
          id: 'memo-unauth',
          title: '未ログイン時のメモ',
          content: '内容',
          createdAt: DateTime(2026, 9, 28),
          updatedAt: DateTime(2026, 9, 28),
        ),
      ];
      controller.add(testMemos);
      await pumpEventQueue();

      verifyNever(
        () => mockService.updateMemoWidget(memos: any(named: 'memos')),
      );
    });

    test(
      '未ログイン状態からログインへ遷移した際、新ユーザーのメモが確認されて同期が自動再開され、updateMemoWidget が呼び出されること',
      () async {
        final controller = StreamController<List<MemoModel>>.broadcast();
        addTearDown(controller.close);

        when(
          () => mockMemoRepository.watchAllMemos(),
        ).thenAnswer((_) => controller.stream);
        when(() => mockService.clearWidgetData()).thenAnswer((_) async {});
        when(
          () => mockService.updateMemoWidget(memos: any(named: 'memos')),
        ).thenAnswer((_) async {});

        final newMemos = [
          MemoModel(
            id: 'memo-login',
            title: 'ログイン後のメモ',
            content: '内容',
            createdAt: DateTime(2026, 9, 28),
            updatedAt: DateTime(2026, 9, 28),
          ),
        ];
        when(
          () => mockMemoRepository.getAllMemos(),
        ).thenAnswer((_) async => newMemos);

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

        // 1. 未ログイン状態で起動
        container.read(testUserIdProvider.notifier).userId = null;
        container.read(testAuthNotifierProvider.notifier).isAuthenticated =
            false;
        container
          ..listen(memoProvider, (_, _) {})
          ..read(homeWidgetSyncCoordinatorProvider);
        await pumpEventQueue();

        // 2. ログイン状態へ遷移（user-new）
        container.read(testUserIdProvider.notifier).userId = 'user-new';
        container.read(testAuthNotifierProvider.notifier).isAuthenticated =
            true;
        container
          ..read(currentUserIdProvider)
          ..read(isAuthenticatedProvider);

        await pumpEventQueue();

        // handleAuthChange によって getAllMemos が呼ばれ、新メモで updateMemoWidget が実行されること
        verify(() => mockMemoRepository.getAllMemos()).called(1);
        verify(() => mockService.updateMemoWidget(memos: newMemos)).called(1);
      },
    );
  });
}
