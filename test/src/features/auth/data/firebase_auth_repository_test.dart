import 'dart:async';

import 'package:checks/checks.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_sample/src/core/exceptions/app_exception.dart';
import 'package:flutter_sample/src/core/exceptions/firebase_auth_error_codes.dart';
import 'package:flutter_sample/src/core/exceptions/reauth_exception.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/auth/data/firebase_auth_repository.dart';
import 'package:flutter_sample/src/features/auth/domain/account_deletion_precheck.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker_flutter/talker_flutter.dart';

// --- モックとFakeクラスの定義 ---

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockGoogleSignIn extends Mock implements GoogleSignIn {}

class MockUser extends Mock implements User {}

class MockUserCredential extends Mock implements UserCredential {}

class MockTalker extends Mock implements Talker {}

class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}

class MockGoogleSignInAuthentication extends Mock
    implements GoogleSignInAuthentication {}

class MockAuthClient extends Mock implements GoogleSignInAuthorizationClient {}

class MockAuthz extends Mock implements GoogleSignInClientAuthorization {}

class MockUserMetadata extends Mock implements UserMetadata {}

class MockUserInfo extends Mock implements UserInfo {}

class FakeAuthCredential extends Fake implements AuthCredential {}

void main() {
  late MockFirebaseAuth mockFirebaseAuth;
  late MockGoogleSignIn mockGoogleSignIn;
  late MockTalker mockTalker;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(FakeAuthCredential());
    registerFallbackValue(<String>[]);
    registerFallbackValue(StackTrace.current);
  });

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    mockGoogleSignIn = MockGoogleSignIn();
    mockTalker = MockTalker();

    when(() => mockTalker.info(any<dynamic>())).thenReturn(null);
    when(() => mockTalker.warning(any<dynamic>())).thenReturn(null);
    when(
      () =>
          mockTalker.handle(any<Object>(), any<StackTrace?>(), any<dynamic>()),
    ).thenReturn(null);

    when(
      () => mockFirebaseAuth.userChanges(),
    ).thenAnswer((_) => const Stream.empty());
    when(() => mockFirebaseAuth.currentUser).thenReturn(null);

    container = ProviderContainer(
      overrides: [
        firebaseAuthProvider.overrideWithValue(mockFirebaseAuth),
        googleSignInProvider.overrideWithValue(mockGoogleSignIn),
        loggerProvider.overrideWithValue(mockTalker),
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

      check(asyncValue).isA<AsyncValue<User?>>();
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

      check(result).equals(true);
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

      check(result).equals(false);

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

        check(result).equals(false);
        verify(
          () => mockTalker.warning('SignInWithGoogle Error: $exception'),
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

    test('currentUserId: ログイン中は uid を返し、未ログイン時は null を返すこと', () {
      final repo = container.read(firebaseAuthRepositoryProvider);
      final mockUser = MockUser();

      when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.uid).thenReturn('user_123');
      check(repo.currentUserId).equals('user_123');

      when(() => mockFirebaseAuth.currentUser).thenReturn(null);
      check(repo.currentUserId).isNull();
    });

    group('updateAuthProfile', () {
      test(
        'currentUser が null の場合、警告ログを出して unauthenticated 例外をスローすること',
        () async {
          final repo = container.read(firebaseAuthRepositoryProvider);
          when(() => mockFirebaseAuth.currentUser).thenReturn(null);

          await check(
            repo.updateAuthProfile(
              displayName: '新表示名',
              email: 'new@example.com',
            ),
          ).throws<AppException>();

          verify(
            () => mockTalker.warning(
              'Cannot update Firebase profile: No user is currently signed in.',
            ),
          ).called(1);
        },
      );

      test('値に変更がない場合、同期処理がスキップされ、reload のみ呼ばれること', () async {
        final repo = container.read(firebaseAuthRepositoryProvider);
        final mockUser = MockUser();

        when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.displayName).thenReturn('旧表示名');
        when(() => mockUser.email).thenReturn('old@example.com');
        when(mockUser.reload).thenAnswer((_) async {});

        await repo.updateAuthProfile(
          displayName: '旧表示名',
          email: 'old@example.com',
        );

        verifyNever(() => mockUser.updateDisplayName(any<String?>()));
        verifyNever(() => mockUser.verifyBeforeUpdateEmail(any<String>()));
        verify(mockUser.reload).called(1);
      });

      test(
        'displayName のみ変更がある場合、updateDisplayName と reload が呼ばれること',
        () async {
          final repo = container.read(firebaseAuthRepositoryProvider);
          final mockUser = MockUser();

          when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
          when(() => mockUser.displayName).thenReturn('旧表示名');
          when(() => mockUser.email).thenReturn('old@example.com');
          when(
            () => mockUser.updateDisplayName('新表示名'),
          ).thenAnswer((_) async {});
          when(mockUser.reload).thenAnswer((_) async {});

          await repo.updateAuthProfile(
            displayName: '新表示名',
            email: 'old@example.com',
          );

          verify(() => mockUser.updateDisplayName('新表示名')).called(1);
          verifyNever(() => mockUser.verifyBeforeUpdateEmail(any<String>()));
          verify(mockUser.reload).called(1);
        },
      );

      test(
        'email のみ変更がある場合、verifyBeforeUpdateEmail と reload が呼ばれること',
        () async {
          final repo = container.read(firebaseAuthRepositoryProvider);
          final mockUser = MockUser();

          when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
          when(() => mockUser.displayName).thenReturn('旧表示名');
          when(() => mockUser.email).thenReturn('old@example.com');
          when(
            () => mockUser.verifyBeforeUpdateEmail('new@example.com'),
          ).thenAnswer((_) async {});
          when(mockUser.reload).thenAnswer((_) async {});

          await repo.updateAuthProfile(
            displayName: '旧表示名',
            email: 'new@example.com',
          );

          verifyNever(() => mockUser.updateDisplayName(any<String?>()));
          verify(
            () => mockUser.verifyBeforeUpdateEmail('new@example.com'),
          ).called(1);
          verify(mockUser.reload).called(1);
        },
      );

      test('displayName の変更処理中に例外が発生した場合、reload が呼ばれず例外を再スローすること', () async {
        final repo = container.read(firebaseAuthRepositoryProvider);
        final mockUser = MockUser();

        when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.displayName).thenReturn('旧表示名');
        when(() => mockUser.email).thenReturn('old@example.com');
        when(
          () => mockUser.updateDisplayName('新表示名'),
        ).thenThrow(Exception('Update error'));

        await check(
          repo.updateAuthProfile(displayName: '新表示名', email: 'old@example.com'),
        ).throws<Object>();

        verify(() => mockUser.updateDisplayName('新表示名')).called(1);
        verifyNever(mockUser.reload);
      });

      test('email の変更処理中に例外が発生した場合、reload が呼ばれず例外を再スローすること', () async {
        final repo = container.read(firebaseAuthRepositoryProvider);
        final mockUser = MockUser();

        when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.displayName).thenReturn('旧表示名');
        when(() => mockUser.email).thenReturn('old@example.com');
        when(
          () => mockUser.verifyBeforeUpdateEmail('new@example.com'),
        ).thenThrow(Exception('Email update error'));

        await check(
          repo.updateAuthProfile(displayName: '旧表示名', email: 'new@example.com'),
        ).throws<Object>();

        verify(
          () => mockUser.verifyBeforeUpdateEmail('new@example.com'),
        ).called(1);
        verifyNever(mockUser.reload);
      });

      test('photoUrl の変更がある場合、updatePhotoURL が呼ばれること', () async {
        final repo = container.read(firebaseAuthRepositoryProvider);
        final mockUser = MockUser();

        when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.displayName).thenReturn('表示名');
        when(() => mockUser.email).thenReturn('test@example.com');
        when(() => mockUser.photoURL).thenReturn('https://old.jpg');
        when(() => mockUser.updatePhotoURL(any())).thenAnswer((_) async {});
        when(mockUser.reload).thenAnswer((_) async {});

        // 写真URLを新しいURLに変更
        await repo.updateAuthProfile(
          displayName: '表示名',
          email: 'test@example.com',
          photoUrl: 'https://new.jpg',
        );
        verify(() => mockUser.updatePhotoURL('https://new.jpg')).called(1);

        // 空文字の場合は null で削除されること
        await repo.updateAuthProfile(
          displayName: '表示名',
          email: 'test@example.com',
          photoUrl: '',
        );
        verify(() => mockUser.updatePhotoURL(null)).called(1);
      });
    });

    group('Reauth & Account Deletion', () {
      test('ユーザー情報ゲッターが currentUser の値を返すこと', () {
        final repo = container.read(firebaseAuthRepositoryProvider);
        check(repo.currentUserEmail).isNull();
        check(repo.currentUserPhotoUrl).isNull();
        check(repo.lastSignInTime).isNull();

        final mockUser = MockUser();
        final mockMetadata = MockUserMetadata();
        final signedInAt = DateTime.utc(2026, 11, 22, 8);
        when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.email).thenReturn('user@example.com');
        when(() => mockUser.photoURL).thenReturn('https://example.com/a.jpg');
        when(() => mockUser.metadata).thenReturn(mockMetadata);
        when(() => mockMetadata.lastSignInTime).thenReturn(signedInAt);

        check(repo.currentUserEmail).equals('user@example.com');
        check(repo.currentUserPhotoUrl).equals('https://example.com/a.jpg');
        check(repo.lastSignInTime).equals(signedInAt);
      });

      test('getAvailableReauthMethods: 未ログインおよび連携プロバイダごとに正しく返すこと', () {
        final repo = container.read(firebaseAuthRepositoryProvider);

        check(repo.getAvailableReauthMethods().isEmpty).isTrue();

        final mockUser = MockUser();
        final passwordInfo = MockUserInfo();
        final googleInfo = MockUserInfo();
        final otherInfo = MockUserInfo();
        when(
          () => passwordInfo.providerId,
        ).thenReturn(EmailAuthProvider.PROVIDER_ID);
        when(
          () => googleInfo.providerId,
        ).thenReturn(GoogleAuthProvider.PROVIDER_ID);
        when(() => otherInfo.providerId).thenReturn('apple.com');

        when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.providerData).thenReturn([passwordInfo, otherInfo]);
        check(
          repo.getAvailableReauthMethods(),
        ).deepEquals({ReauthMethod.password});

        when(() => mockUser.providerData).thenReturn([googleInfo]);
        check(
          repo.getAvailableReauthMethods(),
        ).deepEquals({ReauthMethod.google});

        when(
          () => mockUser.providerData,
        ).thenReturn([passwordInfo, googleInfo]);
        check(
          repo.getAvailableReauthMethods(),
        ).deepEquals({ReauthMethod.password, ReauthMethod.google});
      });

      test('needsRecentLogin: 経過時間に応じて正しく判定されること', () {
        final repo = container.read(firebaseAuthRepositoryProvider);
        final now = DateTime.utc(2026, 11, 22, 9, 5);

        // 未ログイン / lastSignInTime == null は true
        check(repo.needsRecentLogin(now)).isTrue();

        final mockUser = MockUser();
        final mockMetadata = MockUserMetadata();
        when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.metadata).thenReturn(mockMetadata);

        // 4分前 -> false
        when(
          () => mockMetadata.lastSignInTime,
        ).thenReturn(DateTime.utc(2026, 11, 22, 9, 1));
        check(repo.needsRecentLogin(now)).isFalse();

        // ちょうど5分前 -> false
        when(
          () => mockMetadata.lastSignInTime,
        ).thenReturn(DateTime.utc(2026, 11, 22, 9));
        check(repo.needsRecentLogin(now)).isFalse();

        // 5分1秒前 -> true
        when(
          () => mockMetadata.lastSignInTime,
        ).thenReturn(DateTime.utc(2026, 11, 22, 8, 59, 59));
        check(repo.needsRecentLogin(now)).isTrue();
      });

      test('reauthenticateWithPassword: 正常系・各例外変換が正しく動作すること', () async {
        final repo = container.read(firebaseAuthRepositoryProvider);

        // 未ログイン
        await check(
          repo.reauthenticateWithPassword(password: 'pass'),
        ).throws<UnauthenticatedException>();

        final mockUser = MockUser();
        when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);

        // メール未設定
        when(() => mockUser.email).thenReturn('');
        await check(
          repo.reauthenticateWithPassword(password: 'pass'),
        ).throws<ReauthMissingEmailException>();

        // 正常系
        when(() => mockUser.email).thenReturn('test@example.com');
        when(
          () => mockUser.reauthenticateWithCredential(any<AuthCredential>()),
        ).thenAnswer((_) async => MockUserCredential());
        await check(
          repo.reauthenticateWithPassword(password: 'password123'),
        ).completes();
        verify(
          () => mockUser.reauthenticateWithCredential(any<AuthCredential>()),
        ).called(1);

        // 各FirebaseAuthExceptionのマッピング
        final errorAssertions = <String, Future<void> Function()>{
          FirebaseAuthErrorCodes.wrongPassword: () => check(
            repo.reauthenticateWithPassword(password: 'password123'),
          ).throws<ReauthWrongPasswordException>(),
          FirebaseAuthErrorCodes.invalidCredential: () => check(
            repo.reauthenticateWithPassword(password: 'password123'),
          ).throws<ReauthWrongPasswordException>(),
          FirebaseAuthErrorCodes.userMismatch: () => check(
            repo.reauthenticateWithPassword(password: 'password123'),
          ).throws<ReauthUserMismatchException>(),
          FirebaseAuthErrorCodes.tooManyRequests: () => check(
            repo.reauthenticateWithPassword(password: 'password123'),
          ).throws<ReauthTooManyRequestsException>(),
          FirebaseAuthErrorCodes.requiresRecentLogin: () => check(
            repo.reauthenticateWithPassword(password: 'password123'),
          ).throws<ReauthRequiresRecentLoginException>(),
        };

        for (final entry in errorAssertions.entries) {
          when(
            () => mockUser.reauthenticateWithCredential(any<AuthCredential>()),
          ).thenThrow(FirebaseAuthException(code: entry.key));
          await entry.value();
        }

        // 未マップのFirebaseAuthExceptionはそのまま再スロー
        when(
          () => mockUser.reauthenticateWithCredential(any<AuthCredential>()),
        ).thenThrow(FirebaseAuthException(code: 'network-request-failed'));
        await check(
          repo.reauthenticateWithPassword(password: 'password123'),
        ).throws<FirebaseAuthException>();
      });

      test('reauthenticateWithGoogle: '
          '未ログイン・正常・キャンセル・mismatch・例外が正しく動作すること', () async {
        final repo = container.read(firebaseAuthRepositoryProvider);

        // 未ログイン
        await check(
          repo.reauthenticateWithGoogle(),
        ).throws<UnauthenticatedException>();

        final mockUser = MockUser();
        when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(() => mockGoogleSignIn.initialize()).thenAnswer((_) async {});

        // canceled
        when(() => mockGoogleSignIn.authenticate()).thenThrow(
          const GoogleSignInException(code: GoogleSignInExceptionCode.canceled),
        );
        await check(
          repo.reauthenticateWithGoogle(),
        ).throws<ReauthCancelledException>();

        // interrupted
        when(() => mockGoogleSignIn.authenticate()).thenThrow(
          const GoogleSignInException(
            code: GoogleSignInExceptionCode.interrupted,
          ),
        );
        await check(
          repo.reauthenticateWithGoogle(),
        ).throws<ReauthCancelledException>();

        // userMismatch
        when(() => mockGoogleSignIn.authenticate()).thenThrow(
          const GoogleSignInException(
            code: GoogleSignInExceptionCode.userMismatch,
          ),
        );
        await check(
          repo.reauthenticateWithGoogle(),
        ).throws<ReauthUserMismatchException>();

        // その他のGoogleSignInExceptionは再スロー
        when(() => mockGoogleSignIn.authenticate()).thenThrow(
          const GoogleSignInException(
            code: GoogleSignInExceptionCode.unknownError,
          ),
        );
        await check(
          repo.reauthenticateWithGoogle(),
        ).throws<GoogleSignInException>();

        // 両トークンnull -> キャンセル扱い
        final mockGoogleUser = MockGoogleSignInAccount();
        final mockGoogleAuth = MockGoogleSignInAuthentication();
        final mockAuthClient = MockAuthClient();
        final mockAuthz = MockAuthz();
        when(
          () => mockGoogleSignIn.authenticate(),
        ).thenAnswer((_) async => mockGoogleUser);
        when(() => mockGoogleUser.authentication).thenReturn(mockGoogleAuth);
        when(
          () => mockGoogleUser.authorizationClient,
        ).thenReturn(mockAuthClient);
        when(() => mockGoogleAuth.idToken).thenReturn(null);
        when(
          () => mockAuthClient.authorizationForScopes(any<List<String>>()),
        ).thenAnswer((_) async => null);
        await check(
          repo.reauthenticateWithGoogle(),
        ).throws<ReauthCancelledException>();

        // Firebase側で user-mismatch
        when(() => mockGoogleAuth.idToken).thenReturn('id-token');
        when(
          () => mockAuthClient.authorizationForScopes(any<List<String>>()),
        ).thenAnswer((_) async => mockAuthz);
        when(() => mockAuthz.accessToken).thenReturn('access-token');
        when(
          () => mockUser.reauthenticateWithCredential(any<AuthCredential>()),
        ).thenThrow(
          FirebaseAuthException(code: FirebaseAuthErrorCodes.userMismatch),
        );
        await check(
          repo.reauthenticateWithGoogle(),
        ).throws<ReauthUserMismatchException>();

        // 正常系
        when(
          () => mockUser.reauthenticateWithCredential(any<AuthCredential>()),
        ).thenAnswer((_) async => MockUserCredential());
        await check(repo.reauthenticateWithGoogle()).completes();
        verify(
          () => mockUser.reauthenticateWithCredential(any<AuthCredential>()),
        ).called(2);
      });

      test(
        'deleteAccount: 正常・未ログイン・requires-recent-login・例外が正しく動作すること',
        () async {
          final repo = container.read(firebaseAuthRepositoryProvider);

          // 未ログイン
          await check(repo.deleteAccount()).throws<UnauthenticatedException>();

          final mockUser = MockUser();
          when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);

          // requires-recent-login -> ReauthRequiresRecentLoginException
          when(mockUser.delete).thenThrow(
            FirebaseAuthException(
              code: FirebaseAuthErrorCodes.requiresRecentLogin,
            ),
          );
          await check(
            repo.deleteAccount(),
          ).throws<ReauthRequiresRecentLoginException>();
          verify(mockUser.delete).called(1);
          verifyNever(mockGoogleSignIn.signOut);

          // その他のFirebaseAuthException -> そのまま再スロー
          when(
            mockUser.delete,
          ).thenThrow(FirebaseAuthException(code: 'network-request-failed'));
          await check(repo.deleteAccount()).throws<FirebaseAuthException>();
          verify(mockUser.delete).called(1);
          verifyNever(mockGoogleSignIn.signOut);

          // 正常削除 + Googleサインアウト成功
          when(mockUser.delete).thenAnswer((_) async {});
          when(mockGoogleSignIn.signOut).thenAnswer((_) async {});
          await check(repo.deleteAccount()).completes();
          verify(mockUser.delete).called(1);
          verify(mockGoogleSignIn.signOut).called(1);

          // ユーザー削除後にGoogleサインアウトのみ失敗 -> ログ記録しつつ完了
          final signOutError = Exception('Google sign out error');
          when(mockGoogleSignIn.signOut).thenThrow(signOutError);
          await check(repo.deleteAccount()).completes();
          verify(
            () => mockTalker.handle(
              signOutError,
              any<StackTrace?>(),
              'Failed to sign out Google session after account deletion',
            ),
          ).called(1);
        },
      );
    });
  });
}
