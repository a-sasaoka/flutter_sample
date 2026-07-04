import 'dart:async';

import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/exceptions/app_exception.dart';
import 'package:flutter_sample/src/features/profile/application/profile_notifier.dart';
import 'package:flutter_sample/src/features/profile/domain/user_profile.dart';
import 'package:flutter_sample/src/features/profile/presentation/profile_edit_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class FakeProfileNotifier extends Profile {
  FakeProfileNotifier(this._state, {this.onUpdate});

  final AsyncValue<UserProfile> _state;
  final Future<void> Function(UserProfile)? onUpdate;

  @override
  FutureOr<UserProfile> build() {
    return _state.when(
      data: (data) => data,
      error: (err, stack) {
        if (err is Exception) {
          throw err;
        }
        if (err is Error) {
          throw err;
        }
        throw Exception(err.toString());
      },
      loading: () => Completer<UserProfile>().future,
    );
  }

  @override
  Future<void> updateProfile(UserProfile profile) async {
    if (onUpdate != null) {
      await onUpdate!(profile);
    }
  }
}

class FakeRetryProfileNotifier extends Profile {
  FakeRetryProfileNotifier(this.testProfile, this.shouldFailEvaluator);
  final UserProfile testProfile;
  final bool Function() shouldFailEvaluator;

  @override
  FutureOr<UserProfile> build() {
    if (shouldFailEvaluator()) {
      throw Exception('読み込み失敗');
    }
    return testProfile;
  }
}

