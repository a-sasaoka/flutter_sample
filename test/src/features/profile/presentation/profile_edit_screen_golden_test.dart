import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/config/app_theme.dart';
import 'package:flutter_sample/src/features/profile/application/profile_notifier.dart';
import 'package:flutter_sample/src/features/profile/domain/user_profile.dart';
import 'package:flutter_sample/src/features/profile/presentation/profile_edit_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// 💡 画面の状態を直接制御するため、ゴールデンテスト用のモックNotifierを定義します。
// これにより、Firebase Authや通信などの外部依存関係を完全にシャットアウトし、UIの検証に専念できます。
class GoldenProfileNotifier extends Profile {
  GoldenProfileNotifier(this._state);
  final AsyncValue<UserProfile> _state;

  @override
  FutureOr<UserProfile> build() {
    return _state.when(
      data: (data) => data,
      error: (err, stack) {
        if (err is Exception) {
          throw err;
        }
        throw Exception(err.toString());
      },
      loading: () => Completer<UserProfile>().future,
    );
  }

  @override
  Future<void> updateProfile(UserProfile profile) async {}
}

void main() {
  group('ProfileEditScreen Golden Tests', () {
    const testProfile = UserProfile(
      name: 'テスト太郎',
      email: 'test@example.com',
      displayName: 'タロウ',
      phone: '09012345678',
    );

    Widget buildProfileScreenForGolden({
      required ThemeMode themeMode,
      required AsyncValue<UserProfile> profileState,
    }) {
      final isDark = themeMode == ThemeMode.dark;

      return ProviderScope(
        overrides: [
          // 💡 profileProvider 自体をモックNotifierでオーバーライドします
          profileProvider.overrideWith(
            () => GoldenProfileNotifier(profileState),
          ),
        ],
        child: MaterialApp(
          theme: isDark
              ? AppTheme.dark().copyWith(
                  textTheme: AppTheme.dark().textTheme.apply(
                    fontFamily: 'NotoSansJP',
                  ),
                )
              : AppTheme.light().copyWith(
                  textTheme: AppTheme.light().textTheme.apply(
                    fontFamily: 'NotoSansJP',
                  ),
                ),
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
          debugShowCheckedModeBanner: false,
        ),
      );
    }

    // alchemistのgoldenTestは非同期処理ですが、テスト定義内で直接呼び出すため discarded_futures を無視します。
    // ignore: discarded_futures
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
                profileState: const AsyncData(testProfile),
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
                profileState: const AsyncData(testProfile),
              ),
            ),
          ),
        ],
      ),
    );

    // alchemistのgoldenTestは非同期処理ですが、テスト定義内で直接呼び出すため discarded_futures を無視します。
    // ignore: discarded_futures
    goldenTest(
      'ProfileEditScreen の描画 (ローディング状態)',
      fileName: 'profile_edit_screen_loading',
      // 💡 未完了のCompleterによるタイムアウトを防ぐため、pumpAndSettleではなく1回のpumpのみにします
      pumpBeforeTest: (tester) async => tester.pump(),
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Loading State',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildProfileScreenForGolden(
                themeMode: ThemeMode.light,
                profileState: const AsyncLoading(),
              ),
            ),
          ),
        ],
      ),
    );

    // alchemistのgoldenTestは非同期処理ですが、テスト定義内で直接呼び出すため discarded_futures を無視します。
    // ignore: discarded_futures
    goldenTest(
      'ProfileEditScreen の描画 (エラー状態)',
      fileName: 'profile_edit_screen_error',
      // 💡 エラー確定後の画面を描画させるため、こちらはデフォルトの pumpAndSettle を使用します
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Error State',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildProfileScreenForGolden(
                themeMode: ThemeMode.light,
                profileState: AsyncError(
                  Exception('API Connection Error'),
                  StackTrace.empty,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  });
}
