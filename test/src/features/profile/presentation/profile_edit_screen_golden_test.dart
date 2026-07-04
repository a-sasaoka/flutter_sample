// mocktailのwhenマクロに渡すダミー関数の呼び出しにおいて、Futureの未待機警告や
// ラムダ式の省略警告が発生しますが、これらはライブラリの正しい使用法に基づくものなので無視します。
// ignore_for_file: discarded_futures, unnecessary_lambdas
import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/config/app_theme.dart';
import 'package:flutter_sample/src/features/profile/data/profile_repository.dart';
import 'package:flutter_sample/src/features/profile/domain/user_profile.dart';
import 'package:flutter_sample/src/features/profile/presentation/profile_edit_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  group('ProfileEditScreen Golden Tests', () {
    late MockProfileRepository mockProfileRepo;

    const testProfile = UserProfile(
      name: 'テスト太郎',
      email: 'test@example.com',
      displayName: 'タロウ',
      phone: '09012345678',
    );

    setUp(() async {
      mockProfileRepo = MockProfileRepository();
      when(
        () => mockProfileRepo.fetchProfile(),
      ).thenAnswer((_) async => testProfile);
    });

    Widget buildProfileScreenForGolden({
      required ThemeMode themeMode,
      required ProfileRepository repository,
    }) {
      return ProviderScope(
        overrides: [
          profileRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeMode,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ja'),
          ],
          locale: const Locale('ja'),
          home: const ProfileEditScreen(),
        ),
      );
    }

    goldenTest(
      'ProfileEditScreen の描画 (正常系 - ライト/ダークモード)',
      fileName: 'profile_edit_screen_basic',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Light Mode',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildProfileScreenForGolden(
                themeMode: ThemeMode.light,
                repository: mockProfileRepo,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Dark Mode',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildProfileScreenForGolden(
                themeMode: ThemeMode.dark,
                repository: mockProfileRepo,
              ),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'ProfileEditScreen の描画 (ローディング/エラー状態)',
      fileName: 'profile_edit_screen_states',
      builder: () {
        final mockLoadingRepo = MockProfileRepository();
        final mockErrorRepo = MockProfileRepository();

        when(() => mockLoadingRepo.fetchProfile()).thenAnswer((_) {
          return Completer<UserProfile>().future;
        });
        when(
          () => mockErrorRepo.fetchProfile(),
        ).thenThrow(Exception('API Connection Error'));

        return GoldenTestGroup(
          children: [
            GoldenTestScenario(
              name: 'Loading State',
              child: SizedBox(
                width: 390,
                height: 844,
                child: buildProfileScreenForGolden(
                  themeMode: ThemeMode.light,
                  repository: mockLoadingRepo,
                ),
              ),
            ),
            GoldenTestScenario(
              name: 'Error State',
              child: SizedBox(
                width: 390,
                height: 844,
                child: buildProfileScreenForGolden(
                  themeMode: ThemeMode.light,
                  repository: mockErrorRepo,
                ),
              ),
            ),
          ],
        );
      },
    );
  });
}
