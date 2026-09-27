import 'dart:async';

import 'package:flutter_sample/src/core/utils/connectivity_provider.dart';
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
  });
}
