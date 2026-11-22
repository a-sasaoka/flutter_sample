import 'package:checks/checks.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_sample/src/core/analytics/analytics_event.dart';
import 'package:flutter_sample/src/core/analytics/analytics_service.dart';
import 'package:flutter_sample/src/core/config/env_config.dart';
import 'package:flutter_sample/src/core/exceptions/app_exception.dart';
import 'package:flutter_sample/src/core/exceptions/reauth_exception.dart';
import 'package:flutter_sample/src/core/services/lock_suppression_handler.dart';
import 'package:flutter_sample/src/core/storage/cache_manager.dart';
import 'package:flutter_sample/src/core/utils/date_time_provider.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/auth/application/account_deletion_notice_notifier.dart';
import 'package:flutter_sample/src/features/auth/application/auth_service.dart';
import 'package:flutter_sample/src/features/auth/application/auth_state_notifier.dart';
import 'package:flutter_sample/src/features/auth/application/firebase_auth_state_notifier.dart';
import 'package:flutter_sample/src/features/auth/data/auth_repository.dart';
import 'package:flutter_sample/src/features/auth/data/firebase_auth_repository.dart';
import 'package:flutter_sample/src/features/auth/data/token_storage.dart';
import 'package:flutter_sample/src/features/auth/domain/account_deletion_precheck.dart';
import 'package:flutter_sample/src/features/memos/data/memo_repository.dart';
import 'package:flutter_sample/src/features/profile/data/profile_repository.dart';
import 'package:flutter_sample/src/features/profile/data/storage_service.dart';
import 'package:flutter_sample/src/features/profile/domain/user_profile.dart';
import 'package:flutter_sample/src/features/qr_scanner/data/qr_scan_histories_dao.dart';
import 'package:flutter_sample/src/features/user/data/user_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker_flutter/talker_flutter.dart';

class MockFirebaseAuthRepository extends Mock
    implements FirebaseAuthRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockStorageService extends Mock implements StorageService {}

class MockMemoRepository extends Mock implements MemoRepository {}

class MockQrScanHistoriesDao extends Mock implements QrScanHistoriesDao {}

class MockCacheManager extends Mock implements CacheManager {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockUser extends Mock implements User {}

class MockTokenStorage extends Mock implements TokenStorage {}

class _SpyTalker extends Talker {
  _SpyTalker() : super(settings: TalkerSettings(enabled: false));

  final List<Object> handleExceptions = [];

  @override
  void handle(Object exception, [StackTrace? stackTrace, dynamic msg]) {
    handleExceptions.add(exception);
    super.handle(exception, stackTrace, msg);
  }
}

class FakeAuthStateNotifier extends AuthStateNotifier {
  FakeAuthStateNotifier({this.initial = true});

  final bool initial;
  bool isLogoutCalled = false;
  bool isDeleteAccountCalled = false;
  bool deleteAccountResult = true;
  Exception? deleteAccountError;
  VoidCallback? onDeleteAccount;

  @override
  Future<bool> build() async => initial;

  @override
  Future<void> logout() async {
    isLogoutCalled = true;
    state = const AsyncData(false);
  }

