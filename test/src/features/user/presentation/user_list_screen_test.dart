import 'dart:async';

import 'package:flutter/material.dart';
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
    when(() => mockL10n.errorUnknown).thenReturn('Error Occurred');
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
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // 本物の UserNotifier を動かしつつ、裏側の通信(Repository)だけを偽物にする
          userRepositoryProvider.overrideWithValue(mockRepository),
        ],
        child: MaterialApp(
          localizationsDelegates: [_MockLocalizationsDelegate(mockL10n)],
          home: const UserListScreen(),
        ),
      ),
    );
  }

  group('UserListScreen Test', () {
    testWidgets('【状態系】Loading状態の時にインジケータが表示されること', (tester) async {
      // Arrange
      final completer = Completer<List<UserModel>>();
      // 通信が「終わらない」状態（Completer）を返すことで Loading 状態を再現
      when(
        () => mockRepository.fetchUsers(),
      ).thenAnswer((_) => completer.future);

      // Act
      await pumpUserListScreen(tester);

      await tester.pump();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('【正常系】Data状態でユーザー一覧が正しく表示されること', (tester) async {
      // Arrange
      final dummyUsers = [createDummyUser(1), createDummyUser(2)];
      when(
        () => mockRepository.fetchUsers(),
      ).thenAnswer((_) async => dummyUsers);

      // Act
      await pumpUserListScreen(tester);
      await tester.pumpAndSettle(); // 通信完了と画面描画を待つ

      // Assert
      expect(find.text('User List'), findsOneWidget);
      expect(find.byType(ListTile), findsNWidgets(2));
      expect(find.text('Test User 1'), findsOneWidget);
    });

    testWidgets('【正常系】引っ張って更新（Pull-to-Refresh）でデータが再取得されること', (tester) async {
      // Arrange
      final dummyUsers = [createDummyUser(1)];

      // 初回表示用（引数なし）のモック
      when(
        () => mockRepository.fetchUsers(),
      ).thenAnswer((_) async => dummyUsers);

      // 引っ張って更新用（forceRefresh: true）のモック
      when(
        () => mockRepository.fetchUsers(forceRefresh: true),
      ).thenAnswer((_) async => dummyUsers);

      await pumpUserListScreen(tester);
      await tester.pumpAndSettle();

      // 初回の画面表示時の通信が呼ばれたことを確認し、カウントをリセットする
      verify(() => mockRepository.fetchUsers()).called(1);
      clearInteractions(mockRepository);

      // Act: リストを上から下へスワイプして「引っ張って更新」を再現！
      await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
      await tester.pumpAndSettle();

      // Assert: ref.refresh が呼ばれ、裏側で「確実に forceRefresh: true の通信が」走ったことを検証
      verify(() => mockRepository.fetchUsers(forceRefresh: true)).called(1);
    });

    testWidgets('【異常系】Error状態でエラー文とSnackBarが表示されること', (tester) async {
      // Arrange
      final exception = Exception('API Error');
      // 例外を投げてエラー状態を再現
      when(
        () => mockRepository.fetchUsers(),
      ).thenAnswer((_) async => throw exception);

      // Act
      await pumpUserListScreen(tester);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Error Occurred'), findsNWidgets(2)); // 画面中央とスナックバーのエラー文
      expect(find.byType(SnackBar), findsOneWidget); // ref.listen によるスナックバー
    });
  });
}
