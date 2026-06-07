import 'dart:async';

import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/src/features/user/data/user_repository.dart';
import 'package:flutter_sample/src/features/user/domain/user_model.dart';
import 'package:flutter_sample/src/features/user/presentation/user_list_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import '../../../core/widgets/widgets_test_helper.dart';

// --- モック定義 ---

void main() {
  late MockAppLocalizations mockL10n;
  late MockUserRepository mockRepository;
  final dummyTimestamp = DateTime(2026, 5, 17, 10, 30);

  setUp(() {
    mockL10n = MockAppLocalizations();
    when(() => mockL10n.userListTitle).thenReturn('User List');
    when(
      () => mockL10n.userListLastFetched(any()),
    ).thenReturn('Last fetched: 2026/05/17 10:30');
    when(() => mockL10n.userListEmpty).thenReturn('No users found.');
    when(() => mockL10n.errorUnknown).thenReturn('Error Occurred');
    when(() => mockL10n.userListFetchError).thenReturn('Pull to refresh');
    when(() => mockL10n.retry).thenReturn('Retry');
    when(() => mockL10n.close).thenReturn('Close');

    mockRepository = MockUserRepository();
  });

  UserModel createDummyUser(int id) {
    return UserModel.fromJson({
      'id': id,
      'name': 'Test User $id',
      'email': 'test$id@example.com',
      'phone': '123-456-7890',
      'website': 'https://example.com',
      'address': {
        'street': 'Test Street',
        'suite': 'Suite $id',
        'city': 'Tokyo',
        'zipcode': '100-0000',
        'geo': {'lat': '35.6895', 'lng': '139.6917'},
      },
    });
  }

  Future<void> pumpUserListScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userRepositoryProvider.overrideWithValue(mockRepository),
        ],
        child: MaterialApp(
          localizationsDelegates: [
            MockLocalizationsDelegate(mockL10n),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const UserListScreen(),
        ),
      ),
    );
  }

  group('UserListScreen Test', () {
    test('コンストラクタのテスト', () {
      const screen = UserListScreen(key: ValueKey<String>('test'));
      check(screen.key).isA<ValueKey<String>>();
    });
    testWidgets('【状態系】Loading状態の時にインジケータが表示されること', (tester) async {
      final completer = Completer<(List<UserModel>, DateTime)>();
      when(
        () => mockRepository.fetchUsers(),
      ).thenAnswer((_) => completer.future);

      await pumpUserListScreen(tester);
      await tester.pump();

      check(find.byType(CircularProgressIndicator)).findsOne();
    });

    testWidgets('【正常系】Data状態でユーザー一覧が正しく表示され、カードをタップできること', (tester) async {
      final dummyUsers = [createDummyUser(1), createDummyUser(2)];
      when(
        () => mockRepository.fetchUsers(),
      ).thenAnswer((_) async => (dummyUsers, dummyTimestamp));

      await pumpUserListScreen(tester);
      await tester.pumpAndSettle();

      check(find.text('User List')).findsOne();
      check(find.text('Last fetched: 2026/05/17 10:30')).findsOne();
      check(find.text('Test User 1')).findsOne();
      check(find.text('test1@example.com')).findsOne();
      check(find.text('Test User 2')).findsOne();
      check(find.byType(Card)).findsExactly(2);

      await tester.tap(find.text('Test User 1'));
      await tester.pumpAndSettle();
    });

    testWidgets('【正常系】データが空の場合、専用の表示がされること', (tester) async {
      when(
        () => mockRepository.fetchUsers(),
      ).thenAnswer((_) async => (<UserModel>[], dummyTimestamp));

      await pumpUserListScreen(tester);
      await tester.pumpAndSettle();

      check(find.text('No users found.')).findsOne();
      check(find.byIcon(Icons.people_outline)).findsOne();
    });

    testWidgets('【正常系】引っ張って更新（Pull-to-Refresh）でデータが再取得されること', (tester) async {
      final dummyUsers = [createDummyUser(1)];

      when(
        () => mockRepository.fetchUsers(),
      ).thenAnswer((_) async => (dummyUsers, dummyTimestamp));
      when(
        () => mockRepository.fetchUsers(forceRefresh: true),
      ).thenAnswer((_) async => (dummyUsers, dummyTimestamp));

      await pumpUserListScreen(tester);
      await tester.pumpAndSettle();

      verify(() => mockRepository.fetchUsers()).called(1);
      clearInteractions(mockRepository);

      await tester.drag(find.byType(ListView), const Offset(0, 500));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      verify(() => mockRepository.fetchUsers(forceRefresh: true)).called(1);
    });

    testWidgets('【異常系】Error状態でエラー文とSnackBarが表示され、再試行ボタンが動作すること', (
      tester,
    ) async {
      final exception = Exception('API Error');
      when(
        () => mockRepository.fetchUsers(),
      ).thenAnswer((_) async => throw exception);

      when(
        () => mockRepository.fetchUsers(forceRefresh: true),
      ).thenAnswer((_) async => (<UserModel>[], dummyTimestamp));

      await pumpUserListScreen(tester);
      await tester.pumpAndSettle();

      check(find.text('Error Occurred')).findsExactly(2);
      check(find.text('Pull to refresh')).findsOne();

      // リトライ実行前に SnackBar を消去して干渉を防ぐ
      ScaffoldMessenger.of(
        tester.element(find.byType(UserListScreen)),
      ).removeCurrentSnackBar();
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      verify(() => mockRepository.fetchUsers(forceRefresh: true)).called(1);
      // リトライ成功後は body のエラー表示が消え、空表示になっていること
      check(
        find.descendant(
          of: find.byType(RefreshIndicator),
          matching: find.byIcon(Icons.error_outline),
        ),
      ).findsNothing();
      check(find.text('No users found.')).findsOne();
    });

    testWidgets('【正常系】データ保持時にエラーが発生した場合でも、以前のリストが表示され続けること', (tester) async {
      final dummyUsers = [createDummyUser(1)];
      when(
        () => mockRepository.fetchUsers(),
      ).thenAnswer((_) async => (dummyUsers, dummyTimestamp));

      await pumpUserListScreen(tester);
      await tester.pumpAndSettle();

      check(find.text('Test User 1')).findsOne();

      when(
        () => mockRepository.fetchUsers(forceRefresh: true),
      ).thenAnswer((_) async => throw Exception('Network Error'));

      await tester.drag(find.byType(ListView), const Offset(0, 500));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      check(find.text('Test User 1')).findsOne();
      check(
        find.descendant(
          of: find.byType(RefreshIndicator),
          matching: find.byIcon(Icons.error_outline),
        ),
      ).findsNothing();
      check(find.byType(SnackBar)).findsNothing();
    });
  });
}