  @override
  Future<bool> deleteAccount() async {
    onDeleteAccount?.call();
    if (deleteAccountError != null) {
      throw deleteAccountError!;
    }
    isDeleteAccountCalled = true;
    if (deleteAccountResult) {
      state = const AsyncData(false);
    }
    return deleteAccountResult;
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
  late MockAuthRepository mockCustomAuthRepo;
  late MockProfileRepository mockProfileRepo;
  late MockStorageService mockStorageService;
  late MockMemoRepository mockMemoRepo;
  late MockQrScanHistoriesDao mockQrDao;
  late MockCacheManager mockCacheManager;
  late MockAnalyticsService mockAnalyticsService;
  late MockTokenStorage mockTokenStorage;
  late Talker talker;
  late DateTime fixedNow;

  setUpAll(() {
    registerFallbackValue(AnalyticsEvent.accountDeleted);
  });

  setUp(() {
    mockAuthRepo = MockFirebaseAuthRepository();
    mockCustomAuthRepo = MockAuthRepository();
    mockProfileRepo = MockProfileRepository();
    mockStorageService = MockStorageService();
    mockMemoRepo = MockMemoRepository();
    mockQrDao = MockQrScanHistoriesDao();
    mockCacheManager = MockCacheManager();
    mockAnalyticsService = MockAnalyticsService();
    mockTokenStorage = MockTokenStorage();
    fixedNow = DateTime.utc(2026, 11, 22, 9);
    talker = TalkerFlutter.init(
      settings: TalkerSettings(useConsoleLogs: false),
    );

    when(() => mockAuthRepo.signOut()).thenAnswer((_) async {});
    when(() => mockTokenStorage.getUserId()).thenAnswer((_) async => null);
    when(
      () => mockAnalyticsService.logEvent(
        event: any(named: 'event'),
        parameters: any(named: 'parameters'),
      ),
    ).thenAnswer((_) async {});
  });

  ProviderContainer createContainer({
    required bool useFirebaseAuth,
    User? firebaseUser,
    bool authStateValue = true,
    TokenStorage? tokenStorage,
    FakeAuthStateNotifier? fakeAuthNotifier,
    LockSuppressionRunner? lockSuppressionRunner,
  }) {
    final effectiveTokenStorage = tokenStorage ?? mockTokenStorage;
    final notifier =
        fakeAuthNotifier ?? FakeAuthStateNotifier(initial: authStateValue);
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
        authRepositoryProvider.overrideWithValue(mockCustomAuthRepo),
        profileRepositoryProvider.overrideWithValue(mockProfileRepo),
        storageServiceProvider.overrideWithValue(mockStorageService),
        memoRepositoryProvider.overrideWithValue(mockMemoRepo),
        qrScanHistoriesDaoProvider.overrideWithValue(mockQrDao),
        cacheManagerProvider.overrideWithValue(mockCacheManager),
        analyticsServiceProvider.overrideWithValue(mockAnalyticsService),
        clockProvider.overrideWithValue(() => fixedNow),
        if (lockSuppressionRunner != null)
          lockSuppressionRunnerProvider.overrideWithValue(
            lockSuppressionRunner,
          ),
        tokenStorageProvider.overrideWithValue(effectiveTokenStorage),
        firebaseAuthStateProvider.overrideWith(
          () => FakeFirebaseAuthStateNotifier(firebaseUser),
        ),
        authStateProvider.overrideWith(() => notifier),
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
      final container = createContainer(
        useFirebaseAuth: false,
        fakeAuthNotifier: fakeAuthNotifier,
      );

      final service = container.read(authServiceProvider);

      await service.signOut();

      check(fakeAuthNotifier.isLogoutCalled).equals(true);
      verifyNever(() => mockAuthRepo.signOut());
    });
  });

  group('AuthService (checkReauthRequirement / reauthenticate)', () {
    test('checkReauthRequirement: Firebase版で鮮度・プロバイダ・メールを返すこと', () async {
      when(() => mockAuthRepo.needsRecentLogin(fixedNow)).thenReturn(true);
      when(
        () => mockAuthRepo.getAvailableReauthMethods(),
      ).thenReturn({ReauthMethod.password, ReauthMethod.google});
      when(() => mockAuthRepo.currentUserEmail).thenReturn('fb@example.com');

      final container = createContainer(useFirebaseAuth: true);
      final result = await container
          .read(authServiceProvider)
          .checkReauthRequirement();

      check(result).equals(
        const AccountDeletionPrecheck(
          requiresReauthentication: true,
          availableMethods: {ReauthMethod.password, ReauthMethod.google},
          email: 'fb@example.com',
        ),
      );
    });

    test('checkReauthRequirement: カスタム認証版で常にパスワード再認証を要求すること', () async {
      when(
        () => mockCustomAuthRepo.getCurrentEmail(),
      ).thenAnswer((_) async => 'custom@example.com');

      final container = createContainer(useFirebaseAuth: false);
      final result = await container
          .read(authServiceProvider)
          .checkReauthRequirement();

      check(result).equals(
        const AccountDeletionPrecheck(
          requiresReauthentication: true,
          availableMethods: {ReauthMethod.password},
          email: 'custom@example.com',
        ),
      );
    });

    test('reauthenticateWithPassword: Firebase版とカスタム版それぞれ適切に委譲されること', () async {
      when(
        () => mockAuthRepo.reauthenticateWithPassword(
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => mockCustomAuthRepo.reauthenticate(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => mockCustomAuthRepo.getCurrentEmail(),
      ).thenAnswer((_) async => 'token@example.com');

      // Firebase
      final fbContainer = createContainer(useFirebaseAuth: true);
      await fbContainer
          .read(authServiceProvider)
          .reauthenticateWithPassword(password: 'secret');
      verify(
        () => mockAuthRepo.reauthenticateWithPassword(password: 'secret'),
      ).called(1);

      // カスタム認証（明示メールをtrimして使用）
      final customContainer = createContainer(useFirebaseAuth: false);
      await customContainer
          .read(authServiceProvider)
          .reauthenticateWithPassword(
            password: 'secret',
            email: '  explicit@example.com ',
          );
      verify(
        () => mockCustomAuthRepo.reauthenticate(
          email: 'explicit@example.com',
          password: 'secret',
        ),
      ).called(1);

      // カスタム認証（メール省略時はトークンから解決）
      await customContainer
          .read(authServiceProvider)
          .reauthenticateWithPassword(password: 'secret', email: '  ');
      verify(
        () => mockCustomAuthRepo.reauthenticate(
          email: 'token@example.com',
          password: 'secret',
        ),
      ).called(1);

      // カスタム認証（メール未取得時は ReauthMissingEmailException）
      when(
        () => mockCustomAuthRepo.getCurrentEmail(),
      ).thenAnswer((_) async => null);
      await check(
        customContainer
            .read(authServiceProvider)
            .reauthenticateWithPassword(password: 'secret'),
      ).throws<ReauthMissingEmailException>();
    });

    test('reauthenticateWithGoogle: '
        'Firebase版はロック抑止付きで実行し、カスタム版は認可エラーになること', () async {
      var lockSuppressionCalls = 0;
      when(
        () => mockAuthRepo.reauthenticateWithGoogle(),
      ).thenAnswer((_) async {});

      final fbContainer = createContainer(
        useFirebaseAuth: true,
        lockSuppressionRunner:
            <T>(
              Future<T> Function() action, {
              bool Function(T result)? isSuccess,
            }) {
              lockSuppressionCalls++;
              return action();
            },
      );

      await fbContainer.read(authServiceProvider).reauthenticateWithGoogle();
      check(lockSuppressionCalls).equals(1);
      verify(() => mockAuthRepo.reauthenticateWithGoogle()).called(1);

      final customContainer = createContainer(useFirebaseAuth: false);
      await check(
        customContainer.read(authServiceProvider).reauthenticateWithGoogle(),
      ).throws<UnauthorizedException>();
    });
  });

  group('AuthService.deleteAccount', () {
    void stubHappyLocalCleanups({List<String>? callOrder}) {
      when(() => mockMemoRepo.deleteAllMemosByUser(any())).thenAnswer((
        _,
      ) async {
        callOrder?.add('local_memos');
        return 3;
      });
      when(() => mockQrDao.deleteAllHistories()).thenAnswer((_) async {
        callOrder?.add('local_qr');
        return 2;
      });
      when(() => mockCacheManager.clear(UserRepository.cacheKey)).thenAnswer((
        _,
      ) async {
        callOrder?.add('local_cache');
      });
    }

    test('未ログイン時（Firebase / カスタム）は UnauthenticatedException を投げること', () async {
      when(() => mockAuthRepo.currentUserId).thenReturn(null);
      final fbContainer = createContainer(useFirebaseAuth: true);
      await check(
        fbContainer.read(authServiceProvider).deleteAccount(),
      ).throws<UnauthenticatedException>();

      when(() => mockTokenStorage.getUserId()).thenAnswer((_) async => '');
      final customContainer = createContainer(useFirebaseAuth: false);
      await check(
        customContainer.read(authServiceProvider).deleteAccount(),
      ).throws<UnauthenticatedException>();
    });

    test('Firebase版正常系: Storage ➔ サーバーDB ➔ Analytics ➔ Auth削除 ➔ '
        'ローカル全削除の順で実行し、退会通知フラグが立つこと', () async {
      final callOrder = <String>[];
      const duplicateUrl =
          'https://firebasestorage.googleapis.com/v0/b/demo/o/avatar.jpg';

      when(() => mockAuthRepo.currentUserId).thenReturn('uid-1');
      when(() => mockAuthRepo.currentUserPhotoUrl).thenReturn(duplicateUrl);
      when(() => mockProfileRepo.fetchProfile()).thenAnswer((_) async {
        callOrder.add('fetch_profile');
        return const UserProfile(
          name: '太郎',
          email: 'a@example.com',
          avatarUrl: duplicateUrl,
        );
      });
      when(
        () => mockStorageService.deleteAvatarByUrl(avatarUrl: duplicateUrl),
      ).thenAnswer((_) async {
        callOrder.add('storage');
      });
      when(() => mockProfileRepo.deleteMyAccountData()).thenAnswer((_) async {
        callOrder.add('server_db');
      });
      when(
        () =>
            mockAnalyticsService.logEvent(event: AnalyticsEvent.accountDeleted),
      ).thenAnswer((_) async {
        callOrder.add('analytics');
      });
      when(() => mockAuthRepo.deleteAccount()).thenAnswer((_) async {
        callOrder.add('firebase_auth');
      });
      stubHappyLocalCleanups(callOrder: callOrder);

      final container = createContainer(useFirebaseAuth: true);
      await container.read(authServiceProvider).deleteAccount();

      verify(
        () => mockStorageService.deleteAvatarByUrl(avatarUrl: duplicateUrl),
      ).called(1);
      check(callOrder).deepEquals([
        'fetch_profile',
        'storage',
        'server_db',
        'firebase_auth',
        'local_memos',
        'local_qr',
        'local_cache',
        'analytics',
      ]);
      check(container.read(accountDeletionNoticeProvider)).isTrue();
    });

    test(
      'Firebase版: fetchProfile が 404 の場合はサーバー側アバター参照をスキップし、退会を完了すること',
      () async {
        when(() => mockAuthRepo.currentUserId).thenReturn('uid-404');
        when(() => mockAuthRepo.currentUserPhotoUrl).thenReturn(null);
        when(() => mockProfileRepo.fetchProfile()).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/users/me'),
            error: const AppException.badRequest(statusCode: 404),
          ),
        );
        when(
          () => mockProfileRepo.deleteMyAccountData(),
        ).thenAnswer((_) async {});
        when(() => mockAuthRepo.deleteAccount()).thenAnswer((_) async {});
        stubHappyLocalCleanups();

        final container = createContainer(useFirebaseAuth: true);
        await check(
          container.read(authServiceProvider).deleteAccount(),
        ).completes();

        verifyNever(
          () => mockStorageService.deleteAvatarByUrl(
            avatarUrl: any(named: 'avatarUrl'),
          ),
        );
        verify(() => mockAuthRepo.deleteAccount()).called(1);
        check(container.read(accountDeletionNoticeProvider)).isTrue();
      },
    );

    test(
      'Firebase版: fetchProfile が 404 以外のエラーの場合は Storage・DB・Auth削除へ進まず中断すること',
      () async {
        when(() => mockAuthRepo.currentUserId).thenReturn('uid-err');
        when(() => mockAuthRepo.currentUserPhotoUrl).thenReturn(null);
        when(() => mockProfileRepo.fetchProfile()).thenThrow(
          DioException(requestOptions: RequestOptions(path: '/users/me')),
        );

        final container = createContainer(useFirebaseAuth: true);
        await check(
          container.read(authServiceProvider).deleteAccount(),
        ).throws<DioException>();

        verifyNever(() => mockProfileRepo.deleteMyAccountData());
        verifyNever(() => mockAuthRepo.deleteAccount());
      },
    );

    test(
      'Firebase版: ① Storage削除失敗時は ② サーバーDB・③ Auth・④ ローカルへ進まず中断すること',
      () async {
        when(() => mockAuthRepo.currentUserId).thenReturn('uid-st-fail');
        when(
          () => mockAuthRepo.currentUserPhotoUrl,
        ).thenReturn('https://firebasestorage.googleapis.com/a.jpg');
        when(() => mockProfileRepo.fetchProfile()).thenAnswer(
          (_) async => const UserProfile(name: '太郎', email: 'a@example.com'),
        );
        when(
          () => mockStorageService.deleteAvatarByUrl(
            avatarUrl: any(named: 'avatarUrl'),
          ),
        ).thenThrow(const AppException.server(message: 'Storage error'));

        final container = createContainer(useFirebaseAuth: true);
        await check(
          container.read(authServiceProvider).deleteAccount(),
        ).throws<ServerException>();

        verifyNever(() => mockProfileRepo.deleteMyAccountData());
        verifyNever(() => mockAuthRepo.deleteAccount());
        verifyNever(() => mockMemoRepo.deleteAllMemosByUser(any()));
        check(container.read(accountDeletionNoticeProvider)).isFalse();
      },
    );

    test('② サーバーDB削除失敗時は ③ Auth・④ ローカルへ進まず中断すること', () async {
      when(() => mockAuthRepo.currentUserId).thenReturn('uid-db-fail');
      when(() => mockAuthRepo.currentUserPhotoUrl).thenReturn(null);
      when(
        () => mockProfileRepo.fetchProfile(),
      ).thenThrow(const AppException.badRequest(statusCode: 404));
      when(
        () => mockProfileRepo.deleteMyAccountData(),
      ).thenThrow(const AppException.server(statusCode: 500));

      final container = createContainer(useFirebaseAuth: true);
      await check(
        container.read(authServiceProvider).deleteAccount(),
      ).throws<ServerException>();

      verifyNever(() => mockAuthRepo.deleteAccount());
      verifyNever(() => mockMemoRepo.deleteAllMemosByUser(any()));
      check(container.read(accountDeletionNoticeProvider)).isFalse();
    });

    test('Analytics記録が失敗しても退会フローは継続し完了すること', () async {
      when(() => mockAuthRepo.currentUserId).thenReturn('uid-analytics');
      when(() => mockAuthRepo.currentUserPhotoUrl).thenReturn(null);
      when(() => mockProfileRepo.fetchProfile()).thenAnswer(
        (_) async => const UserProfile(name: '太郎', email: 'a@example.com'),
      );
      when(
        () => mockProfileRepo.deleteMyAccountData(),
      ).thenAnswer((_) async {});
      when(
        () =>
            mockAnalyticsService.logEvent(event: AnalyticsEvent.accountDeleted),
      ).thenThrow(Exception('Analytics failure'));
      when(() => mockAuthRepo.deleteAccount()).thenAnswer((_) async {});
      stubHappyLocalCleanups();

      final container = createContainer(useFirebaseAuth: true);
      await check(
        container.read(authServiceProvider).deleteAccount(),
      ).completes();

      verify(() => mockAuthRepo.deleteAccount()).called(1);
      verify(
        () => mockMemoRepo.deleteAllMemosByUser('uid-analytics'),
      ).called(1);
      check(container.read(accountDeletionNoticeProvider)).isTrue();
    });

    test('③ Firebase Auth削除で ReauthRequiresRecentLoginException が起きた場合、 '
        '通知フラグをクリアし、④ ローカル削除を実行せず再スローすること', () async {
      when(() => mockAuthRepo.currentUserId).thenReturn('uid-reauth');
      when(() => mockAuthRepo.currentUserPhotoUrl).thenReturn(null);
      when(() => mockProfileRepo.fetchProfile()).thenAnswer(
        (_) async => const UserProfile(name: '太郎', email: 'a@example.com'),
      );
      when(
        () => mockProfileRepo.deleteMyAccountData(),
      ).thenAnswer((_) async {});
      when(
        () => mockAuthRepo.deleteAccount(),
      ).thenThrow(const ReauthRequiresRecentLoginException());

      final container = createContainer(useFirebaseAuth: true);
      await check(
        container.read(authServiceProvider).deleteAccount(),
      ).throws<ReauthRequiresRecentLoginException>();

      verifyNever(() => mockMemoRepo.deleteAllMemosByUser(any()));
      verifyNever(() => mockQrDao.deleteAllHistories());
      verifyNever(() => mockCacheManager.clear(any()));
      verifyNever(
        () => mockAnalyticsService.logEvent(
          event: any(named: 'event'),
          parameters: any(named: 'parameters'),
        ),
      );
      check(container.read(accountDeletionNoticeProvider)).isFalse();
    });

    test('③ Auth削除で予期せぬ例外が起きた場合、通知フラグをクリアし、④ ローカル削除を実行せず再スローすること', () async {
      when(() => mockAuthRepo.currentUserId).thenReturn('uid-auth-err');
      when(() => mockAuthRepo.currentUserPhotoUrl).thenReturn(null);
      when(() => mockProfileRepo.fetchProfile()).thenAnswer(
        (_) async => const UserProfile(name: '太郎', email: 'a@example.com'),
      );
      when(
        () => mockProfileRepo.deleteMyAccountData(),
      ).thenAnswer((_) async {});
      when(
        () => mockAuthRepo.deleteAccount(),
      ).thenThrow(Exception('Unexpected auth failure'));

      final container = createContainer(useFirebaseAuth: true);
      await check(
        container.read(authServiceProvider).deleteAccount(),
      ).throws<Exception>();

      verifyNever(() => mockMemoRepo.deleteAllMemosByUser(any()));
      check(container.read(accountDeletionNoticeProvider)).isFalse();
    });

    test('④ ローカルクリーンアップの一部が失敗しても、残りのクリーンアップを実行して完了すること', () async {
      when(() => mockAuthRepo.currentUserId).thenReturn('uid-local-err');
      when(() => mockAuthRepo.currentUserPhotoUrl).thenReturn(null);
      when(() => mockProfileRepo.fetchProfile()).thenAnswer(
        (_) async => const UserProfile(name: '太郎', email: 'a@example.com'),
      );
      when(
        () => mockProfileRepo.deleteMyAccountData(),
      ).thenAnswer((_) async {});
      when(() => mockAuthRepo.deleteAccount()).thenAnswer((_) async {});
      when(
        () => mockMemoRepo.deleteAllMemosByUser('uid-local-err'),
      ).thenThrow(Exception('Drift failure'));
      when(
        () => mockQrDao.deleteAllHistories(),
      ).thenThrow(Exception('QR delete failure'));
      when(
        () => mockCacheManager.clear(UserRepository.cacheKey),
      ).thenAnswer((_) async {});

      final container = createContainer(useFirebaseAuth: true);
      await check(
        container.read(authServiceProvider).deleteAccount(),
      ).completes();

      verify(() => mockCacheManager.clear(UserRepository.cacheKey)).called(1);
      check(container.read(accountDeletionNoticeProvider)).isTrue();
    });

    test(
      'カスタム認証版正常系: Storageをスキップし、サーバーDB ➔ AuthStateNotifier削除 ➔ ローカル全削除が完了すること',
      () async {
        final callOrder = <String>[];
        final fakeAuthNotifier = FakeAuthStateNotifier()
          ..onDeleteAccount = () => callOrder.add('custom_auth');

        when(
          () => mockTokenStorage.getUserId(),
        ).thenAnswer((_) async => 'custom-uid-1');
        when(() => mockProfileRepo.deleteMyAccountData()).thenAnswer((_) async {
          callOrder.add('server_db');
        });
        when(
          () => mockAnalyticsService.logEvent(
            event: AnalyticsEvent.accountDeleted,
          ),
        ).thenAnswer((_) async {
          callOrder.add('analytics');
        });
        stubHappyLocalCleanups(callOrder: callOrder);

        final container = createContainer(
          useFirebaseAuth: false,
          fakeAuthNotifier: fakeAuthNotifier,
        );
        await container.read(authServiceProvider).deleteAccount();

        verifyNever(() => mockProfileRepo.fetchProfile());
        verifyNever(
          () => mockStorageService.deleteAvatarByUrl(
            avatarUrl: any(named: 'avatarUrl'),
          ),
        );
        verifyNever(() => mockAuthRepo.deleteAccount());
        check(fakeAuthNotifier.isDeleteAccountCalled).isTrue();
        check(callOrder).deepEquals([
          'server_db',
          'custom_auth',
          'local_memos',
          'local_qr',
          'local_cache',
          'analytics',
        ]);
        check(container.read(accountDeletionNoticeProvider)).isTrue();
      },
    );

    test('カスタム認証版: 別アカウントへ切り替わり対象セッションを終了しない(false)場合、 '
        '完了通知を取り消し共有QR履歴・ユーザーキャッシュを消去せず対象ユーザーのメモのみ削除すること', () async {
      final fakeAuthNotifier = FakeAuthStateNotifier()
        ..deleteAccountResult = false;

      when(
        () => mockTokenStorage.getUserId(),
      ).thenAnswer((_) async => 'custom-uid-1');
      when(
        () => mockProfileRepo.deleteMyAccountData(),
      ).thenAnswer((_) async {});
      stubHappyLocalCleanups();

      final container = createContainer(
        useFirebaseAuth: false,
        fakeAuthNotifier: fakeAuthNotifier,
      );
      await container.read(authServiceProvider).deleteAccount();

      check(fakeAuthNotifier.isDeleteAccountCalled).isTrue();
      check(container.read(authStateProvider).value).equals(true);
      check(container.read(accountDeletionNoticeProvider)).isFalse();
      verify(() => mockMemoRepo.deleteAllMemosByUser('custom-uid-1')).called(1);
      verify(
        () =>
            mockAnalyticsService.logEvent(event: AnalyticsEvent.accountDeleted),
      ).called(1);
      verifyNever(() => mockQrDao.deleteAllHistories());
      verifyNever(() => mockCacheManager.clear(UserRepository.cacheKey));
    });

    test('② deleteMyAccountData が ReauthRequiresRecentLoginException を投げた場合、 '
        'Crashlytics へ記録せず再スローし、再認証後の再試行で完了すること', () async {
      final spyTalker = _SpyTalker();
      var attempts = 0;

      when(() => mockAuthRepo.currentUserId).thenReturn('uid-server-reauth');
      when(() => mockAuthRepo.currentUserPhotoUrl).thenReturn(null);
      when(() => mockProfileRepo.fetchProfile()).thenAnswer(
        (_) async => const UserProfile(name: '太郎', email: 'a@example.com'),
      );
      when(() => mockProfileRepo.deleteMyAccountData()).thenAnswer((_) async {
        attempts++;
        if (attempts == 1) {
          throw const ReauthRequiresRecentLoginException();
        }
      });
      when(() => mockAuthRepo.deleteAccount()).thenAnswer((_) async {});
      stubHappyLocalCleanups();

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
              useFirebaseAuth: true,
              useAgentPlatform: true,
            ),
          ),
          loggerProvider.overrideWithValue(spyTalker),
          firebaseAuthRepositoryProvider.overrideWithValue(mockAuthRepo),
          authRepositoryProvider.overrideWithValue(mockCustomAuthRepo),
          profileRepositoryProvider.overrideWithValue(mockProfileRepo),
          storageServiceProvider.overrideWithValue(mockStorageService),
          memoRepositoryProvider.overrideWithValue(mockMemoRepo),
          qrScanHistoriesDaoProvider.overrideWithValue(mockQrDao),
          cacheManagerProvider.overrideWithValue(mockCacheManager),
          analyticsServiceProvider.overrideWithValue(mockAnalyticsService),
          clockProvider.overrideWithValue(() => fixedNow),
          tokenStorageProvider.overrideWithValue(mockTokenStorage),
          firebaseAuthStateProvider.overrideWith(
            () => FakeFirebaseAuthStateNotifier(null),
          ),
          authStateProvider.overrideWith(FakeAuthStateNotifier.new),
        ],
      );
      addTearDown(container.dispose);

      await check(
        container.read(authServiceProvider).deleteAccount(),
      ).throws<ReauthRequiresRecentLoginException>();

      check(spyTalker.handleExceptions).isEmpty();
      verifyNever(() => mockAuthRepo.deleteAccount());
      verifyNever(() => mockMemoRepo.deleteAllMemosByUser(any()));
      check(container.read(accountDeletionNoticeProvider)).isFalse();

      // 再試行時は 2 回目の deleteMyAccountData が成功し、退会が完了すること
      await check(
        container.read(authServiceProvider).deleteAccount(),
      ).completes();
      verify(() => mockAuthRepo.deleteAccount()).called(1);
      verify(
        () => mockMemoRepo.deleteAllMemosByUser('uid-server-reauth'),
      ).called(1);
      check(container.read(accountDeletionNoticeProvider)).isTrue();
    });
  });
}
