import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/features/user/data/user_repository.dart';
import 'package:flutter_sample/src/features/user/domain/user_model.dart';
import 'package:flutter_sample/src/features/user/presentation/user_list_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

// --- モック定義 ---

class MockAppLocalizations extends Mock implements AppLocalizations {}

class MockUserRepository extends Mock implements UserRepository {}

class _MockLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _MockLocalizationsDelegate(this.mock);
  final MockAppLocalizations mock;
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<AppLocalizations> load(Locale locale) async => mock;
  @override
  bool shouldReload(covariant _) => false;
}

void main() {
  late MockAppLocalizations mockL10n;
  late MockUserRepository mockRepository;

  setUp(() {
    mockL10n = MockAppLocalizations();
    when(() => mockL10n.userListTitle).thenReturn('User List');
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
            _MockLocalizationsDelegate(mockL10n),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: UserListScreen(key: GlobalKey()),
        ),
      ),
    );
  }

  group('UserListScreen Test', () {
    test('コンストラクタのテスト', () {
      // ignore: prefer_const_constructors, 100%カバレッジのために意図的にconstを外している
      final screen = UserListScreen(key: const ValueKey<String>('test'));
      expect(screen.key, isA<ValueKey<String>>());
    });
    testWidgets('【状態系】Loading状態の時にインジケータが表示されること', (tester) async {
      final completer = Completer<List<UserModel>>();
      when(
        () => mockRepository.fetchUsers(),
      ).thenAnswer((_) => completer.future);

      await pumpUserListScreen(tester);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('【正常系】Data状態でユーザー一覧が正しく表示され、カードをタップできること', (tester) async {
      final dummyUsers = [createDummyUser(1), createDummyUser(2)];
      when(
        () => mockRepository.fetchUsers(),
      ).thenAnswer((_) async => dummyUsers);

      await pumpUserListScreen(tester);
      await tester.pumpAndSettle();

      expect(find.text('User List'), findsOneWidget);
      expect(find.text('Test User 1'), findsOneWidget);
      expect(find.text('test1@example.com'), findsOneWidget);
      expect(find.text('Test User 2'), findsOneWidget);
      expect(find.byType(Card), findsNWidgets(2));

      // カードをタップ（カバレッジ用）
      await tester.tap(find.text('Test User 1'));
      await tester.pumpAndSettle();
    });

    testWidgets('【正常系】データが空の場合、専用の表示がされること', (tester) async {
      when(() => mockRepository.fetchUsers()).thenAnswer((_) async => []);

      await pumpUserListScreen(tester);
      await tester.pumpAndSettle();

      expect(find.text('No users found.'), findsOneWidget);
      expect(find.byIcon(Icons.people_outline), findsOneWidget);
    });

    testWidgets('【正常系】引っ張って更新（Pull-to-Refresh）でデータが再取得されること', (tester) async {
      final dummyUsers = [createDummyUser(1)];

      when(
        () => mockRepository.fetchUsers(),
      ).thenAnswer((_) async => dummyUsers);
      when(
        () => mockRepository.fetchUsers(forceRefresh: true),
      ).thenAnswer((_) async => dummyUsers);

      await pumpUserListScreen(tester);
      await tester.pumpAndSettle();

      verify(() => mockRepository.fetchUsers()).called(1);
      clearInteractions(mockRepository);

      // 💡 UIから確実にリフレッシュをトリガーする
      await tester.drag(find.byType(ListView), const Offset(0, 500));
      await tester.pump(); // ドラッグ開始
      await tester.pump(const Duration(seconds: 1)); // アニメーション
      await tester.pumpAndSettle(); // 処理完了を待つ

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
      ).thenAnswer((_) async => []);

      await pumpUserListScreen(tester);
      await tester.pumpAndSettle();

      expect(
        find.text('Error Occurred'),
        findsNWidgets(2),
      ); // SnackBar & Screen
      expect(find.text('Pull to refresh'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
      await tester.pumpAndSettle();

      verify(() => mockRepository.fetchUsers(forceRefresh: true)).called(1);
    });
  });
}
