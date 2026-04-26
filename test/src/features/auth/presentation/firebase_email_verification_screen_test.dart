// ignore_for_file: use_setters_to_change_properties, document_ignores

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/utils/app_lifecycle_provider.dart';
import 'package:flutter_sample/src/features/auth/application/firebase_auth_state_notifier.dart';
import 'package:flutter_sample/src/features/auth/data/firebase_auth_repository.dart';
import 'package:flutter_sample/src/features/auth/presentation/firebase_email_verification_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseAuthRepository extends Mock
    implements FirebaseAuthRepository {}

class MockUser extends Mock implements User {}

class MockAppLocalizations extends Mock implements AppLocalizations {}

class _MockLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _MockLocalizationsDelegate(this.mock);
  final MockAppLocalizations mock;
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<AppLocalizations> load(Locale locale) async => mock;
  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}

class FakeFirebaseAuthStateNotifier extends FirebaseAuthStateNotifier {
  FakeFirebaseAuthStateNotifier(this.initialState);
  final User? initialState;

  @override
  User? build() => initialState;

  void updateState(User? newUser) {
    state = newUser;
  }
}

class FakeAppLifecycle extends AppLifecycle {
  @override
  // テスト開始時は「バックグラウンド（paused）にいる」という設定にしておきます
  AppLifecycleState build() => AppLifecycleState.paused;

  // テストコードから好きなタイミングで状態を変えるためのメソッド
  void updateState(AppLifecycleState newState) {
    state = newState;
  }
}

