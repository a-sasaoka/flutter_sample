// ignore_for_file: document_ignores, directives_ordering, lines_longer_than_80_chars
import 'dart:async';
import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_sample/src/core/config/flavor_provider.dart';
import 'package:flutter_sample/src/core/storage/secure_storage_provider.dart';
import 'package:flutter_sample/src/core/storage/shared_preferences_provider.dart';
import 'package:flutter_sample/src/core/widgets/not_found_screen.dart';
import 'package:flutter_sample/src/features/dev_tools/presentation/developer_storage_screen.dart';
import 'package:flutter_sample/src/features/dev_tools/application/shared_preferences_provider.dart';
import 'package:flutter_sample/src/features/dev_tools/application/secure_storage_provider.dart';

import '../../../core/widgets/widgets_test_helper.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

class MockSharedPreferencesAsync extends Mock
    implements SharedPreferencesAsync {}

class ErrorSharedPreferencesItems extends SharedPreferencesItems {
  @override
  FutureOr<Map<String, Object?>> build() {
    return Future<Map<String, Object?>>.error(
      Exception('Simulated Prefs Error'),
    );
  }
}

class ErrorSecureStorageItems extends SecureStorageItems {
  @override
  FutureOr<Map<String, String>> build() {
    return Future<Map<String, String>>.error(
      Exception('Simulated Secure Error'),
    );
  }
}