void main() {
  const testProfile = UserProfile(
    name: 'テスト太郎',
    email: 'test@example.com',
    displayName: 'タロウ',
    phone: '09012345678',
  );

  Widget createTestWidget({
    required ProviderContainer container,
  }) {
    return UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [
          Locale('ja'),
        ],
        locale: Locale('ja'),
        home: ProfileEditScreen(),
      ),
    );
  }

  // 各 TextFormField を順序（インデックス）で特定する Finder
  Finder findNameField() => find.byType(TextFormField).at(0);
  Finder findEmailField() => find.byType(TextFormField).at(1);
  Finder findDisplayField() => find.byType(TextFormField).at(2);
  Finder findPhoneField() => find.byType(TextFormField).at(3);

  group('ProfileEditScreen Widget Tests', () {
    testWidgets('初期読み込み中：インジケータが表示されること', (tester) async {
      final container = ProviderContainer(
        overrides: [
          profileProvider.overrideWith(
            () => FakeProfileNotifier(const AsyncValue.loading()),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(createTestWidget(container: container));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('初期表示：UserProfileの各値が正しくバインドされていること', (tester) async {
      final container = ProviderContainer(
        overrides: [
          profileProvider.overrideWith(
            () => FakeProfileNotifier(const AsyncValue.data(testProfile)),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(createTestWidget(container: container));
      await tester.pumpAndSettle();

      final nameField = tester.widget<TextFormField>(findNameField());
      final emailField = tester.widget<TextFormField>(findEmailField());
      final displayField = tester.widget<TextFormField>(findDisplayField());
      final phoneField = tester.widget<TextFormField>(findPhoneField());

      check(nameField.controller?.text).equals('テスト太郎');
      check(emailField.controller?.text).equals('test@example.com');
      check(displayField.controller?.text).equals('タロウ');
      check(phoneField.controller?.text).equals('09012345678');
    });

    testWidgets('エラー画面：再試行ボタンをタップするとプロバイダーが再評価されること', (tester) async {
      var shouldFail = true;
      final container = ProviderContainer(
        overrides: [
          profileProvider.overrideWith(
            () => FakeRetryProfileNotifier(testProfile, () => shouldFail),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(createTestWidget(container: container));
      await tester.pumpAndSettle();

      expect(find.textContaining('読み込み失敗'), findsOneWidget);

      shouldFail = false;

      await tester.tap(find.text('再試行'));
      await tester.pumpAndSettle();

      final nameField = tester.widget<TextFormField>(findNameField());
      check(nameField.controller?.text).equals('テスト太郎');
    });

    testWidgets('入力コピペ制御：電話番号フィールドに非数字は入力できないこと', (tester) async {
      final container = ProviderContainer(
        overrides: [
          profileProvider.overrideWith(
            () => FakeProfileNotifier(const AsyncValue.data(testProfile)),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(createTestWidget(container: container));
      await tester.pumpAndSettle();

      final phoneFinder = findPhoneField();

      // 最初は '09012345678'
      await tester.enterText(phoneFinder, '123-abc');
      await tester.pump();

      // Formatterにより非数字が含まれるため、古いテキスト（'09012345678'）が維持される
      final phoneFieldBefore = tester.widget<TextFormField>(phoneFinder);
      check(phoneFieldBefore.controller?.text).equals('09012345678');

      // 数字のみの場合は入力できること
      await tester.enterText(phoneFinder, '08098765432');
      await tester.pump();
      final phoneFieldAfter = tester.widget<TextFormField>(phoneFinder);
      check(phoneFieldAfter.controller?.text).equals('08098765432');
    });

    testWidgets('バリデーション：必須チェック・形式チェックエラーが正しく動くこと', (tester) async {
      final container = ProviderContainer(
        overrides: [
          profileProvider.overrideWith(
            () => FakeProfileNotifier(const AsyncValue.data(testProfile)),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(createTestWidget(container: container));
      await tester.pumpAndSettle();

      final nameFinder = findNameField();
      final emailFinder = findEmailField();

      // 1. 完全に空欄・無効メールアドレスの場合のテスト
      await tester.enterText(nameFinder, ''); // 完全に空
      await tester.enterText(emailFinder, 'invalid-email');
      await tester.pump();

      // 保存する
      await tester.tap(find.text('保存する'));
      await tester.pumpAndSettle();

      // エラー文言が表示されること
      expect(find.text('氏名は必須入力です'), findsOneWidget);
      expect(find.text('有効なメールアドレス形式で入力してください'), findsOneWidget);

      // 2. 氏名に空白スペースのみを入力した場合のテスト
      await tester.enterText(nameFinder, '   '); // 空白スペースのみ
      await tester.pump();
      await tester.tap(find.text('保存する'));
      await tester.pumpAndSettle();
      expect(find.text('氏名に空白のみを入力することはできません'), findsOneWidget);
    });

    testWidgets('バリデーション：電話番号の桁数チェックが正しく動くこと', (tester) async {
      final container = ProviderContainer(
        overrides: [
          profileProvider.overrideWith(
            () => FakeProfileNotifier(const AsyncValue.data(testProfile)),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(createTestWidget(container: container));
      await tester.pumpAndSettle();

      final phoneFinder = findPhoneField();

      // 1. 携帯・IP (090で始まる) なのに10桁の場合
      await tester.enterText(phoneFinder, '0901234567'); // 10桁
      await tester.pump();
      await tester.tap(find.text('保存する'));
      await tester.pumpAndSettle();
      expect(find.text('携帯電話・IP電話は11桁で入力してください'), findsOneWidget);

      // 2. 固定電話等 (03で始まる) なのに11桁の場合
      await tester.enterText(phoneFinder, '03123456789'); // 11桁
      await tester.pump();
      await tester.tap(find.text('保存する'));
      await tester.pumpAndSettle();
      expect(find.text('固定電話等は10桁で入力してください'), findsOneWidget);

      // 3. 非数字が含まれる場合のテスト (Formatterをバイパスして直接テキストを代入)
      final phoneField = tester.widget<TextFormField>(phoneFinder);
      phoneField.controller?.text = '090-1234-5678';
      await tester.pump();
      await tester.tap(find.text('保存する'));
      await tester.pumpAndSettle();
      expect(find.text('半角数字のみで入力してください'), findsOneWidget);
    });

    testWidgets('保存：正常に入力し、保存に成功した際、スナックバーが表示されること', (tester) async {
      var updateCalled = false;
      final container = ProviderContainer(
        overrides: [
          profileProvider.overrideWith(
            () => FakeProfileNotifier(
              const AsyncValue.data(testProfile),
              onUpdate: (profile) async {
                updateCalled = true;
              },
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(createTestWidget(container: container));
      await tester.pumpAndSettle();

      final nameFinder = findNameField();
      await tester.enterText(nameFinder, '山田 太郎');
      await tester.pump();

      // 保存ボタンタップ
      await tester.tap(find.text('保存する'));
      await tester.pump(); // スナックバー表示のアニメーション開始

      // SnackBar が表示されていること
      expect(find.text('会員情報を保存しました'), findsOneWidget);
      check(updateCalled).isTrue();
    });

    testWidgets('保存：保存に失敗した際、エラーSnackBarが表示されること', (tester) async {
      final container = ProviderContainer(
        overrides: [
          profileProvider.overrideWith(
            () => FakeProfileNotifier(
              const AsyncValue.data(testProfile),
              onUpdate: (profile) async {
                throw const AppException.unknown(message: '通信エラー');
              },
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(createTestWidget(container: container));
      await tester.pumpAndSettle();

      final nameFinder = findNameField();
      await tester.enterText(nameFinder, '山田 二郎');
      await tester.pump();

      // 保存ボタンタップ
      await tester.tap(find.text('保存する'));
      await tester.pumpAndSettle();

      // エラーハンドラー経由の SnackBar が表示されていること
      expect(find.text('通信エラー'), findsOneWidget);
    });
  });
}
