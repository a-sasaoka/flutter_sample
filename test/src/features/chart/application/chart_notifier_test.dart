import 'package:checks/checks.dart';
import 'package:flutter_sample/src/core/utils/uuid_provider.dart';
import 'package:flutter_sample/src/features/auth/application/auth_service.dart';
import 'package:flutter_sample/src/features/chart/application/chart_notifier.dart';
import 'package:flutter_sample/src/features/chart/domain/chart_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';

class MockUuid extends Mock implements Uuid {}

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
  late MockUuid mockUuid;

  setUp(() {
    mockUuid = MockUuid();
  });

  ProviderContainer makeProviderContainer() {
    final container = ProviderContainer(
      overrides: [
        uuidProvider.overrideWithValue(mockUuid),
        currentUserIdProvider.overrideWith(
          (ref) => ref.watch(testUserIdProvider),
        ),
        isAuthenticatedProvider.overrideWith(
          (ref) => ref.watch(testAuthNotifierProvider),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('ChartNotifier', () {
    test('初期状態が正しいこと', () {
      final container = makeProviderContainer();
      final state = container.read(chartProvider);

      check(state.items.length).equals(2);
      check(state.chartType).equals(ChartType.line);
    });

    test('グラフの種類を更新できること', () {
      final container = makeProviderContainer();
      container.read(chartProvider.notifier).updateChartType(ChartType.bar);
      check(container.read(chartProvider).chartType).equals(ChartType.bar);
    });

    test('項目を追加できること (UUIDモック使用)', () {
      const generatedId = 'generated-uuid';
      when(() => mockUuid.v4()).thenReturn(generatedId);

      final container = makeProviderContainer();
      container.read(chartProvider.notifier).addItem();

      final items = container.read(chartProvider).items;
      check(items.length).equals(3);
      check(items.last.id).equals(generatedId);
      check(items.last.label).equals('Item3');
      verify(() => mockUuid.v4()).called(1);
    });

    test('項目を削除した後に再度追加してもラベルが重複しないこと', () {
      when(() => mockUuid.v4()).thenReturn('any-uuid');
      final container = makeProviderContainer();
      final id1 = container.read(chartProvider).items.first.id;

      // Item1(id1) を削除 -> 現在は Item2 のみ
      container.read(chartProvider.notifier).removeItem(id1);
      check(container.read(chartProvider).items.length).equals(1);

      // 追加 -> Item2 があるので、次は Item3 になるべき（Item2とは重複しない）
      container.read(chartProvider.notifier).addItem();
      check(container.read(chartProvider).items.length).equals(2);
      check(
        container.read(chartProvider).items.any((i) => i.label == 'Item3'),
      ).equals(true);
    });

    test('項目を削除できること', () {
      final container = makeProviderContainer();
      final firstId = container.read(chartProvider).items.first.id;

      container.read(chartProvider.notifier).removeItem(firstId);
      check(container.read(chartProvider).items.length).equals(1);
      check(
        container.read(chartProvider).items.any((i) => i.id == firstId),
      ).equals(false);
    });

    test('reset: 全ての項目が削除されカウンターがリセットされること', () {
      final container = makeProviderContainer();
      container.read(chartProvider.notifier).reset();

      final state = container.read(chartProvider);
      check(state.items).isEmpty();
      check(state.itemCounter).equals(0);
    });

    test('ラベルを更新できること', () {
      final container = makeProviderContainer();
      final firstId = container.read(chartProvider).items.first.id;

      container.read(chartProvider.notifier).updateLabel(firstId, '更新済み');
      check(container.read(chartProvider).items.first.label).equals('更新済み');
    });

    test('数値を更新できること', () {
      final container = makeProviderContainer();
      final firstId = container.read(chartProvider).items.first.id;

      container.read(chartProvider.notifier).updateValue(firstId, 100.5);
      check(container.read(chartProvider).items.first.value).equals(100.5);
    });

    test('ユーザーID変更時（アカウント切り替え）に入力データが自動リセットされること', () {
      final container = makeProviderContainer();
      // 初期状態ではデフォルト項目が2件ある
      check(container.read(chartProvider).items.length).equals(2);

      // ユーザーIDを変更（アカウント切り替え）
      container.read(testUserIdProvider.notifier).userId = 'new-user';

      // 変更検知によって自律的に reset() され空になっていることを検証
      final state = container.read(chartProvider);
      check(state.items).isEmpty();
      check(state.itemCounter).equals(0);
    });

    test('サインアウト時（isAuthenticatedがfalseへ遷移）に入力データが自動リセットされること', () {
      final container = makeProviderContainer();
      check(container.read(chartProvider).items.length).equals(2);

      // サインアウト
      container.read(testAuthNotifierProvider.notifier).isAuthenticated = false;

      // 変更検知によって自律的に reset() され空になっていることを検証
      final state = container.read(chartProvider);
      check(state.items).isEmpty();
      check(state.itemCounter).equals(0);
    });
  });
}
