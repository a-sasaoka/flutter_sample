import 'dart:async';
import 'dart:io';

import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/exceptions/app_exception.dart';
import 'package:flutter_sample/src/features/profile/application/profile_notifier.dart';
import 'package:flutter_sample/src/features/profile/data/image_picker_service.dart';
import 'package:flutter_sample/src/features/profile/domain/user_profile.dart';
import 'package:flutter_sample/src/features/profile/presentation/profile_edit_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:permission_handler/permission_handler.dart';

class MockImagePickerService extends Mock implements ImagePickerService {}

class FakeProfileNotifier extends Profile {
  FakeProfileNotifier(
    this._state, {
    this.onUpdate,
    this.onUpdateWithAvatar,
  });

  final AsyncValue<UserProfile> _state;
  final Future<void> Function(UserProfile)? onUpdate;
  final Future<void> Function(
    UserProfile profile,
    File? avatarFile, {
    required bool deleteAvatar,
  })?
  onUpdateWithAvatar;

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
  Future<void> updateProfile(
    UserProfile profile, {
    File? avatarFile,
    bool deleteAvatar = false,
  }) async {
    final previousState = state;
    // ignore: invalid_use_of_internal_member, copyWithPrevious is internal but required to preserve state value during test loader.
    state = const AsyncLoading<UserProfile>().copyWithPrevious(previousState);
    try {
      if (onUpdateWithAvatar != null) {
        await onUpdateWithAvatar!(
          profile,
          avatarFile,
          deleteAvatar: deleteAvatar,
        );
      } else if (onUpdate != null) {
        await onUpdate!(profile);
      }
      state = AsyncData(profile);
    } on Object catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
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
      throw const AppException.unknown(message: '読み込み失敗');
    }
    return testProfile;
  }
}

