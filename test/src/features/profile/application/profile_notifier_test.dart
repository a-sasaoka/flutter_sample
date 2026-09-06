import 'dart:io';

import 'package:checks/checks.dart';
import 'package:flutter_sample/src/core/config/env_config.dart';
import 'package:flutter_sample/src/core/exceptions/app_exception.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/auth/data/firebase_auth_repository.dart';
import 'package:flutter_sample/src/features/profile/application/profile_notifier.dart';
import 'package:flutter_sample/src/features/profile/data/profile_repository.dart';
import 'package:flutter_sample/src/features/profile/data/storage_service.dart';
import 'package:flutter_sample/src/features/profile/domain/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker_flutter/talker_flutter.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockFirebaseAuthRepository extends Mock
    implements FirebaseAuthRepository {}

class MockStorageService extends Mock implements StorageService {}

class MockFile extends Mock implements File {}

class FakeFile extends Fake implements File {}

class MockTalker extends Mock implements Talker {}

void main() {
  late MockProfileRepository mockProfileRepo;
  late MockFirebaseAuthRepository mockAuthRepo;
  late MockStorageService mockStorageService;
  late MockTalker mockTalker;

  const testProfile = UserProfile(
    name: 'テスト太郎',
    email: 'test@example.com',
    displayName: 'タロウ',
    phone: '09012345678',
  );

  setUpAll(() {
    registerFallbackValue(testProfile);
    registerFallbackValue(StackTrace.current);
    registerFallbackValue(FakeFile());
  });

  setUp(() {
    mockProfileRepo = MockProfileRepository();
    mockAuthRepo = MockFirebaseAuthRepository();
    mockStorageService = MockStorageService();
    mockTalker = MockTalker();

    // デフォルトのモック設定
    when(() => mockTalker.debug(any<dynamic>())).thenReturn(null);
    when(() => mockTalker.warning(any<dynamic>())).thenReturn(null);
    when(() => mockTalker.error(any<dynamic>())).thenReturn(null);
    when(
      () => mockTalker.handle(
        any<Object>(),
        any<StackTrace?>(),
        any<dynamic>(),
      ),
    ).thenReturn(null);
    when(
      () => mockProfileRepo.fetchProfile(),
    ).thenAnswer((_) async => testProfile);
    when(() => mockAuthRepo.currentUserId).thenReturn('test_uid');
  });

  ProviderContainer createContainer({
    required bool useAuth,
  }) {
    final container = ProviderContainer(
      overrides: [
        profileRepositoryProvider.overrideWithValue(mockProfileRepo),
        firebaseAuthRepositoryProvider.overrideWithValue(mockAuthRepo),
        storageServiceProvider.overrideWithValue(mockStorageService),
        envConfigProvider.overrideWithValue(
          EnvConfigState(
            baseUrl: 'https://test.example.com',
            imageBaseUrl: defaultImageBaseUrl,
            aiModel: 'test-model',
            connectTimeout: 10,
            receiveTimeout: 15,
            sendTimeout: 10,
            useFirebaseAuth: useAuth,
            useAgentPlatform: true,
          ),
        ),
        loggerProvider.overrideWithValue(mockTalker),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('ProfileNotifier Tests', () {
    test('build: 初期化時に fetchProfile を呼び出し、データを取得すること', () async {
      final container = createContainer(useAuth: false);

      // AutoDisposeなプロバイダーのため、listenして自動破棄を防ぐ
      final subscription = container.listen(profileProvider, (prev, next) {});

      final state = await container.read(profileProvider.future);

      check(state).equals(testProfile);
      verify(() => mockProfileRepo.fetchProfile()).called(1);
      subscription.close();
    });

    test('updateProfile: useFirebaseAuth: false の時、自前サーバーのみ更新すること', () async {
      final container = createContainer(useAuth: false);
      final subscription = container.listen(profileProvider, (prev, next) {});
      await container.read(profileProvider.future);

      const updated = UserProfile(
        name: '更新太郎',
        email: 'update@example.com',
        displayName: 'アップデート',
        phone: '08012345678',
      );

      when(
        () => mockProfileRepo.updateProfile(updated),
      ).thenAnswer((_) async => updated);

      // Act
      await container.read(profileProvider.notifier).updateProfile(updated);

      // Assert
      final state = container.read(profileProvider);
      check(state.value).equals(updated);

      verify(() => mockProfileRepo.updateProfile(updated)).called(1);
      verifyNever(
        () => mockAuthRepo.updateAuthProfile(
          displayName: any<String>(named: 'displayName'),
          email: any<String>(named: 'email'),
        ),
      );

      subscription.close();
    });

    test(
      'updateProfile: useFirebaseAuth: true の時、 '
      '自前サーバーと Firebase Auth の両方を更新すること',
      () async {
        final container = createContainer(useAuth: true);
        final subscription = container.listen(profileProvider, (prev, next) {});
        await container.read(profileProvider.future);

        const updated = UserProfile(
          name: '更新太郎',
          email: 'update@example.com',
          displayName: 'アップデート',
          phone: '08012345678',
        );

        when(
          () => mockProfileRepo.updateProfile(updated),
        ).thenAnswer((_) async => updated);
        when(
          () => mockAuthRepo.updateAuthProfile(
            displayName: updated.displayName,
            email: updated.email,
            photoUrl: any(named: 'photoUrl'),
          ),
        ).thenAnswer((_) async {});

        // Act
        await container.read(profileProvider.notifier).updateProfile(updated);

        // Assert
        final state = container.read(profileProvider);
        check(state.value).equals(updated);

        verify(() => mockProfileRepo.updateProfile(updated)).called(1);
        verify(
          () => mockAuthRepo.updateAuthProfile(
            displayName: updated.displayName,
            email: updated.email,
            photoUrl: any(named: 'photoUrl'),
          ),
        ).called(1);

        subscription.close();
      },
    );

    test(
      'updateProfile: プロフィールが未ロード（oldProfile が null）の時、 '
      '外部更新を行わずに AppException をスローすること',
      () async {
        final container = createContainer(useAuth: false);
        // 初期ロード（.future）を待たずに即座に updateProfile を実行
        final subscription = container.listen(profileProvider, (prev, next) {});

        await container
            .read(profileProvider.notifier)
            .updateProfile(testProfile);

        final state = container.read(profileProvider);
        check(state.hasError).isTrue();
        check(state.error).isA<AppException>();
        final error = state.error! as AppException;
        check(error).isA<UnknownException>();

        // 外部リポジトリやStorageへの更新・削除通信は一切行われないこと
        verifyNever(() => mockProfileRepo.updateProfile(any()));
        verifyNever(
          () => mockStorageService.uploadAvatar(
            userId: any(named: 'userId'),
            file: any(named: 'file'),
          ),
        );

        subscription.close();
      },
    );

    test('updateProfile: エラー発生時、AsyncError 状態になること', () async {
      final container = createContainer(useAuth: false);
      final subscription = container.listen(profileProvider, (prev, next) {});
      await container.read(profileProvider.future);

      final exception = Exception('Update failed');
      when(() => mockProfileRepo.updateProfile(any())).thenThrow(exception);

      // Act (非同期エラーテスト時は .future を待たずに notifier を直接実行します)
      await container.read(profileProvider.notifier).updateProfile(testProfile);

      // Assert (.futureを待つとデッドロックするため、状態プロパティで検証)
      final state = container.read(profileProvider);
      check(state.hasError).isTrue();
      check(state.error).equals(exception);

      subscription.close();
    });

    test(
      'updateProfile: Firebase Auth の更新に失敗したとき、ロールバックが実行され AsyncError になること',
      () async {
        final container = createContainer(useAuth: true);
        final subscription = container.listen(profileProvider, (prev, next) {});

        // 初期ロード完了を待機
        await container.read(profileProvider.future);

        final updated = testProfile.copyWith(displayName: '新しい名前');
        final exception = Exception('Auth Update failed');

        // mock setup
        when(
          () => mockProfileRepo.updateProfile(updated),
        ).thenAnswer((_) async => updated);
        when(
          () => mockAuthRepo.updateAuthProfile(
            displayName: updated.displayName,
            email: updated.email,
            photoUrl: any(named: 'photoUrl'),
          ),
        ).thenThrow(exception);
        // ロールバック（古いプロフィールに戻す）用のモック
        when(
          () => mockProfileRepo.updateProfile(testProfile),
        ).thenAnswer((_) async => testProfile);

        // Act
        await container.read(profileProvider.notifier).updateProfile(updated);

        // Assert
        final state = container.read(profileProvider);
        check(state.hasError).isTrue();
        check(state.error).equals(exception);

        // 1回目の更新とロールバック（2回目の更新）が両方呼ばれたことを確認
        verify(() => mockProfileRepo.updateProfile(updated)).called(1);
        verify(() => mockProfileRepo.updateProfile(testProfile)).called(1);

        subscription.close();
      },
    );

    test(
      'updateProfile: Firebase Auth の更新に失敗し、 '
      'さらに自前サーバーのロールバックにも失敗したとき、エラーがキャッチされ AsyncError になること',
      () async {
        final container = createContainer(useAuth: true);
        final subscription = container.listen(profileProvider, (prev, next) {});

        // 初期ロード完了を待機
        await container.read(profileProvider.future);

        final updated = testProfile.copyWith(displayName: '新しい名前');
        final exception = Exception('Auth Update failed');
        final rollbackException = Exception('Rollback failed');

        // mock setup
        when(
          () => mockProfileRepo.updateProfile(updated),
        ).thenAnswer((_) async => updated);
        when(
          () => mockAuthRepo.updateAuthProfile(
            displayName: updated.displayName,
            email: updated.email,
            photoUrl: any(named: 'photoUrl'),
          ),
        ).thenThrow(exception);
        // ロールバック自体も例外を投げて失敗するようにモック
        when(
          () => mockProfileRepo.updateProfile(testProfile),
        ).thenThrow(rollbackException);

        // Act
        await container.read(profileProvider.notifier).updateProfile(updated);

        // Assert
        final state = container.read(profileProvider);
        check(state.hasError).isTrue();
        check(
          state.error,
        ).equals(exception); // 元の Firebase Auth 側の例外が維持されて再スローされること

        // 1回目の更新とロールバック（2回目の更新）が両方呼ばれたことを確認
        verify(() => mockProfileRepo.updateProfile(updated)).called(1);
        verify(() => mockProfileRepo.updateProfile(testProfile)).called(1);
        verify(
          () => mockTalker.handle(
            rollbackException,
            any<StackTrace>(),
            any<String>(that: contains('Failed to rollback')),
          ),
        ).called(1);

        subscription.close();
      },
    );

    test(
      'updateProfile: useFirebaseAuth: true かつ currentUserId が null の時、 '
      'AppException.unauthenticated がスローされること',
      () async {
        // ログイン状態ではない（ユーザーIDが取得できない）状態をシミュレートします
        when(() => mockAuthRepo.currentUserId).thenReturn(null);
        final container = createContainer(useAuth: true);
        final subscription = container.listen(profileProvider, (prev, next) {});
        await container.read(profileProvider.future);

        // 実行：プロフィール更新を呼び出す
        await container
            .read(profileProvider.notifier)
            .updateProfile(testProfile);

        // 検証：未認証エラーになっていることを確認
        final state = container.read(profileProvider);
        check(state.hasError).isTrue();
        check(state.error).isA<AppException>();
        final error = state.error! as AppException;
        check(error).isA<UnauthenticatedException>();

        subscription.close();
      },
    );

    test(
      'updateProfile: useFirebaseAuth: true かつ avatarFile が渡された時、 '
      'Storage にアップロードして avatarUrl を更新し Auth にも同期すること',
      () async {
        final container = createContainer(useAuth: true);
        final subscription = container.listen(profileProvider, (prev, next) {});
        await container.read(profileProvider.future);

        final mockFile = MockFile();
        const uploadedUrl = 'https://storage.googleapis.com/avatar.jpg';
        final updated = testProfile.copyWith(avatarUrl: uploadedUrl);

        // モックの設定：Storageへのアップロードとサーバー・Authの更新
        when(
          () => mockStorageService.uploadAvatar(
            userId: 'test_uid',
            file: mockFile,
          ),
        ).thenAnswer((_) async => uploadedUrl);
        when(
          () => mockProfileRepo.updateProfile(updated),
        ).thenAnswer((_) async => updated);
        when(
          () => mockAuthRepo.updateAuthProfile(
            displayName: updated.displayName,
            email: updated.email,
            photoUrl: uploadedUrl,
          ),
        ).thenAnswer((_) async {});

        // 実行：アバターファイルを指定して更新
        await container
            .read(profileProvider.notifier)
            .updateProfile(
              testProfile,
              avatarFile: mockFile,
            );

        // 検証：状態が更新され、Storage・サーバー・Authの各処理が正しく呼ばれたこと
        final state = container.read(profileProvider);
        check(state.value).equals(updated);
        verify(
          () => mockStorageService.uploadAvatar(
            userId: 'test_uid',
            file: mockFile,
          ),
        ).called(1);
        verify(() => mockProfileRepo.updateProfile(updated)).called(1);
        verify(
          () => mockAuthRepo.updateAuthProfile(
            displayName: updated.displayName,
            email: updated.email,
            photoUrl: uploadedUrl,
          ),
        ).called(1);

        subscription.close();
      },
    );

    test(
      'updateProfile: useFirebaseAuth: true かつ deleteAvatar: true の時、 '
      'Storage から旧アバター画像を削除して avatarUrl を空文字にし Auth にも同期すること',
      () async {
        const initialProfile = UserProfile(
          name: 'テスト太郎',
          email: 'test@example.com',
          displayName: 'タロウ',
          phone: '09012345678',
          avatarUrl: 'https://storage.googleapis.com/old_avatar.jpg',
        );
        when(
          () => mockProfileRepo.fetchProfile(),
        ).thenAnswer((_) async => initialProfile);

        final container = createContainer(useAuth: true);
        final subscription = container.listen(profileProvider, (prev, next) {});
        await container.read(profileProvider.future);

        final updated = initialProfile.copyWith(avatarUrl: '');

        // モックの設定：Storageからの削除とサーバー・Authの更新
        when(
          () => mockStorageService.deleteAvatarByUrl(
            avatarUrl: 'https://storage.googleapis.com/old_avatar.jpg',
          ),
        ).thenAnswer((_) async {});
        when(
          () => mockProfileRepo.updateProfile(updated),
        ).thenAnswer((_) async => updated);
        when(
          () => mockAuthRepo.updateAuthProfile(
            displayName: updated.displayName,
            email: updated.email,
            photoUrl: '',
          ),
        ).thenAnswer((_) async {});

        // 実行：削除フラグを立てて更新
        await container
            .read(profileProvider.notifier)
            .updateProfile(
              initialProfile,
              deleteAvatar: true,
            );

        // 検証：アバターURLが空になり、各削除処理が呼ばれたこと
        final state = container.read(profileProvider);
        check(state.value).equals(updated);
        verify(
          () => mockStorageService.deleteAvatarByUrl(
            avatarUrl: 'https://storage.googleapis.com/old_avatar.jpg',
          ),
        ).called(1);
        verify(() => mockProfileRepo.updateProfile(updated)).called(1);
        verify(
          () => mockAuthRepo.updateAuthProfile(
            displayName: updated.displayName,
            email: updated.email,
            photoUrl: '',
          ),
        ).called(1);

        subscription.close();
      },
    );

    test(
      'updateProfile: useFirebaseAuth: true かつ 新規アバターアップロード成功時、 '
      '既存の旧アバター画像が存在すればそれが削除されること',
      () async {
        const initialProfile = UserProfile(
          name: 'テスト太郎',
          email: 'test@example.com',
          displayName: 'タロウ',
          phone: '09012345678',
          avatarUrl: 'https://storage.googleapis.com/old_avatar.jpg',
        );
        when(
          () => mockProfileRepo.fetchProfile(),
        ).thenAnswer((_) async => initialProfile);

        final container = createContainer(useAuth: true);
        final subscription = container.listen(profileProvider, (prev, next) {});
        await container.read(profileProvider.future);

        final mockFile = MockFile();
        const uploadedUrl = 'https://storage.googleapis.com/new_avatar.jpg';
        final updated = initialProfile.copyWith(avatarUrl: uploadedUrl);

        when(
          () => mockStorageService.uploadAvatar(
            userId: 'test_uid',
            file: mockFile,
          ),
        ).thenAnswer((_) async => uploadedUrl);
        when(
          () => mockProfileRepo.updateProfile(updated),
        ).thenAnswer((_) async => updated);
        when(
          () => mockAuthRepo.updateAuthProfile(
            displayName: updated.displayName,
            email: updated.email,
            photoUrl: uploadedUrl,
          ),
        ).thenAnswer((_) async {});
        when(
          () => mockStorageService.deleteAvatarByUrl(
            avatarUrl: 'https://storage.googleapis.com/old_avatar.jpg',
          ),
        ).thenAnswer((_) async {});

        // 実行：既存アバターがある状態で新アバターを保存
        await container
            .read(profileProvider.notifier)
            .updateProfile(
              initialProfile,
              avatarFile: mockFile,
            );

        final state = container.read(profileProvider);
        check(state.value).equals(updated);
        verify(
          () => mockStorageService.uploadAvatar(
            userId: 'test_uid',
            file: mockFile,
          ),
        ).called(1);
        verify(() => mockProfileRepo.updateProfile(updated)).called(1);
        verify(
          () => mockAuthRepo.updateAuthProfile(
            displayName: updated.displayName,
            email: updated.email,
            photoUrl: uploadedUrl,
          ),
        ).called(1);
        verify(
          () => mockStorageService.deleteAvatarByUrl(
            avatarUrl: 'https://storage.googleapis.com/old_avatar.jpg',
          ),
        ).called(1);

        subscription.close();
      },
    );

    test(
      'updateProfile: useFirebaseAuth: true かつ 旧アバターが gs:// 形式の時、 '
      'deleteAvatar: true で正しく旧画像が削除されること',
      () async {
        const initialProfile = UserProfile(
          name: 'テスト太郎',
          email: 'test@example.com',
          displayName: 'タロウ',
          phone: '09012345678',
          avatarUrl: 'gs://bucket/old_avatar.jpg',
        );
        when(
          () => mockProfileRepo.fetchProfile(),
        ).thenAnswer((_) async => initialProfile);

        final container = createContainer(useAuth: true);
        final subscription = container.listen(profileProvider, (prev, next) {});
        await container.read(profileProvider.future);

        final updated = initialProfile.copyWith(avatarUrl: '');

        when(
          () => mockStorageService.deleteAvatarByUrl(
            avatarUrl: 'gs://bucket/old_avatar.jpg',
          ),
        ).thenAnswer((_) async {});
        when(
          () => mockProfileRepo.updateProfile(updated),
        ).thenAnswer((_) async => updated);
        when(
          () => mockAuthRepo.updateAuthProfile(
            displayName: updated.displayName,
            email: updated.email,
            photoUrl: '',
          ),
        ).thenAnswer((_) async {});

        await container
            .read(profileProvider.notifier)
            .updateProfile(
              initialProfile,
              deleteAvatar: true,
            );

        final state = container.read(profileProvider);
        check(state.value).equals(updated);
        verify(
          () => mockStorageService.deleteAvatarByUrl(
            avatarUrl: 'gs://bucket/old_avatar.jpg',
          ),
        ).called(1);

        subscription.close();
      },
    );

    test(
      'updateProfile: useFirebaseAuth: false かつ avatarFile が渡された時、 '
      'ローカルファイルパスが保持され Storage 通信は行われないこと',
      () async {
        final container = createContainer(useAuth: false);
        final subscription = container.listen(profileProvider, (prev, next) {});
        await container.read(profileProvider.future);

        final mockFile = MockFile();
        when(() => mockFile.path).thenReturn('/path/to/local/avatar.jpg');
        final updated = testProfile.copyWith(
          avatarUrl: '/path/to/local/avatar.jpg',
        );

        when(
          () => mockProfileRepo.updateProfile(updated),
        ).thenAnswer((_) async => updated);

        // 実行：ローカルファイルを指定して更新
        await container
            .read(profileProvider.notifier)
            .updateProfile(
              testProfile,
              avatarFile: mockFile,
            );

        // 検証：Storageへの通信は行われず、ローカルパスが保存されること
        final state = container.read(profileProvider);
        check(state.value).equals(updated);
        verifyNever(
          () => mockStorageService.uploadAvatar(
            userId: any(named: 'userId'),
            file: any(named: 'file'),
          ),
        );
        verify(() => mockProfileRepo.updateProfile(updated)).called(1);

        subscription.close();
      },
    );

    test(
      'updateProfile: useFirebaseAuth: false かつ deleteAvatar: true の時、 '
      'avatarUrl が空文字になり Storage 通信は行われないこと',
      () async {
        final container = createContainer(useAuth: false);
        final subscription = container.listen(profileProvider, (prev, next) {});
        await container.read(profileProvider.future);

        const initialProfile = UserProfile(
          name: 'テスト太郎',
          email: 'test@example.com',
          displayName: 'タロウ',
          phone: '09012345678',
          avatarUrl: '/path/to/local/avatar.jpg',
        );
        final updated = initialProfile.copyWith(avatarUrl: '');

        when(
          () => mockProfileRepo.updateProfile(updated),
        ).thenAnswer((_) async => updated);

        // 実行：削除フラグを立てて更新
        await container
            .read(profileProvider.notifier)
            .updateProfile(
              initialProfile,
              deleteAvatar: true,
            );

        // 検証：Storageへの通信は行われず、アバターURLが空になること
        final state = container.read(profileProvider);
        check(state.value).equals(updated);
        verifyNever(
          () => mockStorageService.deleteAvatarByUrl(
            avatarUrl: any(named: 'avatarUrl'),
          ),
        );
        verify(() => mockProfileRepo.updateProfile(updated)).called(1);

        subscription.close();
      },
    );

    test(
      'updateProfile: useFirebaseAuth: true かつ avatarFile アップロード後に '
      'サーバー更新が失敗したとき、ロールバック削除が呼ばれ、その例外も処理されること',
      () async {
        final container = createContainer(useAuth: true);
        final subscription = container.listen(profileProvider, (prev, next) {});
        await container.read(profileProvider.future);

        final mockFile = MockFile();
        const uploadedUrl = 'https://storage.googleapis.com/avatar.jpg';
        final updated = testProfile.copyWith(avatarUrl: uploadedUrl);
        final serverException = Exception('Server update failed');
        final storageException = Exception('Storage delete failed');

        when(
          () => mockStorageService.uploadAvatar(
            userId: 'test_uid',
            file: mockFile,
          ),
        ).thenAnswer((_) async => uploadedUrl);
        when(
          () => mockProfileRepo.updateProfile(updated),
        ).thenThrow(serverException);
        when(
          () => mockStorageService.deleteAvatarByUrl(avatarUrl: uploadedUrl),
        ).thenThrow(storageException);

        await container
            .read(profileProvider.notifier)
            .updateProfile(
              testProfile,
              avatarFile: mockFile,
            );

        final state = container.read(profileProvider);
        check(state.hasError).isTrue();
        check(state.error).equals(serverException);

        verify(
          () => mockStorageService.deleteAvatarByUrl(avatarUrl: uploadedUrl),
        ).called(1);
        verify(
          () => mockTalker.handle(
            storageException,
            any<StackTrace>(),
            any<String>(that: contains('Failed to rollback uploaded avatar')),
          ),
        ).called(1);

        subscription.close();
      },
    );

    test(
      'updateProfile: useFirebaseAuth: true かつ avatarFile アップロード後に '
      'Auth更新が失敗したとき、ロールバック削除が呼ばれ、その例外も処理されること',
      () async {
        final container = createContainer(useAuth: true);
        final subscription = container.listen(profileProvider, (prev, next) {});
        await container.read(profileProvider.future);

        final mockFile = MockFile();
        const uploadedUrl = 'https://storage.googleapis.com/avatar.jpg';
        final updated = testProfile.copyWith(avatarUrl: uploadedUrl);
        final authException = Exception('Auth update failed');
        final storageException = Exception('Storage delete failed');

        when(
          () => mockStorageService.uploadAvatar(
            userId: 'test_uid',
            file: mockFile,
          ),
        ).thenAnswer((_) async => uploadedUrl);
        when(
          () => mockProfileRepo.updateProfile(updated),
        ).thenAnswer((_) async => updated);
        when(
          () => mockProfileRepo.updateProfile(testProfile),
        ).thenAnswer((_) async => testProfile);
        when(
          () => mockAuthRepo.updateAuthProfile(
            displayName: updated.displayName,
            email: updated.email,
            photoUrl: uploadedUrl,
          ),
        ).thenThrow(authException);
        when(
          () => mockStorageService.deleteAvatarByUrl(avatarUrl: uploadedUrl),
        ).thenThrow(storageException);

        await container
            .read(profileProvider.notifier)
            .updateProfile(
              testProfile,
              avatarFile: mockFile,
            );

        final state = container.read(profileProvider);
        check(state.hasError).isTrue();
        check(state.error).equals(authException);

        verify(() => mockProfileRepo.updateProfile(testProfile)).called(1);
        verify(
          () => mockStorageService.deleteAvatarByUrl(avatarUrl: uploadedUrl),
        ).called(1);
        verify(
          () => mockTalker.handle(
            storageException,
            any<StackTrace>(),
            any<String>(that: contains('Failed to rollback uploaded avatar')),
          ),
        ).called(1);

        subscription.close();
      },
    );

    test(
      'updateProfile: useFirebaseAuth: true かつ Auth更新後にサーバーロールバックも失敗したとき、 '
      '新画像は削除されず保持されること',
      () async {
        final container = createContainer(useAuth: true);
        final subscription = container.listen(profileProvider, (prev, next) {});
        await container.read(profileProvider.future);

        final mockFile = MockFile();
        const uploadedUrl = 'https://storage.googleapis.com/avatar.jpg';
        final updated = testProfile.copyWith(avatarUrl: uploadedUrl);
        final authException = Exception('Auth update failed');
        final serverRollbackException = Exception('Server rollback failed');

        when(
          () => mockStorageService.uploadAvatar(
            userId: 'test_uid',
            file: mockFile,
          ),
        ).thenAnswer((_) async => uploadedUrl);
        when(
          () => mockProfileRepo.updateProfile(updated),
        ).thenAnswer((_) async => updated);
        when(
          () => mockAuthRepo.updateAuthProfile(
            displayName: updated.displayName,
            email: updated.email,
            photoUrl: uploadedUrl,
          ),
        ).thenThrow(authException);
        when(
          () => mockProfileRepo.updateProfile(testProfile),
        ).thenThrow(serverRollbackException);

        await container
            .read(profileProvider.notifier)
            .updateProfile(
              testProfile,
              avatarFile: mockFile,
            );

        final state = container.read(profileProvider);
        check(state.hasError).isTrue();
        check(state.error).equals(authException);

        // サーバーロールバックが試みられたことを確認
        verify(() => mockProfileRepo.updateProfile(testProfile)).called(1);
        // サーバーロールバック失敗時は新画像削除が呼ばれず、保持されること
        verifyNever(
          () => mockStorageService.deleteAvatarByUrl(
            avatarUrl: any(named: 'avatarUrl'),
          ),
        );
        verify(
          () => mockTalker.handle(
            serverRollbackException,
            any<StackTrace>(),
            any<String>(that: contains('Failed to rollback server update')),
          ),
        ).called(1);

        subscription.close();
      },
    );

    test(
      'updateProfile: useFirebaseAuth: true かつ deleteAvatar 完了後の '
      'Storage削除で例外が発生しても、エラーが処理され正常終了すること',
      () async {
        const initialProfile = UserProfile(
          name: 'テスト太郎',
          email: 'test@example.com',
          displayName: 'タロウ',
          phone: '09012345678',
          avatarUrl: 'https://storage.googleapis.com/old_avatar.jpg',
        );
        when(
          () => mockProfileRepo.fetchProfile(),
        ).thenAnswer((_) async => initialProfile);

        final container = createContainer(useAuth: true);
        final subscription = container.listen(profileProvider, (prev, next) {});
        await container.read(profileProvider.future);

        final updated = initialProfile.copyWith(avatarUrl: '');
        final storageException = Exception('Storage delete failed');

        when(
          () => mockProfileRepo.updateProfile(updated),
        ).thenAnswer((_) async => updated);
        when(
          () => mockAuthRepo.updateAuthProfile(
            displayName: updated.displayName,
            email: updated.email,
            photoUrl: '',
          ),
        ).thenAnswer((_) async {});
        when(
          () => mockStorageService.deleteAvatarByUrl(
            avatarUrl: 'https://storage.googleapis.com/old_avatar.jpg',
          ),
        ).thenThrow(storageException);

        await container
            .read(profileProvider.notifier)
            .updateProfile(
              initialProfile,
              deleteAvatar: true,
            );

        final state = container.read(profileProvider);
        check(state.value).equals(updated);

        verify(
          () => mockStorageService.deleteAvatarByUrl(
            avatarUrl: 'https://storage.googleapis.com/old_avatar.jpg',
          ),
        ).called(1);
        verify(
          () => mockTalker.handle(
            storageException,
            any<StackTrace>(),
            any<String>(that: contains('Failed to delete old avatar')),
          ),
        ).called(1);

        subscription.close();
      },
    );
  });
}
