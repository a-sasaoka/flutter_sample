import 'package:checks/checks.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_sample/src/core/config/env_config.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/auth/application/auth_service.dart';
import 'package:flutter_sample/src/features/auth/application/auth_state_notifier.dart';
import 'package:flutter_sample/src/features/auth/application/firebase_auth_state_notifier.dart';
import 'package:flutter_sample/src/features/auth/data/firebase_auth_repository.dart';
import 'package:flutter_sample/src/features/auth/data/token_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker_flutter/talker_flutter.dart';

class MockFirebaseAuthRepository extends Mock
    implements FirebaseAuthRepository {}

class MockUser extends Mock implements User {}

class MockTokenStorage extends Mock implements TokenStorage {}

class FakeAuthStateNotifier extends AuthStateNotifier {
  FakeAuthStateNotifier({this.initial = true});

  final bool initial;
  bool isLogoutCalled = false;

  @override
  Future<bool> build() async => initial;

  @override
  Future<void> logout() async {
    isLogoutCalled = true;
    state = const AsyncData(false);
  }
}

class FakeFirebaseAuthStateNotifier extends FirebaseAuthStateNotifier {
  FakeFirebaseAuthStateNotifier(this.initialUser);

  final User? initialUser;

  @override
  AsyncValue<User?> build() => AsyncData(initialUser);
}

