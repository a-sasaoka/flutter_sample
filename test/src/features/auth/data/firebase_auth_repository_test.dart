import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_sample/src/features/auth/data/firebase_auth_repository.dart'; // パスは適宜合わせてください
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

// --- モッククラスの定義 ---
class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockGoogleSignIn extends Mock implements GoogleSignIn {}

class MockUser extends Mock implements User {}

class MockUserCredential extends Mock implements UserCredential {}

class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}

class MockGoogleSignInAuthentication extends Mock
    implements GoogleSignInAuthentication {}

class MockGoogleSignInAuthorizationClient extends Mock
    implements GoogleSignInAuthorizationClient {}

class MockAuthzResponse extends Mock
    implements GoogleSignInClientAuthorization {}

// mocktail で any(that: ...) 等を使うためのダミークラス
class FakeAuthCredential extends Fake implements AuthCredential {}

void main() {
  late MockFirebaseAuth mockAuth;
  late MockGoogleSignIn mockGoogleSignIn;
  late MockUser mockUser;
  late MockUserCredential mockUserCredential;

  setUpAll(() {
    // any(named: 'credential') などのためにフォールバック値を登録
    registerFallbackValue(FakeAuthCredential());
  });

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockGoogleSignIn = MockGoogleSignIn();
    mockUser = MockUser();
    mockUserCredential = MockUserCredential();

    // デフォルトの挙動設定
    when(() => mockUserCredential.user).thenReturn(mockUser);
  });

  /// 依存関係を注入した ProviderContainer を作成するヘルパー
  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        firebaseAuthProvider.overrideWithValue(mockAuth),
        googleSignInProvider.overrideWithValue(mockGoogleSignIn),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('FirebaseAuthRepository', () {
    test('build: 現在ログインしているユーザーを返すこと', () {
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      final container = createContainer();

      final state = container.read(firebaseAuthRepositoryProvider);

      expect(state, mockUser);
      verify(() => mockAuth.currentUser).called(1);
    });

    test('authStateChanges: FirebaseAuth のストリームをそのまま返すこと', () {
      final container = createContainer();
      final repo = container.read(firebaseAuthRepositoryProvider.notifier);
      const stream = Stream<User?>.empty();

      when(() => mockAuth.authStateChanges()).thenAnswer((_) => stream);

      final result = repo.authStateChanges();

      expect(result, stream);
      verify(() => mockAuth.authStateChanges()).called(1);
    });

    test('signIn: メールとパスワードでログインし、state を更新すること', () async {
      final container = createContainer();
      final repo = container.read(firebaseAuthRepositoryProvider.notifier);

      when(
        () => mockAuth.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        ),
      ).thenAnswer((_) async => mockUserCredential);

      await repo.signIn('test@example.com', 'password123');

      expect(container.read(firebaseAuthRepositoryProvider), mockUser);
      verify(
        () => mockAuth.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        ),
      ).called(1);
    });

    test('signUp: メールとパスワードで新規登録し、state を更新すること', () async {
      final container = createContainer();
      final repo = container.read(firebaseAuthRepositoryProvider.notifier);

      when(
        () => mockAuth.createUserWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        ),
      ).thenAnswer((_) async => mockUserCredential);

      await repo.signUp('test@example.com', 'password123');

      expect(container.read(firebaseAuthRepositoryProvider), mockUser);
    });

    group('sendEmailVerification', () {
      test('ユーザーが未認証の場合、確認メールを送信すること', () async {
        final container = createContainer();
        final repo = container.read(firebaseAuthRepositoryProvider.notifier);

        when(() => mockAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.emailVerified).thenReturn(false);
        when(() => mockUser.sendEmailVerification()).thenAnswer((_) async {});

        await repo.sendEmailVerification();

        verify(() => mockUser.sendEmailVerification()).called(1);
      });

      test('ユーザーが認証済み、または null の場合は何もしないこと', () async {
        final container = createContainer();
        final repo = container.read(firebaseAuthRepositoryProvider.notifier);

        when(() => mockAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.emailVerified).thenReturn(true);

        await repo.sendEmailVerification();

        // 呼ばれていないことを確認
        verifyNever(() => mockUser.sendEmailVerification());
      });
    });

    test('reloadCurrentUser: ユーザー情報を再読み込みし、state を更新すること', () async {
      final container = createContainer();
      final repo = container.read(firebaseAuthRepositoryProvider.notifier);

      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.reload()).thenAnswer((_) async {});

      await repo.reloadCurrentUser();

      verify(() => mockUser.reload()).called(1);
      // reload 後にもう一度 currentUser を読みに行っているか
      verify(() => mockAuth.currentUser).called(3);
      expect(container.read(firebaseAuthRepositoryProvider), mockUser);
    });

    test('sendPasswordResetEmail: パスワードリセットメールを送信すること', () async {
      final container = createContainer();
      final repo = container.read(firebaseAuthRepositoryProvider.notifier);

      when(
        () => mockAuth.sendPasswordResetEmail(email: 'test@example.com'),
      ).thenAnswer((_) async {});

      await repo.sendPasswordResetEmail('test@example.com');

      verify(
        () => mockAuth.sendPasswordResetEmail(email: 'test@example.com'),
      ).called(1);
    });

    test(
      'signOut: Firebase と GoogleSignIn の両方からサインアウトし、state を null にすること',
      () async {
        final container = createContainer();
        final repo = container.read(firebaseAuthRepositoryProvider.notifier);

        when(() => mockAuth.signOut()).thenAnswer((_) async {});
        when(() => mockGoogleSignIn.signOut()).thenAnswer((_) async {});

        await repo.signOut();

        verify(() => mockAuth.signOut()).called(1);
        verify(() => mockGoogleSignIn.signOut()).called(1);
        expect(container.read(firebaseAuthRepositoryProvider), isNull);
      },
    );

    group('signInWithGoogle', () {
      test('初期化と認証で Exception が発生した場合、false を返すこと (catchブロックの網羅)', () async {
        final container = createContainer();
        final repo = container.read(firebaseAuthRepositoryProvider.notifier);

        when(() => mockGoogleSignIn.initialize()).thenAnswer((_) async {});
        // authenticate 時に例外を投げる
        when(
          () => mockGoogleSignIn.authenticate(),
        ).thenThrow(Exception('Google SignIn Canceled'));

        final result = await repo.signInWithGoogle();

        expect(result, isFalse);
      });

      test('トークンが null の場合、signInWithCredential を呼ばずに false を返すこと', () async {
        final container = createContainer();
        final repo = container.read(firebaseAuthRepositoryProvider.notifier);

        final mockGoogleUser = MockGoogleSignInAccount();
        final mockGoogleAuth = MockGoogleSignInAuthentication();
        final mockAuthClient = MockGoogleSignInAuthorizationClient();

        when(() => mockGoogleSignIn.initialize()).thenAnswer((_) async {});
        when(
          () => mockGoogleSignIn.authenticate(),
        ).thenAnswer((_) async => mockGoogleUser);

        when(() => mockGoogleUser.authentication).thenReturn(mockGoogleAuth);
        when(() => mockGoogleAuth.idToken).thenReturn(null);

        when(
          () => mockGoogleUser.authorizationClient,
        ).thenReturn(mockAuthClient);
        when(
          () => mockAuthClient.authorizationForScopes(any()),
        ).thenAnswer((_) async => null);

        final result = await repo.signInWithGoogle();

        expect(result, isFalse);
        verifyNever(() => mockAuth.signInWithCredential(any()));
      });

      test('正常にGoogleアカウントでログインし、トークンを使って state を更新すること', () async {
        final container = createContainer();
        final repo = container.read(firebaseAuthRepositoryProvider.notifier);

        final mockGoogleUser = MockGoogleSignInAccount();
        final mockGoogleAuth = MockGoogleSignInAuthentication();
        final mockAuthClient = MockGoogleSignInAuthorizationClient();

        // 💡 1. 戻り値のモックをインスタンス化し、ダミーの accessToken を持たせる
        final mockAuthz = MockAuthzResponse();
        when(() => mockAuthz.accessToken).thenReturn('dummy_access_token');

        when(() => mockGoogleSignIn.initialize()).thenAnswer((_) async {});
        when(
          () => mockGoogleSignIn.authenticate(),
        ).thenAnswer((_) async => mockGoogleUser);

        when(() => mockGoogleUser.authentication).thenReturn(mockGoogleAuth);
        when(() => mockGoogleAuth.idToken).thenReturn('dummy_id_token');

        when(
          () => mockGoogleUser.authorizationClient,
        ).thenReturn(mockAuthClient);

        // 💡 2. null ではなく、上で作った mockAuthz を返すようにする！
        when(
          () => mockAuthClient.authorizationForScopes(any()),
        ).thenAnswer((_) async => mockAuthz);

        when(
          () => mockAuth.signInWithCredential(any()),
        ).thenAnswer((_) async => mockUserCredential);

        // Act
        final result = await repo.signInWithGoogle();

        // Assert
        expect(result, isTrue);
        verify(() => mockAuth.signInWithCredential(any())).called(1);
        expect(container.read(firebaseAuthRepositoryProvider), mockUser);
      });
    });
  });
}