void main() {
  late MockFirebaseAuthRepository mockAuthRepo;
  late MockUser mockUser;
  late MockAppLocalizations mockL10n;

  setUp(() {
    mockAuthRepo = MockFirebaseAuthRepository();
    mockUser = MockUser();
    mockL10n = MockAppLocalizations();

    when(() => mockL10n.emailVerificationTitle).thenReturn('メール認証');
    when(
      () => mockL10n.emailVerificationDescription,
    ).thenReturn('確認メールを送信しました。');
    when(() => mockL10n.resendVerificationMail).thenReturn('再送信する');
    when(() => mockL10n.emailVerificationWaiting).thenReturn('認証待ちです...');
    when(() => mockL10n.checkVerificationStatus).thenReturn('認証を完了したか確認する');
    when(() => mockL10n.errorUnknown).thenReturn('予期しないエラーが発生しました。');
    when(() => mockL10n.close).thenReturn('閉じる');
    when(
      () => mockL10n.resendVerificationMailSuccess,
    ).thenReturn('確認メールを再送信しました'); // 👈 成功メッセージ用

    when(() => mockAuthRepo.sendEmailVerification()).thenAnswer((_) async {});
    when(() => mockAuthRepo.reloadCurrentUser()).thenAnswer((_) async {});
  });

  Widget createTestWidget(ProviderContainer container) {
    final router = GoRouter(
      initialLocation: '/verify',
      routes: [
        GoRoute(
          path: '/verify',
          builder: (context, state) => const FirebaseEmailVerificationScreen(),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Text('Navigated to ${state.uri}'),
      ),
    );

    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: [_MockLocalizationsDelegate(mockL10n)],
      ),
    );
  }

  group('FirebaseEmailVerificationScreen', () {
    testWidgets('UIが正しくレンダリングされること', (tester) async {
      when(() => mockUser.emailVerified).thenReturn(false);

      final container = ProviderContainer(
        overrides: [
          firebaseAuthRepositoryProvider.overrideWithValue(mockAuthRepo),
          firebaseAuthStateProvider.overrideWith(
            () => FakeFirebaseAuthStateNotifier(mockUser),
          ),
        ],
      );

      await tester.pumpWidget(createTestWidget(container));
      await tester.pumpAndSettle();

      expect(find.text('メール認証'), findsOneWidget);
      expect(find.text('確認メールを送信しました。'), findsOneWidget);
      expect(find.text('認証を完了したか確認する'), findsOneWidget);
      expect(find.text('認証待ちです...'), findsOneWidget);
    });

    testWidgets('手動確認ボタンタップ時、ローディング表示になりリロード処理が呼ばれること', (tester) async {
      when(() => mockUser.emailVerified).thenReturn(false);

      // ローディング中の状態（CircularProgressIndicator）をテストするために、
      // 処理が完了するまでに意図的に少しだけ遅延させる
      when(() => mockAuthRepo.reloadCurrentUser()).thenAnswer(
        (_) async => Future.delayed(const Duration(milliseconds: 100)),
      );

      final container = ProviderContainer(
        overrides: [
          firebaseAuthRepositoryProvider.overrideWithValue(mockAuthRepo),
          firebaseAuthStateProvider.overrideWith(
            () => FakeFirebaseAuthStateNotifier(mockUser),
          ),
        ],
      );

      await tester.pumpWidget(createTestWidget(container));
      await tester.pumpAndSettle();

      // ボタンをタップ
      await tester.tap(find.text('認証を完了したか確認する'));

      // ポンプして画面を再描画（まだ非同期処理は終わっていない）
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // 非同期処理を最後まで完了させる
      await tester.pumpAndSettle();

      // ローディングが消え、処理が呼ばれたことを確認
      expect(find.byType(CircularProgressIndicator), findsNothing);
      verify(() => mockAuthRepo.reloadCurrentUser()).called(1);
    });

    testWidgets('再送信ボタンをタップした時、処理後に成功スナックバーが表示されること', (tester) async {
      when(() => mockUser.emailVerified).thenReturn(false);

      final container = ProviderContainer(
        overrides: [
          firebaseAuthRepositoryProvider.overrideWithValue(mockAuthRepo),
          firebaseAuthStateProvider.overrideWith(
            () => FakeFirebaseAuthStateNotifier(mockUser),
          ),
        ],
      );

      await tester.pumpWidget(createTestWidget(container));
      await tester.pumpAndSettle();

      await tester.tap(find.text('再送信する'));
      await tester.pumpAndSettle();

      verify(() => mockAuthRepo.sendEmailVerification()).called(1);
      // 処理成功後にスナックバーが表示されていることを確認
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('再送信処理でエラーが起きた場合、エラースナックバーが表示されること', (tester) async {
      when(() => mockUser.emailVerified).thenReturn(false);

      // 例外を投げるように設定
      when(
        () => mockAuthRepo.sendEmailVerification(),
      ).thenThrow(Exception('Error'));

      final container = ProviderContainer(
        overrides: [
          firebaseAuthRepositoryProvider.overrideWithValue(mockAuthRepo),
          firebaseAuthStateProvider.overrideWith(
            () => FakeFirebaseAuthStateNotifier(mockUser),
          ),
        ],
      );

      await tester.pumpWidget(createTestWidget(container));
      await tester.pumpAndSettle();

      await tester.tap(find.text('再送信する'));
      await tester.pumpAndSettle();

      verify(() => mockAuthRepo.sendEmailVerification()).called(1);
      // ErrorHandler 経由でエラースナックバーが表示されることを確認
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('アプリがバックグラウンドから復帰(resumed)した時、ユーザー情報がリロードされること', (
      tester,
    ) async {
      when(() => mockUser.emailVerified).thenReturn(false);

      final container = ProviderContainer(
        overrides: [
          firebaseAuthRepositoryProvider.overrideWithValue(mockAuthRepo),
          firebaseAuthStateProvider.overrideWith(
            () => FakeFirebaseAuthStateNotifier(mockUser),
          ),
          appLifecycleProvider.overrideWith(FakeAppLifecycle.new),
        ],
      );

      await tester.pumpWidget(createTestWidget(container));
      await tester.pumpAndSettle();

      // ✨ Fakeプロバイダーの操作リモコン（Notifier）を取得する
      final _ =
          container.read(appLifecycleProvider.notifier) as FakeAppLifecycle
            // アプリがバックグラウンドから復帰（resumed）した状態をシミュレート！
            ..updateState(AppLifecycleState.resumed);
      await tester.pump();

      // 状態の変化を検知して、リロード処理が1回呼ばれたことを確認
      verify(() => mockAuthRepo.reloadCurrentUser()).called(1);
    });

    testWidgets(
      'アプリがバックグラウンドから復帰(resumed)した時のリロードでエラーが起きた場合、エラースナックバーが表示されること',
      (tester) async {
        when(() => mockUser.emailVerified).thenReturn(false);

        // 非同期処理で例外を投げるように設定
        when(() => mockAuthRepo.reloadCurrentUser()).thenAnswer(
          (_) => Future.error(Exception('Lifecycle Reload Error')),
        );

        final container = ProviderContainer(
          overrides: [
            firebaseAuthRepositoryProvider.overrideWithValue(mockAuthRepo),
            firebaseAuthStateProvider.overrideWith(
              () => FakeFirebaseAuthStateNotifier(mockUser),
            ),
            appLifecycleProvider.overrideWith(FakeAppLifecycle.new),
          ],
        );

        await tester.pumpWidget(createTestWidget(container));
        await tester.pumpAndSettle();

        final _ =
            container.read(appLifecycleProvider.notifier) as FakeAppLifecycle
              ..updateState(AppLifecycleState.resumed);
        await tester.pumpAndSettle();

        verify(() => mockAuthRepo.reloadCurrentUser()).called(1);
        expect(find.byType(SnackBar), findsOneWidget);
      },
    );

    testWidgets(
      'ユーザー状態が変更され emailVerified == true になると、自動で HomeRoute に遷移すること',
      (tester) async {
        when(() => mockUser.emailVerified).thenReturn(false);

        final container = ProviderContainer(
          overrides: [
            firebaseAuthRepositoryProvider.overrideWithValue(mockAuthRepo),
            firebaseAuthStateProvider.overrideWith(
              () => FakeFirebaseAuthStateNotifier(mockUser),
            ),
          ],
        );

        await tester.pumpWidget(createTestWidget(container));
        await tester.pumpAndSettle();

        final verifiedUser = MockUser();
        when(() => verifiedUser.emailVerified).thenReturn(true);

        (container.read(firebaseAuthStateProvider.notifier)
                as FakeFirebaseAuthStateNotifier)
            .updateState(verifiedUser);

        await tester.pumpAndSettle();

        expect(find.textContaining('Navigated to'), findsOneWidget);
        expect(find.text('メール認証'), findsNothing);
      },
    );

    testWidgets('手動確認ボタンをタップしてエラーが起きた場合、エラースナックバーが表示されること', (tester) async {
      when(() => mockUser.emailVerified).thenReturn(false);

      // リロード処理で例外を投げるように設定
      when(
        () => mockAuthRepo.reloadCurrentUser(),
      ).thenThrow(Exception('Reload Error'));

      final container = ProviderContainer(
        overrides: [
          firebaseAuthRepositoryProvider.overrideWithValue(mockAuthRepo),
          firebaseAuthStateProvider.overrideWith(
            () => FakeFirebaseAuthStateNotifier(mockUser),
          ),
        ],
      );

      await tester.pumpWidget(createTestWidget(container));
      await tester.pumpAndSettle();

      // 手動確認ボタンをタップ
      await tester.tap(find.text('認証を完了したか確認する'));
      await tester.pumpAndSettle();

      verify(() => mockAuthRepo.reloadCurrentUser()).called(1);

      // ErrorHandler 経由でエラースナックバーが表示されることを確認（61行目の通過）
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
