import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/src/core/config/app_theme.dart';
import 'package:flutter_sample/src/features/user/data/user_repository.dart';
import 'package:flutter_sample/src/features/user/domain/user_model.dart';
import 'package:flutter_sample/src/features/user/presentation/user_list_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import '../../../core/widgets/widgets_test_helper.dart';

void main() {
  group('UserListScreen Golden Tests', () {
    late MockAppLocalizations mockL10n;
    late MockUserRepository mockRepository;
    final dummyTimestamp = DateTime(2026, 5, 17, 10, 30);

    setUp(() {
      mockL10n = MockAppLocalizations();
      when(() => mockL10n.userListTitle).thenReturn('User List');
      when(
        () => mockL10n.userListLastFetched(any()),
      ).thenReturn('Last fetched: 2026/05/17 10:30');
      when(() => mockL10n.userListEmpty).thenReturn('No users found.');
      when(() => mockL10n.errorUnknown).thenReturn('Error Occurred');
      when(() => mockL10n.userListFetchError).thenReturn('Pull to refresh');
      when(() => mockL10n.retry).thenReturn('Retry');
      when(() => mockL10n.close).thenReturn('Close');

      mockRepository = MockUserRepository();
    });

    // テスト用のダミーのユーザーモデルを作成する関数
    UserModel createDummyUser(int id) {
      return UserModel.fromJson({
        'id': id,
        'name': 'Test User $id',
        'email': 'test$id@example.com',
        'phone': '123-456-7890',
        'website': 'https://example.com',
        'address': {
          'street': 'Test Street',
          'suite': 'Suite $id',
          'city': 'Tokyo',
          'zipcode': '100-0000',
          'geo': {'lat': '35.6895', 'lng': '139.6917'},
        },
      });
    }

    // ユーザー一覧画面をテスト用に構築する関数
    Widget buildUserListForGolden({
      required ThemeMode themeMode,
      bool isEmpty = false,
    }) {
      final dummyUsers = isEmpty
          ? <UserModel>[]
          : [createDummyUser(1), createDummyUser(2)];
      when(
        () => mockRepository.fetchUsers(),
      ).thenAnswer((_) async => (dummyUsers, dummyTimestamp));

      return ProviderScope(
        overrides: [
          userRepositoryProvider.overrideWithValue(mockRepository),
        ],
        child: MaterialApp(
          // 日本語フォントを適用したテーマを設定します
          theme: AppTheme.light().copyWith(
            textTheme: AppTheme.light().textTheme.apply(
              fontFamily: 'NotoSansJP',
            ),
          ),
          darkTheme: AppTheme.dark().copyWith(
            textTheme: AppTheme.dark().textTheme.apply(
              fontFamily: 'NotoSansJP',
            ),
          ),
          themeMode: themeMode,
          localizationsDelegates: [
            MockLocalizationsDelegate(mockL10n),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const UserListScreen(),
          debugShowCheckedModeBanner: false,
        ),
      );
    }

    // ignore: discarded_futures, テストフレームワークが同期的にテストを登録するための警告回避
    goldenTest(
      'UserListScreen の描画 (ライト/ダークモード/空データ)',
      fileName: 'user_list_screen',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'With Users - Light Mode',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildUserListForGolden(themeMode: ThemeMode.light),
            ),
          ),
          GoldenTestScenario(
            name: 'With Users - Dark Mode',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildUserListForGolden(themeMode: ThemeMode.dark),
            ),
          ),
          GoldenTestScenario(
            name: 'Empty State - Light Mode',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildUserListForGolden(
                themeMode: ThemeMode.light,
                isEmpty: true,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'Empty State - Dark Mode',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildUserListForGolden(
                themeMode: ThemeMode.dark,
                isEmpty: true,
              ),
            ),
          ),
        ],
      ),
    );
  });
}
