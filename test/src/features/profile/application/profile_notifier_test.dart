import 'package:checks/checks.dart';
import 'package:flutter_sample/src/core/config/env_config.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/auth/data/firebase_auth_repository.dart';
import 'package:flutter_sample/src/features/profile/application/profile_notifier.dart';
import 'package:flutter_sample/src/features/profile/data/profile_repository.dart';
import 'package:flutter_sample/src/features/profile/domain/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker_flutter/talker_flutter.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockFirebaseAuthRepository extends Mock
    implements FirebaseAuthRepository {}

class MockTalker extends Mock implements Talker {}

void main() {
  late MockProfileRepository mockProfileRepo;
  late MockFirebaseAuthRepository mockAuthRepo;
  late MockTalker mockTalker;

  const testProfile = UserProfile(
    name: 'テスト太郎',
    email: 'test@example.com',
    displayName: 'タロウ',
    phone: '09012345678',
  );

  setUpAll(() {
    registerFallbackValue(testProfile);
  });

  setUp(() {
    mockProfileRepo = MockProfileRepository();
    mockAuthRepo = MockFirebaseAuthRepository();
    mockTalker = MockTalker();

    // デフォルトのモック設定
    when(() => mockTalker.debug(any<dynamic>())).thenReturn(null);
    when(() => mockTalker.error(any<dynamic>())).thenReturn(null);
    when(
      () => mockProfileRepo.fetchProfile(),
    ).thenAnswer((_) async => testProfile);
  });

  ProviderContainer createContainer({
    required bool useAuth,
  }) {
    final container = ProviderContainer(
      overrides: [
        profileRepositoryProvider.overrideWithValue(mockProfileRepo),
        firebaseAuthRepositoryProvider.overrideWithValue(mockAuthRepo),
        envConfigProvider.overrideWithValue(
          EnvConfigState(
            baseUrl: 'https://test.example.com',
            aiModel: 'test-model',
            connectTimeout: 10,
            receiveTimeout: 15,
            sendTimeout: 10,
            useFirebaseAuth: useAuth,
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
          ),
        ).called(1);

        subscription.close();
      },
    );

    test('updateProfile: エラー発生時、AsyncError 状態になること', () async {
      final container = createContainer(useAuth: false);
      final subscription = container.listen(profileProvider, (prev, next) {});

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
  });
}