void main() {
  late MockFirebaseAuthRepository mockAuthRepo;
  late MockTokenStorage mockTokenStorage;
  late Talker talker;

  setUp(() {
    mockAuthRepo = MockFirebaseAuthRepository();
    mockTokenStorage = MockTokenStorage();
    talker = TalkerFlutter.init(
      settings: TalkerSettings(useConsoleLogs: false),
    );

    when(() => mockAuthRepo.signOut()).thenAnswer((_) async {});
    when(() => mockTokenStorage.getUserId()).thenAnswer((_) async => null);
  });

  ProviderContainer createContainer({
    required bool useFirebaseAuth,
    User? firebaseUser,
    bool authStateValue = true,
    TokenStorage? tokenStorage,
  }) {
    final effectiveTokenStorage = tokenStorage ?? mockTokenStorage;
    final container = ProviderContainer(
      overrides: [
        envConfigProvider.overrideWithValue(
          EnvConfigState(
            baseUrl: 'https://test.example.com',
            imageBaseUrl: defaultImageBaseUrl,
            aiModel: 'test-model',
            connectTimeout: 10,
            receiveTimeout: 15,
            sendTimeout: 10,
            useFirebaseAuth: useFirebaseAuth,
            useAgentPlatform: true,
          ),
        ),
        loggerProvider.overrideWithValue(talker),
        firebaseAuthRepositoryProvider.overrideWithValue(mockAuthRepo),
        tokenStorageProvider.overrideWithValue(effectiveTokenStorage),
        firebaseAuthStateProvider.overrideWith(
          () => FakeFirebaseAuthStateNotifier(firebaseUser),
        ),
        authStateProvider.overrideWith(
          () => FakeAuthStateNotifier(initial: authStateValue),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('isAuthenticatedProvider', () {
    test('useFirebaseAuth: true かつ Firebase User が存在する場合、true を返すこと', () {
      final mockUser = MockUser();
      final container = createContainer(
        useFirebaseAuth: true,
        firebaseUser: mockUser,
      );

      final isAuthed = container.read(isAuthenticatedProvider);
      check(isAuthed).equals(true);
    });

    test('useFirebaseAuth: true かつ Firebase User が null の場合、false を返すこと', () {
      final container = createContainer(useFirebaseAuth: true);

      final isAuthed = container.read(isAuthenticatedProvider);
      check(isAuthed).equals(false);
    });

    test('useFirebaseAuth: false かつ authState が true の場合、true を返すこと', () async {
      final container = createContainer(useFirebaseAuth: false);

      // 非同期Notifierの初期化完了を待機
      await container.read(authStateProvider.future);

      final isAuthed = container.read(isAuthenticatedProvider);
      check(isAuthed).equals(true);
    });

    test(
      'useFirebaseAuth: false かつ authState が false の場合、false を返すこと',
      () async {
        final container = createContainer(
          useFirebaseAuth: false,
          authStateValue: false,
        );

        // 非同期Notifierの初期化完了を待機
        await container.read(authStateProvider.future);

        final isAuthed = container.read(isAuthenticatedProvider);
        check(isAuthed).equals(false);
      },
    );
  });

  group('customUserIdProvider', () {
    test('未ログイン（authState が false）の場合、null を返すこと', () async {
      final container = createContainer(
        useFirebaseAuth: false,
        authStateValue: false,
      );

      await container.read(authStateProvider.future);
      final userId = await container.read(customUserIdProvider.future);
      check(userId).isNull();
    });

    test(
      'ログイン中（authState が true）の場合、tokenStorage から取得した userId を返すこと',
      () async {
        when(
          () => mockTokenStorage.getUserId(),
        ).thenAnswer((_) async => 'custom_user_123');

        final container = createContainer(useFirebaseAuth: false);

        await container.read(authStateProvider.future);
        final userId = await container.read(customUserIdProvider.future);
        check(userId).equals('custom_user_123');
      },
    );
  });

  group('currentUserIdProvider', () {
    test('useFirebaseAuth: true かつ Firebase User が存在する場合、uid を返すこと', () {
      final mockUser = MockUser();
      when(() => mockUser.uid).thenReturn('test-user-id');
      final container = createContainer(
        useFirebaseAuth: true,
        firebaseUser: mockUser,
      );

      final uid = container.read(currentUserIdProvider);
      check(uid).equals('test-user-id');
    });

    test('useFirebaseAuth: true かつ Firebase User が null の場合、null を返すこと', () {
      final container = createContainer(useFirebaseAuth: true);

      final uid = container.read(currentUserIdProvider);
      check(uid).isNull();
    });

    test(
      'useFirebaseAuth: false かつ 独自認証ログイン済みの場合、customUserId を返すこと',
      () async {
        when(
          () => mockTokenStorage.getUserId(),
        ).thenAnswer((_) async => 'custom_user_789');

        final container = createContainer(useFirebaseAuth: false);

        await container.read(authStateProvider.future);
        await container.read(customUserIdProvider.future);

        final uid = container.read(currentUserIdProvider);
        check(uid).equals('custom_user_789');
      },
    );

    test('useFirebaseAuth: false かつ 未ログインの場合、null を返すこと', () async {
      final container = createContainer(
        useFirebaseAuth: false,
        authStateValue: false,
      );

      await container.read(authStateProvider.future);
      await container.read(customUserIdProvider.future);

      final uid = container.read(currentUserIdProvider);
      check(uid).isNull();
    });
  });

  group('AuthService.updateAuthProfile', () {
    test('useFirebaseAuth: true の場合、updateAuthProfile が呼ばれること', () async {
      when(
        () => mockAuthRepo.updateAuthProfile(
          displayName: any(named: 'displayName'),
          email: any(named: 'email'),
          photoUrl: any(named: 'photoUrl'),
        ),
      ).thenAnswer((_) async {});

      final container = createContainer(useFirebaseAuth: true);
      final service = container.read(authServiceProvider);

      await service.updateAuthProfile(
        displayName: '新しい名前',
        email: 'new@example.com',
        photoUrl: 'https://example.com/photo.png',
      );

      verify(
        () => mockAuthRepo.updateAuthProfile(
          displayName: '新しい名前',
          email: 'new@example.com',
          photoUrl: 'https://example.com/photo.png',
        ),
      ).called(1);
    });

    test('useFirebaseAuth: false の場合、何もしないこと', () async {
      final container = createContainer(useFirebaseAuth: false);
      final service = container.read(authServiceProvider);

      await service.updateAuthProfile(
        displayName: '新しい名前',
        email: 'new@example.com',
        photoUrl: 'https://example.com/photo.png',
      );

      verifyNever(
        () => mockAuthRepo.updateAuthProfile(
          displayName: any(named: 'displayName'),
          email: any(named: 'email'),
          photoUrl: any(named: 'photoUrl'),
        ),
      );
    });
  });

  group('AuthService.signOut', () {
    test('useFirebaseAuth: true の場合、Firebase signOut が呼ばれること', () async {
      final container = createContainer(useFirebaseAuth: true);
      final service = container.read(authServiceProvider);

      await service.signOut();

      verify(() => mockAuthRepo.signOut()).called(1);
    });

    test('useFirebaseAuth: false の場合、authState logout が呼ばれること', () async {
      final fakeAuthNotifier = FakeAuthStateNotifier();
      final container = ProviderContainer(
        overrides: [
          envConfigProvider.overrideWithValue(
            const EnvConfigState(
              baseUrl: 'https://test.example.com',
              imageBaseUrl: defaultImageBaseUrl,
              aiModel: 'test-model',
              connectTimeout: 10,
              receiveTimeout: 15,
              sendTimeout: 10,
              useFirebaseAuth: false,
              useAgentPlatform: true,
            ),
          ),
          loggerProvider.overrideWithValue(talker),
          firebaseAuthRepositoryProvider.overrideWithValue(mockAuthRepo),
          authStateProvider.overrideWith(() => fakeAuthNotifier),
        ],
      );
      addTearDown(container.dispose);

      final service = container.read(authServiceProvider);

      await service.signOut();

      check(fakeAuthNotifier.isLogoutCalled).equals(true);
      verifyNever(() => mockAuthRepo.signOut());
    });
  });
}
