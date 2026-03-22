import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/features/auth/data/firebase_auth_repository.dart';
import 'package:flutter_sample/src/features/auth/presentation/firebase_email_verification_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

// --- モッククラス ---
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

// --- Fake Repository ---
class FakeFirebaseAuthRepository extends FirebaseAuthRepository {
  FakeFirebaseAuthRepository(this._initialUser);
  final User? _initialUser;

  int reloadCalledCount = 0;
  int sendEmailCalledCount = 0;

  @override
  User? build() => _initialUser;

  @override
  Future<void> reloadCurrentUser() async {
    reloadCalledCount++;
  }

  @override
  Future<void> sendEmailVerification() async {
    sendEmailCalledCount++;
  }

  // テスト中にユーザー状態（認証済み等）を変更するためのヘルパー
  // ignore: use_setters_to_change_properties
  void updateUser(User? user) {
    state = user;
  }
}

void main() {
  late MockAppLocalizations mockL10n;
  late MockUser mockUser;

  setUp(() {
    mockL10n = MockAppLocalizations();
    mockUser = MockUser();

    // L10nのスタブ設定
    when(() => mockL10n.emailVerificationTitle).thenReturn('メール認証');
    when(
      () => mockL10n.emailVerificationDescription,
    ).thenReturn('確認メールを送信しました。');
    when(() => mockL10n.resendVerificationMail).thenReturn('再送信');
    when(() => mockL10n.emailVerificationWaiting).thenReturn('認証待ち...');

    // 初期状態は「未認証 (false)」にしておく
    when(() => mockUser.emailVerified).thenReturn(false);
  });

  /// 画面をセットアップし、テスト用のGoRouterを返すヘルパー関数
  Future<GoRouter> setupWidget(
    WidgetTester tester,
    FakeFirebaseAuthRepository fakeRepo,
  ) async {
    final router = GoRouter(
      initialLocation: '/verify',
      routes: [
        GoRoute(
          path: '/verify',
          builder: (context, state) => const FirebaseEmailVerificationScreen(),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const Scaffold(body: Text('Home Screen')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseAuthRepositoryProvider.overrideWith(() => fakeRepo),
        ],
        // Consumer でラップして Provider を強制的に延命する
        child: Consumer(
          builder: (context, ref, _) {
            // テスト中、誰も watch していないことで Provider が破棄されるのを防ぐ
            ref.watch(firebaseAuthRepositoryProvider);

            return MaterialApp.router(
              localizationsDelegates: [_MockLocalizationsDelegate(mockL10n)],
              routerConfig: router,
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  group('FirebaseEmailVerificationScreen', () {
    testWidgets('初期表示: 正しいテキストとボタンが表示されること', (tester) async {
      final fakeRepo = FakeFirebaseAuthRepository(mockUser);
      await setupWidget(tester, fakeRepo);

      expect(find.text('メール認証'), findsOneWidget);
      expect(find.text('確認メールを送信しました。'), findsOneWidget);
      expect(find.text('再送信'), findsOneWidget);
      expect(find.text('認証待ち...'), findsOneWidget);

      // テスト終了時にタイマーが動いたままだとエラーになるため、画面を破棄(dispose)する
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('ボタン押下: 再送信ボタンをタップすると sendEmailVerification が呼ばれること', (
      tester,
    ) async {
      final fakeRepo = FakeFirebaseAuthRepository(mockUser);
      await setupWidget(tester, fakeRepo);

      // Act: ボタンをタップ
      await tester.tap(find.text('再送信'));
      await tester.pump();

      // Assert: メソッドが1回呼ばれたか確認
      expect(fakeRepo.sendEmailCalledCount, 1);

      // 画面を破棄
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('タイマー: 3秒ごとに reloadCurrentUser が呼ばれ、認証完了でホームへ遷移すること', (
      tester,
    ) async {
      final fakeRepo = FakeFirebaseAuthRepository(mockUser);
      final router = await setupWidget(tester, fakeRepo);

      // 1. 最初の3秒を進める
      await tester.pump(const Duration(seconds: 3));

      // 未認証なので、リロードは呼ばれるが遷移はしない
      expect(fakeRepo.reloadCalledCount, 1);
      expect(router.routerDelegate.currentConfiguration.uri.path, '/verify');

      // 2. ユーザーが別端末などでメールリンクを踏み、認証完了したとシミュレート
      when(() => mockUser.emailVerified).thenReturn(true);
      fakeRepo.updateUser(mockUser); // 状態を更新

      // 3. 次の3秒を進める
      await tester.pump(const Duration(seconds: 3));

      // リロードが2回目に呼ばれ、認証完了を検知して遷移するはず
      expect(fakeRepo.reloadCalledCount, 2);

      await tester.pumpAndSettle(); // 画面遷移アニメーションを完了させる

      // タイマーがキャンセルされ、Home画面（ダミーの '/' パス）へ遷移したことを確認
      expect(router.routerDelegate.currentConfiguration.uri.path, '/');
    });
  });
}
