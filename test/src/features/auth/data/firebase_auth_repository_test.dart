import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/auth/data/firebase_auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';

// --- モックとFakeクラスの定義 ---

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockGoogleSignIn extends Mock implements GoogleSignIn {}

class MockUser extends Mock implements User {}

class MockUserCredential extends Mock implements UserCredential {}

class MockLogger extends Mock implements Logger {}

class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}

class MockGoogleSignInAuthentication extends Mock
    implements GoogleSignInAuthentication {}

class MockAuthClient extends Mock implements GoogleSignInAuthorizationClient {}

class MockAuthz extends Mock implements GoogleSignInClientAuthorization {}

class FakeAuthCredential extends Fake implements AuthCredential {}

void main() {
  late MockFirebaseAuth mockFirebaseAuth;
  late MockGoogleSignIn mockGoogleSignIn;
  late MockLogger mockLogger;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(FakeAuthCredential());
    registerFallbackValue(<String>[]);
  });

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    mockGoogleSignIn = MockGoogleSignIn();
    mockLogger = MockLogger();

    when(() => mockLogger.w(any<dynamic>())).thenReturn(null);

    when(
      () => mockFirebaseAuth.userChanges(),
    ).thenAnswer((_) => const Stream.empty());
    when(() => mockFirebaseAuth.currentUser).thenReturn(null);

    container = ProviderContainer(
      overrides: [
        firebaseAuthProvider.overrideWithValue(mockFirebaseAuth),
        googleSignInProvider.overrideWithValue(mockGoogleSignIn),
        loggerProvider.overrideWithValue(mockLogger),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('authStateChangesProvider', () {
    test('firebaseAuth.userChanges() を監視し、AsyncValueとして状態を返すこと', () {
      final mockUser = MockUser();
      when(
        () => mockFirebaseAuth.userChanges(),
      ).thenAnswer((_) => Stream.value(mockUser));

      final asyncValue = container.read(authStateChangesProvider);

      expect(asyncValue, isA<AsyncValue<User?>>());
      verify(() => mockFirebaseAuth.userChanges()).called(1);
    });
  });

  group('FirebaseAuthRepository (Email & Password)', () {
    test('signIn: メールアドレスとパスワードでログイン処理が呼ばれること', () async {
      final repo = container.read(firebaseAuthRepositoryProvider);
      when(
        () => mockFirebaseAuth.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        ),
      ).thenAnswer((_) async => MockUserCredential());

      await repo.signIn('test@example.com', 'password123');

      verify(
        () => mockFirebaseAuth.signInWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        ),
      ).called(1);
    });

    test('signUp: メールアドレスとパスワードで新規登録処理が呼ばれること', () async {
      final repo = container.read(firebaseAuthRepositoryProvider);
      when(
        () => mockFirebaseAuth.createUserWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        ),
      ).thenAnswer((_) async => MockUserCredential());

      await repo.signUp('test@example.com', 'password123');

      verify(
        () => mockFirebaseAuth.createUserWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        ),
      ).called(1);
    });
  });

  group('FirebaseAuthRepository (Google Sign-In)', () {
    test('signInWithGoogle: 成功時にFirebaseで認証され、trueを返すこと', () async {
      final repo = container.read(firebaseAuthRepositoryProvider);

      final mockGoogleUser = MockGoogleSignInAccount();
      final mockGoogleAuth = MockGoogleSignInAuthentication();
      final mockAuthClient = MockAuthClient();
      final mockAuthz = MockAuthz();

      when(() => mockGoogleSignIn.initialize()).thenAnswer((_) async {});
      when(
        () => mockGoogleSignIn.authenticate(),
      ).thenAnswer((_) async => mockGoogleUser);

      when(() => mockGoogleUser.authentication).thenReturn(mockGoogleAuth);
      when(() => mockGoogleAuth.idToken).thenReturn('dummy_id_token');

      when(() => mockGoogleUser.authorizationClient).thenReturn(mockAuthClient);

      when(
        () => mockAuthClient.authorizationForScopes(any<List<String>>()),
      ).thenAnswer((_) async => mockAuthz);

      when(() => mockAuthz.accessToken).thenReturn('dummy_access_token');

      when(
        () => mockFirebaseAuth.signInWithCredential(any<AuthCredential>()),
      ).thenAnswer((_) async => MockUserCredential());

      final result = await repo.signInWithGoogle();

      expect(result, isTrue);
      verify(() => mockGoogleSignIn.initialize()).called(1);
      verify(() => mockGoogleSignIn.authenticate()).called(1);

      verify(
        () => mockFirebaseAuth.signInWithCredential(any<AuthCredential>()),
      ).called(1);

      await repo.signInWithGoogle();
      verifyNever(() => mockGoogleSignIn.initialize());
    });

    test('signInWithGoogle: トークンが両方ともnullの場合、falseを返すこと', () async {
      final repo = container.read(firebaseAuthRepositoryProvider);

      final mockGoogleUser = MockGoogleSignInAccount();
      final mockGoogleAuth = MockGoogleSignInAuthentication();
      final mockAuthClient = MockAuthClient();

      when(() => mockGoogleSignIn.initialize()).thenAnswer((_) async {});
      when(
        () => mockGoogleSignIn.authenticate(),
      ).thenAnswer((_) async => mockGoogleUser);
      when(() => mockGoogleUser.authentication).thenReturn(mockGoogleAuth);

      when(() => mockGoogleAuth.idToken).thenReturn(null);

      when(() => mockGoogleUser.authorizationClient).thenReturn(mockAuthClient);

      when(
        () => mockAuthClient.authorizationForScopes(any<List<String>>()),
      ).thenAnswer((_) async => null);

      final result = await repo.signInWithGoogle();

      expect(result, isFalse);

      verifyNever(
        () => mockFirebaseAuth.signInWithCredential(any<AuthCredential>()),
      );
    });

    test(
      'signInWithGoogle: 例外が発生した場合(キャンセル等)、Loggerで警告を出してfalseを返すこと',
      () async {
        final repo = container.read(firebaseAuthRepositoryProvider);

        when(() => mockGoogleSignIn.initialize()).thenAnswer((_) async {});

        final exception = Exception('Canceled by user');
        when(() => mockGoogleSignIn.authenticate()).thenThrow(exception);

        final result = await repo.signInWithGoogle();

        expect(result, isFalse);
        verify(
          () => mockLogger.w('SignInWithGoogle Error: $exception'),
        ).called(1);
      },
    );
  });

  group('FirebaseAuthRepository (Other Methods)', () {
    test('sendEmailVerification: 未検証の場合、確認メールが送信されること', () async {
      final repo = container.read(firebaseAuthRepositoryProvider);
      final mockUser = MockUser();

      when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.emailVerified).thenReturn(false);
      when(mockUser.sendEmailVerification).thenAnswer((_) async {});

      await repo.sendEmailVerification();

      verify(mockUser.sendEmailVerification).called(1);
    });

    test('sendEmailVerification: 既に検証済みの場合、送信処理がスキップされること', () async {
      final repo = container.read(firebaseAuthRepositoryProvider);
      final mockUser = MockUser();

      when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.emailVerified).thenReturn(true);

      await repo.sendEmailVerification();

      verifyNever(mockUser.sendEmailVerification);
    });

    test('reloadCurrentUser: ユーザー情報をリロードすること', () async {
      final repo = container.read(firebaseAuthRepositoryProvider);
      final mockUser = MockUser();

      when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
      when(mockUser.reload).thenAnswer((_) async {});

      await repo.reloadCurrentUser();

      verify(mockUser.reload).called(1);
    });

    test('sendPasswordResetEmail: パスワードリセットメール送信が呼ばれること', () async {
      final repo = container.read(firebaseAuthRepositoryProvider);
      when(
        () =>
            mockFirebaseAuth.sendPasswordResetEmail(email: 'test@example.com'),
      ).thenAnswer((_) async {});

      await repo.sendPasswordResetEmail('test@example.com');

      verify(
        () =>
            mockFirebaseAuth.sendPasswordResetEmail(email: 'test@example.com'),
      ).called(1);
    });

    test('signOut: FirebaseとGoogleSignIn両方のサインアウトが呼ばれること', () async {
      final repo = container.read(firebaseAuthRepositoryProvider);
      when(() => mockFirebaseAuth.signOut()).thenAnswer((_) async {});
      when(() => mockGoogleSignIn.signOut()).thenAnswer((_) async {});

      await repo.signOut();

      verify(() => mockFirebaseAuth.signOut()).called(1);
      verify(() => mockGoogleSignIn.signOut()).called(1);
    });
  });
}