void main() {
  late MockFlutterSecureStorage mockSecureStorage;
  late MockSharedPreferencesAsync mockPrefs;
  late MockAppLocalizations mockL10n;
  late Map<String, Object?> store;

  void setupMockSharedPreferences() {
    when(() => mockPrefs.getAll()).thenAnswer((_) async => store);
    when(() => mockPrefs.setString(any(), any())).thenAnswer((inv) async {
      final key = inv.positionalArguments[0] as String;
      final val = inv.positionalArguments[1] as String;
      store[key] = val;
    });
    when(() => mockPrefs.setInt(any(), any())).thenAnswer((inv) async {
      final key = inv.positionalArguments[0] as String;
      final val = inv.positionalArguments[1] as int;
      store[key] = val;
    });
    when(() => mockPrefs.setDouble(any(), any())).thenAnswer((inv) async {
      final key = inv.positionalArguments[0] as String;
      final val = inv.positionalArguments[1] as double;
      store[key] = val;
    });
    when(() => mockPrefs.setBool(any(), any())).thenAnswer((inv) async {
      final key = inv.positionalArguments[0] as String;
      final val = inv.positionalArguments[1] as bool;
      store[key] = val;
    });
    when(() => mockPrefs.remove(any())).thenAnswer((inv) async {
      final key = inv.positionalArguments[0] as String;
      store.remove(key);
    });
    when(() => mockPrefs.clear()).thenAnswer((_) async {
      store.clear();
    });
  }

  setUp(() {
    mockSecureStorage = MockFlutterSecureStorage();
    mockPrefs = MockSharedPreferencesAsync();
    mockL10n = MockAppLocalizations();
    store = {
      'pref_key_1': 'pref_val_1',
      'pref_key_2': 123,
      'pref_key_3': true,
      'pref_key_4': 1.23,
    };
    setupMockSharedPreferences();

    when(() => mockSecureStorage.readAll()).thenAnswer(
      (_) async => {'sec_key_1': 'sec_val_1'},
    );
    when(
      () => mockSecureStorage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async => {});
    when(
      () => mockSecureStorage.delete(key: any(named: 'key')),
    ).thenAnswer((_) async => {});
    when(() => mockSecureStorage.deleteAll()).thenAnswer((_) async => {});

    // l10n Mock configuration
    when(() => mockL10n.devStorageTitle).thenReturn('Storage Test Title');
    when(() => mockL10n.devStorageClearAll).thenReturn('Clear All');
    when(() => mockL10n.devStoragePrefsTab).thenReturn('SharedPreferences');
    when(() => mockL10n.devStorageSecureTab).thenReturn('SecureStorage');
    when(() => mockL10n.devStorageError(any())).thenAnswer(
      (inv) => 'Error: ${inv.positionalArguments[0]}',
    );
    when(() => mockL10n.devStorageNoPrefsData).thenReturn('No Prefs Data');
    when(() => mockL10n.devStorageNoSecureData).thenReturn('No Secure Data');
    when(() => mockL10n.devStorageConfirmClear).thenReturn('Confirm Clear');
    when(() => mockL10n.close).thenReturn('Close');
    when(() => mockL10n.delete).thenReturn('Delete');
    when(() => mockL10n.ok).thenReturn('OK');
    when(() => mockL10n.devStorageAddDialogTitle).thenReturn('Add Key');
    when(() => mockL10n.devStorageEditDialogTitle).thenReturn('Edit Key');
    when(() => mockL10n.devStorageKey).thenReturn('Key');
    when(() => mockL10n.devStorageValue).thenReturn('Value');
    when(() => mockL10n.devStorageType).thenReturn('Type');
    when(() => mockL10n.notFoundTitle).thenReturn('Page Not Found');
    when(
      () => mockL10n.notFoundMessage,
    ).thenReturn('The page could not be found.');
    when(() => mockL10n.notFoundBackToHome).thenReturn('Back to Home');
  });

  Widget buildTestWidget({
    required Flavor flavor,
  }) {
    return ProviderScope(
      overrides: [
        flavorProvider.overrideWithValue(flavor),
        sharedPreferencesProvider.overrideWithValue(mockPrefs),
        secureStorageProvider.overrideWithValue(mockSecureStorage),
      ],
      child: MaterialApp(
        localizationsDelegates: [
          MockLocalizationsDelegate(mockL10n),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ja')],
        locale: const Locale('ja'),
        home: const DeveloperStorageScreen(),
      ),
    );
  }

  testWidgets('Flavor.prod では NotFoundScreen が表示されること', (tester) async {
    await tester.pumpWidget(buildTestWidget(flavor: Flavor.prod));
    await tester.pumpAndSettle();

    check(find.byType(NotFoundScreen)).findsOne();
  });

  testWidgets('Flavor.dev では画面が正常に表示され、データが表示されること', (tester) async {
    await tester.pumpWidget(buildTestWidget(flavor: Flavor.dev));
    await tester.pumpAndSettle();

    check(find.byType(NotFoundScreen)).findsNothing();
    check(find.text('Storage Test Title')).findsOne();

    // SharedPreferences のデータ表示確認
    check(find.text('pref_key_1')).findsOne();
    check(find.text('pref_val_1')).findsOne();
    check(find.text('pref_key_2')).findsOne();
    check(find.text('123')).findsOne();

    // タブを SecureStorage に切り替え
    await tester.tap(find.text('SecureStorage'));
    await tester.pumpAndSettle();

    check(find.text('sec_key_1')).findsOne();
    check(find.text('sec_val_1')).findsOne();
  });

  testWidgets('SharedPreferencesタブでキーを追加できること', (tester) async {
    await tester.pumpWidget(buildTestWidget(flavor: Flavor.dev));
    await tester.pumpAndSettle();

    // FABをタップしてダイアログを開く
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    check(find.text('Add Key')).findsOne();

    // キーと値を入力
    await tester.enterText(
      find.widgetWithText(TextField, 'Key'),
      'new_pref_key',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Value'),
      'new_pref_val',
    );

    // 保存ボタン(OK)をタップ
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // 追加されたキーが表示されること
    check(find.text('new_pref_key')).findsOne();
    check(find.text('new_pref_val')).findsOne();
  });

  testWidgets('SharedPreferencesタブでbool型のキーを追加できること', (tester) async {
    await tester.pumpWidget(buildTestWidget(flavor: Flavor.dev));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Key'),
      'new_bool_key',
    );

    // ドロップダウンをタップしてデータ型を bool に変更
    await tester.tap(
      find.byWidgetPredicate((widget) => widget is DropdownButtonFormField),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('bool').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    check(find.text('new_bool_key')).findsOne();
    check(find.text('false')).findsOne();
  });

  testWidgets('SharedPreferencesタブでキーを編集できること', (tester) async {
    await tester.pumpWidget(buildTestWidget(flavor: Flavor.dev));
    await tester.pumpAndSettle();

    // タイルをタップして編集ダイアログを開く
    await tester.tap(find.text('pref_key_1'));
    await tester.pumpAndSettle();

    check(find.text('Edit Key')).findsOne();

    // 新しい値を入力
    await tester.enterText(
      find.widgetWithText(TextField, 'Value'),
      'updated_pref_val',
    );

    // 保存
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    check(find.text('updated_pref_val')).findsOne();
  });

  testWidgets('SharedPreferencesタブでbool型のキーを編集できること', (tester) async {
    await tester.pumpWidget(buildTestWidget(flavor: Flavor.dev));
    await tester.pumpAndSettle();

    // bool型のタイルをタップして編集ダイアログを開く
    await tester.tap(find.text('pref_key_3'));
    await tester.pumpAndSettle();

    check(find.text('Edit Key')).findsOne();

    // スイッチをオフにする
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    check(find.text('false')).findsOne();
  });

  testWidgets('SharedPreferencesタブでキーを削除できること', (tester) async {
    await tester.pumpWidget(buildTestWidget(flavor: Flavor.dev));
    await tester.pumpAndSettle();

    check(find.text('pref_key_1')).findsOne();

    // 削除ボタンをタップ
    final deleteButtons = find.byIcon(Icons.delete_outline);
    await tester.tap(deleteButtons.first);
    await tester.pumpAndSettle();

    check(find.text('pref_key_1')).findsNothing();
  });

  testWidgets('SharedPreferencesタブで一括削除ができること', (tester) async {
    await tester.pumpWidget(buildTestWidget(flavor: Flavor.dev));
    await tester.pumpAndSettle();

    check(find.text('pref_key_1')).findsOne();

    // 一括削除ボタンをタップ
    await tester.tap(find.byIcon(Icons.delete_forever));
    await tester.pumpAndSettle();

    check(find.text('Confirm Clear')).findsOne();

    // 削除を選択
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    check(find.text('No Prefs Data')).findsOne();
  });

  testWidgets('SecureStorageタブでキーを追加、編集、削除、一括削除できること', (tester) async {
    await tester.pumpWidget(buildTestWidget(flavor: Flavor.dev));
    await tester.pumpAndSettle();

    // タブを SecureStorage に切り替え
    await tester.tap(find.text('SecureStorage'));
    await tester.pumpAndSettle();

    // 1. 新規追加
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Key'),
      'new_sec_key',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Value'),
      'new_sec_val',
    );

    when(() => mockSecureStorage.readAll()).thenAnswer(
      (_) async => {
        'sec_key_1': 'sec_val_1',
        'new_sec_key': 'new_sec_val',
      },
    );

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    check(find.text('new_sec_key')).findsOne();

    // 2. 編集
    await tester.tap(find.text('sec_key_1'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Value'),
      'updated_sec_val',
    );

    when(() => mockSecureStorage.readAll()).thenAnswer(
      (_) async => {
        'sec_key_1': 'updated_sec_val',
        'new_sec_key': 'new_sec_val',
      },
    );

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    check(find.text('updated_sec_val')).findsOne();

    // 3. 削除
    when(() => mockSecureStorage.readAll()).thenAnswer(
      (_) async => {
        'new_sec_key': 'new_sec_val',
      },
    );

    final deleteButtons = find.byIcon(Icons.delete_outline);
    await tester.tap(deleteButtons.first);
    await tester.pumpAndSettle();

    check(find.text('sec_key_1')).findsNothing();

    // 4. 一括削除
    when(() => mockSecureStorage.readAll()).thenAnswer((_) async => {});

    await tester.tap(find.byIcon(Icons.delete_forever));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    check(find.text('No Secure Data')).findsOne();
  });

  testWidgets('ダイアログの閉じるボタンやキャンセルボタンが正しく動作すること', (tester) async {
    await tester.pumpWidget(buildTestWidget(flavor: Flavor.dev));
    await tester.pumpAndSettle();

    // 1. SharedPreferences一括削除のキャンセル
    await tester.tap(find.byIcon(Icons.delete_forever));
    await tester.pumpAndSettle();
    check(find.text('Confirm Clear')).findsOne();
    await tester.tap(find.widgetWithText(TextButton, 'Close'));
    await tester.pumpAndSettle();
    check(find.text('Confirm Clear')).findsNothing();

    // 2. SharedPreferences追加のキャンセル
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    check(find.text('Add Key')).findsOne();
    await tester.tap(find.widgetWithText(TextButton, 'Close'));
    await tester.pumpAndSettle();
    check(find.text('Add Key')).findsNothing();

    // 3. SharedPreferences編集のキャンセル
    await tester.tap(find.text('pref_key_1'));
    await tester.pumpAndSettle();
    check(find.text('Edit Key')).findsOne();
    await tester.tap(find.widgetWithText(TextButton, 'Close'));
    await tester.pumpAndSettle();
    check(find.text('Edit Key')).findsNothing();

    // SecureStorageタブに切り替え
    await tester.tap(find.text('SecureStorage'));
    await tester.pumpAndSettle();

    // 4. SecureStorage追加のキャンセル
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    check(find.text('Add Key')).findsOne();
    await tester.tap(find.widgetWithText(TextButton, 'Close'));
    await tester.pumpAndSettle();
    check(find.text('Add Key')).findsNothing();

    // 5. SecureStorage編集のキャンセル
    await tester.tap(find.text('sec_key_1'));
    await tester.pumpAndSettle();
    check(find.text('Edit Key')).findsOne();
    await tester.tap(find.widgetWithText(TextButton, 'Close'));
    await tester.pumpAndSettle();
    check(find.text('Edit Key')).findsNothing();
  });

  testWidgets('SharedPreferencesタブでint型およびdouble型のキーを追加・編集できること', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestWidget(flavor: Flavor.dev));
    await tester.pumpAndSettle();

    // 1. int型の追加
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Key'),
      'new_int_key',
    );
    await tester.tap(
      find.byWidgetPredicate((widget) => widget is DropdownButtonFormField),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('int').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Value'), '456');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    check(find.text('new_int_key')).findsOne();
    check(find.text('456')).findsOne();

    // 2. double型の追加
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Key'),
      'new_double_key',
    );
    await tester.tap(
      find.byWidgetPredicate((widget) => widget is DropdownButtonFormField),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('double').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Value'), '9.99');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    check(find.text('new_double_key')).findsOne();
    check(find.text('9.99')).findsOne();

    // 3. int型の編集
    await tester.tap(find.text('pref_key_2'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Value'), '789');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    check(find.text('789')).findsOne();

    // 4. double型の編集
    await tester.tap(find.text('pref_key_4'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Value'), '4.56');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    check(find.text('4.56')).findsOne();
  });

  testWidgets('SharedPreferences追加ダイアログでbool型のスイッチ切り替え動作が正しく動くこと', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestWidget(flavor: Flavor.dev));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Key'),
      'new_bool_key_2',
    );

    await tester.tap(
      find.byWidgetPredicate((widget) => widget is DropdownButtonFormField),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('bool').last);
    await tester.pumpAndSettle();

    // スイッチを切り替え (デフォルトはfalse)
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    check(find.text('new_bool_key_2')).findsOne();
    final tileFinder = find.ancestor(
      of: find.text('true'),
      matching: find.widgetWithText(ListTile, 'new_bool_key_2'),
    );
    check(tileFinder).findsOne();
  });

  testWidgets('エラー発生時にエラー画面が表示されること', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          flavorProvider.overrideWithValue(Flavor.dev),
          sharedPreferencesItemsProvider.overrideWith(
            ErrorSharedPreferencesItems.new,
          ),
          secureStorageItemsProvider.overrideWith(ErrorSecureStorageItems.new),
        ],
        child: MaterialApp(
          localizationsDelegates: [
            MockLocalizationsDelegate(mockL10n),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('ja')],
          locale: const Locale('ja'),
          home: const DeveloperStorageScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    check(find.textContaining('Simulated Prefs Error')).findsOne();

    await tester.tap(find.text('SecureStorage'));
    await tester.pumpAndSettle();
    check(find.textContaining('Simulated Secure Error')).findsOne();
  });
}