const transparentImageBytes = <int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
];

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

  Future<void> tapSaveButton(WidgetTester tester) async {
    await tester.dragUntilVisible(
      find.text('保存する'),
      find.byType(SingleChildScrollView),
      const Offset(0, -50),
    );
    await tester.tap(find.text('保存する'));
  }

  group('ProfileEditScreen Widget Tests', () {
    test('ProfileEditScreen can be instantiated', () {
      // カバレッジ計測でコンストラクタのコードを確実に実行させてカバーするため、あえて非constでインスタンス化します。
      // ignore: prefer_const_constructors
      final screen = ProfileEditScreen();
      check(screen).isA<ProfileEditScreen>();
    });

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

      check(find.byType(CircularProgressIndicator)).findsOne();
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

      // コントローラー自体は空であること
      check(nameField.controller?.text).equals('');
      check(emailField.controller?.text).equals('');
      check(displayField.controller?.text).equals('');
      check(phoneField.controller?.text).equals('');

      // 入力欄の上に現在の設定値がテキスト表示されていること
      check(find.text('現在の設定: テスト太郎')).findsOne();
      check(find.text('現在の設定: test@example.com')).findsOne();
      check(find.text('現在の設定: タロウ')).findsOne();
      check(find.text('現在の設定: 09012345678')).findsOne();
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

      check(find.textContaining('読み込み失敗')).findsOne();

      shouldFail = false;

      await tester.tap(find.text('再試行'));
      await tester.pumpAndSettle();

      final nameField = tester.widget<TextFormField>(findNameField());
      check(nameField.controller?.text).equals('');
      check(find.text('現在の設定: テスト太郎')).findsOne();
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

      // 最初は空 ''
      await tester.enterText(phoneFinder, '123-abc');
      await tester.pump();

      // Formatterにより非数字が含まれるため、古いテキスト（''）が維持される
      final phoneFieldBefore = tester.widget<TextFormField>(phoneFinder);
      check(phoneFieldBefore.controller?.text).equals('');

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
      await tapSaveButton(tester);
      await tester.pumpAndSettle();

      // エラー文言が表示されること
      check(find.text('氏名は必須入力です')).findsOne();
      check(find.text('有効なメールアドレス形式で入力してください')).findsOne();

      // 2. 氏名に空白スペースのみを入力した場合のテスト
      await tester.enterText(nameFinder, '   '); // 空白スペースのみ
      await tester.pump();
      await tapSaveButton(tester);
      await tester.pumpAndSettle();
      check(find.text('氏名に空白のみを入力することはできません')).findsOne();
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
      await tapSaveButton(tester);
      await tester.pumpAndSettle();
      check(find.text('携帯電話・IP電話は11桁で入力してください')).findsOne();

      // 2. 固定電話等 (03で始まる) なのに11桁の場合
      await tester.enterText(phoneFinder, '03123456789'); // 11桁
      await tester.pump();
      await tapSaveButton(tester);
      await tester.pumpAndSettle();
      check(find.text('固定電話等は10桁で入力してください')).findsOne();

      // 3. 非数字が含まれる場合のテスト (Formatterをバイパスして直接テキストを代入)
      final phoneField = tester.widget<TextFormField>(phoneFinder);
      phoneField.controller?.text = '090-1234-5678';
      await tester.pump();
      await tapSaveButton(tester);
      await tester.pumpAndSettle();
      check(find.text('半角数字のみで入力してください')).findsOne();
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
      final emailFinder = findEmailField();
      await tester.enterText(nameFinder, '山田 太郎');
      await tester.enterText(emailFinder, 'test@example.com');
      await tester.pump();

      // 保存ボタンタップ
      await tapSaveButton(tester);
      await tester.pump(); // スナックバー表示のアニメーション開始

      // SnackBar が表示されていること
      check(find.text('会員情報を保存しました')).findsOne();
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
      final emailFinder = findEmailField();
      await tester.enterText(nameFinder, '山田 二郎');
      await tester.enterText(emailFinder, 'test@example.com');
      await tester.pump();

      // 保存ボタンタップ
      await tapSaveButton(tester);
      await tester.pumpAndSettle();

      // エラーハンドラー経由の SnackBar が表示されていること
      check(find.text('通信エラー')).findsOne();
    });

    testWidgets('保存：保存中はフォームが維持され、フルスクリーンスピナーが表示されないこと', (tester) async {
      final completer = Completer<void>();
      final container = ProviderContainer(
        overrides: [
          profileProvider.overrideWith(
            () => FakeProfileNotifier(
              const AsyncValue.data(testProfile),
              onUpdate: (profile) => completer.future,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(createTestWidget(container: container));
      await tester.pumpAndSettle();

      final nameFinder = findNameField();
      final emailFinder = findEmailField();
      await tester.enterText(nameFinder, '山田 太郎');
      await tester.enterText(emailFinder, 'test@example.com');
      await tester.pump();

      // 保存ボタンタップ
      await tapSaveButton(tester);
      await tester.pump(); // Notifier.state が AsyncLoading になる

      // フォームのテキストフィールドが維持され、フルスクリーンロードに切り替わっていないことを確認
      check(find.byType(TextFormField)).findsExactly(4);

      completer.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('アバター操作：カメラから写真を選択して保存できること', (tester) async {
      final mockPicker = MockImagePickerService();
      final tempDir = Directory.systemTemp.createTempSync();
      final dummyFile = File('${tempDir.path}/picked_avatar.jpg')
        ..writeAsBytesSync(transparentImageBytes);
      addTearDown(() => tempDir.deleteSync(recursive: true));

      when(
        () => mockPicker.pickAndCropAvatar(
          source: AvatarPickSource.camera,
          cropperTitle: any(named: 'cropperTitle'),
        ),
      ).thenAnswer((_) async => dummyFile.path);

      File? capturedFile;
      bool? capturedDelete;

      final container = ProviderContainer(
        overrides: [
          profileProvider.overrideWith(
            () => FakeProfileNotifier(
              const AsyncValue.data(testProfile),
              onUpdateWithAvatar:
                  (profile, file, {required deleteAvatar}) async {
                    capturedFile = file;
                    capturedDelete = deleteAvatar;
                  },
            ),
          ),
          imagePickerServiceProvider.overrideWithValue(mockPicker),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(createTestWidget(container: container));
      await tester.pumpAndSettle();

      // アバター枠をタップしてボトムシートを表示
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      // ボトムシートの選択肢を確認
      check(find.text('カメラで撮影')).findsOne();
      check(find.text('アルバムから選択')).findsOne();

      // 「カメラで撮影」を選択
      await tester.tap(find.text('カメラで撮影'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 必須項目を入力
      final nameFinder = findNameField();
      final emailFinder = findEmailField();
      await tester.enterText(nameFinder, 'テスト太郎');
      await tester.enterText(emailFinder, 'test@example.com');
      await tester.pump();

      // 保存するボタンをタップ
      await tapSaveButton(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      check(capturedFile?.path).equals(dummyFile.path);
      check(capturedDelete).equals(false);
    });

    testWidgets('アバター操作：写真ライブラリから写真を選択して保存できること', (tester) async {
      final mockPicker = MockImagePickerService();
      final tempDir = Directory.systemTemp.createTempSync();
      final dummyFile = File('${tempDir.path}/gallery_avatar.jpg')
        ..writeAsBytesSync(transparentImageBytes);
      addTearDown(() => tempDir.deleteSync(recursive: true));

      when(
        () => mockPicker.pickAndCropAvatar(
          source: AvatarPickSource.gallery,
          cropperTitle: any(named: 'cropperTitle'),
        ),
      ).thenAnswer((_) async => dummyFile.path);

      File? capturedFile;
      bool? capturedDelete;

      final container = ProviderContainer(
        overrides: [
          profileProvider.overrideWith(
            () => FakeProfileNotifier(
              const AsyncValue.data(testProfile),
              onUpdateWithAvatar:
                  (profile, file, {required deleteAvatar}) async {
                    capturedFile = file;
                    capturedDelete = deleteAvatar;
                  },
            ),
          ),
          imagePickerServiceProvider.overrideWithValue(mockPicker),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(createTestWidget(container: container));
      await tester.pumpAndSettle();

      // アバター枠をタップしてボトムシートを表示
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      // 「アルバムから選択」を選択
      await tester.tap(find.text('アルバムから選択'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 必須項目を入力
      final nameFinder = findNameField();
      final emailFinder = findEmailField();
      await tester.enterText(nameFinder, 'テスト太郎');
      await tester.enterText(emailFinder, 'test@example.com');
      await tester.pump();

      // 保存するボタンをタップ
      await tapSaveButton(tester);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      check(capturedFile?.path).equals(dummyFile.path);
      check(capturedDelete).equals(false);
    });

    testWidgets('アバター操作：写真選択がキャンセルされた場合、アバターが変更されないこと', (tester) async {
      final mockPicker = MockImagePickerService();
      when(
        () => mockPicker.pickAndCropAvatar(
          source: AvatarPickSource.camera,
          cropperTitle: any(named: 'cropperTitle'),
        ),
      ).thenAnswer((_) async => null);

      final container = ProviderContainer(
        overrides: [
          profileProvider.overrideWith(
            () => FakeProfileNotifier(const AsyncValue.data(testProfile)),
          ),
          imagePickerServiceProvider.overrideWithValue(mockPicker),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(createTestWidget(container: container));
      await tester.pumpAndSettle();

      // アバター枠をタップしてボトムシートを表示
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      // 「カメラで撮影」を選択
      await tester.tap(find.text('カメラで撮影'));
      await tester.pumpAndSettle();

      // アイコンがデフォルト（Icon）のまま変わらないこと
      check(find.byIcon(Icons.person)).findsOne();
    });

    testWidgets('アバター操作：既存アバターの削除を選択して保存できること', (tester) async {
      const profileWithAvatar = UserProfile(
        name: 'テスト太郎',
        email: 'test@example.com',
        displayName: 'タロウ',
        phone: '09012345678',
        avatarUrl: 'https://example.com/avatar.jpg',
      );

      bool? capturedDelete;

      final container = ProviderContainer(
        overrides: [
          profileProvider.overrideWith(
            () => FakeProfileNotifier(
              const AsyncValue.data(profileWithAvatar),
              onUpdateWithAvatar:
                  (profile, file, {required deleteAvatar}) async {
                    capturedDelete = deleteAvatar;
                  },
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(createTestWidget(container: container));
      await tester.pumpAndSettle();

      // アバター枠をタップしてボトムシートを表示
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      // 削除ボタンが表示されていること
      check(find.text('現在の写真を削除')).findsOne();

      // 削除をタップ
      await tester.tap(find.text('現在の写真を削除'));
      await tester.pumpAndSettle();

      // 必須項目を入力
      final nameFinder = findNameField();
      final emailFinder = findEmailField();
      await tester.enterText(nameFinder, 'テスト太郎');
      await tester.enterText(emailFinder, 'test@example.com');
      await tester.pump();

      // 保存ボタンをタップ
      await tapSaveButton(tester);
      await tester.pumpAndSettle();

      check(capturedDelete).equals(true);
    });

    testWidgets('アバター操作：権限拒否時にダイアログが表示され、設定を開くボタンが動作すること', (tester) async {
      final mockPicker = MockImagePickerService();
      when(
        () => mockPicker.pickAndCropAvatar(
          source: AvatarPickSource.gallery,
          cropperTitle: any(named: 'cropperTitle'),
        ),
      ).thenThrow(
        const AvatarPermissionDeniedException(
          permission: Permission.photos,
          isPermanentlyDenied: true,
        ),
      );
      when(mockPicker.openSettings).thenAnswer((_) async => true);

      final container = ProviderContainer(
        overrides: [
          profileProvider.overrideWith(
            () => FakeProfileNotifier(const AsyncValue.data(testProfile)),
          ),
          imagePickerServiceProvider.overrideWithValue(mockPicker),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(createTestWidget(container: container));
      await tester.pumpAndSettle();

      // アバター枠をタップしてボトムシートを表示
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      // 「アルバムから選択」をタップ
      await tester.tap(find.text('アルバムから選択'));
      await tester.pumpAndSettle();

      // 権限案内ダイアログが表示されていることを検証
      check(find.text('アクセス許可が必要です')).findsOne();

      // 「設定を開く」をタップ
      await tester.tap(find.text('設定を開く'));
      await tester.pumpAndSettle();

      // 設定アプリを開くメソッドが呼ばれたことを確認
      verify(mockPicker.openSettings).called(1);
    });

    testWidgets('アバター操作：権限拒否ダイアログで「閉じる」ボタンをタップするとダイアログが閉じること', (tester) async {
      final mockPicker = MockImagePickerService();
      when(
        () => mockPicker.pickAndCropAvatar(
          source: AvatarPickSource.gallery,
          cropperTitle: any(named: 'cropperTitle'),
        ),
      ).thenThrow(
        const AvatarPermissionDeniedException(
          permission: Permission.photos,
        ),
      );

      final container = ProviderContainer(
        overrides: [
          profileProvider.overrideWith(
            () => FakeProfileNotifier(const AsyncValue.data(testProfile)),
          ),
          imagePickerServiceProvider.overrideWithValue(mockPicker),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(createTestWidget(container: container));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('アルバムから選択'));
      await tester.pumpAndSettle();

      check(find.text('アクセス許可が必要です')).findsOne();

      // 「閉じる」をタップしてダイアログを閉じる
      await tester.tap(find.text('閉じる'));
      await tester.pumpAndSettle();

      check(find.text('アクセス許可が必要です')).findsNothing();
    });

    testWidgets('アバター操作：カメラ起動時に権限拒否された場合もダイアログが表示されること', (tester) async {
      final mockPicker = MockImagePickerService();
      when(
        () => mockPicker.pickAndCropAvatar(
          source: AvatarPickSource.camera,
          cropperTitle: any(named: 'cropperTitle'),
        ),
      ).thenThrow(
        const AvatarPermissionDeniedException(
          permission: Permission.camera,
        ),
      );

      final container = ProviderContainer(
        overrides: [
          profileProvider.overrideWith(
            () => FakeProfileNotifier(const AsyncValue.data(testProfile)),
          ),
          imagePickerServiceProvider.overrideWithValue(mockPicker),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(createTestWidget(container: container));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      // カメラを選択
      await tester.tap(find.text('カメラで撮影'));
      await tester.pumpAndSettle();

      check(find.text('アクセス許可が必要です')).findsOne();
    });

    testWidgets('アバター操作：ボトムシートの外側をタップして閉じた場合は何もしないこと', (tester) async {
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

      // アバター枠をタップしてボトムシートを表示
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      // ボトムシートの背景（上部余白）をタップして閉じる
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // ボトムシートが消えていること
      check(find.text('カメラで撮影')).findsNothing();
    });

    testWidgets('初期表示：avatarUrl がローカルパスの場合に Image.file で表示されること', (
      tester,
    ) async {
      final tempDir = Directory.systemTemp.createTempSync();
      final localFile = File('${tempDir.path}/local_avatar.jpg')
        ..writeAsBytesSync(transparentImageBytes);
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final profileWithLocalAvatar = UserProfile(
        name: 'テスト太郎',
        email: 'test@example.com',
        displayName: 'タロウ',
        phone: '09012345678',
        avatarUrl: localFile.path,
      );

      final container = ProviderContainer(
        overrides: [
          profileProvider.overrideWith(
            () => FakeProfileNotifier(
              AsyncValue.data(profileWithLocalAvatar),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(createTestWidget(container: container));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      check(find.byType(Image)).findsOne();
    });

    testWidgets('初期表示：avatarUrl が file:// スキームの場合に Image.file で表示されること', (
      tester,
    ) async {
      final tempDir = Directory.systemTemp.createTempSync();
      final localFile = File('${tempDir.path}/local_avatar.jpg')
        ..writeAsBytesSync(transparentImageBytes);
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final profileWithFileScheme = UserProfile(
        name: 'テスト太郎',
        email: 'test@example.com',
        displayName: 'タロウ',
        phone: '09012345678',
        avatarUrl: 'file://${localFile.path}',
      );

      final container = ProviderContainer(
        overrides: [
          profileProvider.overrideWith(
            () => FakeProfileNotifier(
              AsyncValue.data(profileWithFileScheme),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(createTestWidget(container: container));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      check(find.byType(Image)).findsOne();
    });

    testWidgets(
      '初期表示：avatarUrl のローカル画像エラー時に errorBuilder でフォールバックアイコンが生成されること',
      (tester) async {
        const profileWithInvalidFile = UserProfile(
          name: 'テスト太郎',
          email: 'test@example.com',
          displayName: 'タロウ',
          phone: '09012345678',
          avatarUrl: '/invalid/path/avatar.jpg',
        );

        final container = ProviderContainer(
          overrides: [
            profileProvider.overrideWith(
              () => FakeProfileNotifier(
                const AsyncValue.data(profileWithInvalidFile),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(createTestWidget(container: container));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final imageFinder = find.byType(Image);
        check(imageFinder).findsOne();
        final imageWidget = tester.widget<Image>(imageFinder);
        final errorWidget = imageWidget.errorBuilder!(
          tester.element(imageFinder),
          Exception('Load failed'),
          StackTrace.current,
        );
        check(errorWidget).isA<Widget>();
      },
    );

    testWidgets(
      'アバター操作：選択した一時画像のエラー時に errorBuilder でフォールバックアイコンが生成されること',
      (tester) async {
        final mockPicker = MockImagePickerService();
        final tempDir = Directory.systemTemp.createTempSync();
        final localFile = File('${tempDir.path}/temp_avatar.jpg')
          ..writeAsBytesSync(transparentImageBytes);
        addTearDown(() => tempDir.deleteSync(recursive: true));

        when(
          () => mockPicker.pickAndCropAvatar(
            source: AvatarPickSource.gallery,
            cropperTitle: any(named: 'cropperTitle'),
          ),
        ).thenAnswer((_) async => localFile.path);

        final container = ProviderContainer(
          overrides: [
            profileProvider.overrideWith(
              () => FakeProfileNotifier(const AsyncValue.data(testProfile)),
            ),
            imagePickerServiceProvider.overrideWithValue(mockPicker),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(createTestWidget(container: container));
        await tester.pumpAndSettle();

        // アバター枠をタップしてアルバムから選択
        await tester.tap(find.byType(InkWell).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('アルバムから選択'));
        await tester.pumpAndSettle();

        final imageFinder = find.byType(Image);
        check(imageFinder).findsOne();
        final imageWidget = tester.widget<Image>(imageFinder);
        final errorWidget = imageWidget.errorBuilder!(
          tester.element(imageFinder),
          Exception('Load failed'),
          StackTrace.current,
        );
        check(errorWidget).isA<Widget>();
      },
    );
  });
}
