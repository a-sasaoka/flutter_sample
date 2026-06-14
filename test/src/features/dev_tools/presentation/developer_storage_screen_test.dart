// ignore_for_file: document_ignores, directives_ordering, lines_longer_than_80_chars
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/config/flavor_provider.dart';
import 'package:flutter_sample/src/core/storage/secure_storage_provider.dart';
import 'package:flutter_sample/src/core/storage/shared_preferences_provider.dart';
import 'package:flutter_sample/src/core/widgets/not_found_screen.dart';
import 'package:flutter_sample/src/features/dev_tools/presentation/developer_storage_screen.dart';
import 'package:flutter_sample/src/features/dev_tools/application/shared_preferences_provider.dart';
import 'package:flutter_sample/src/features/dev_tools/application/secure_storage_provider.dart';

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
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('ja'),
        home: DeveloperStorageScreen(),
      ),
    );
  }

  testWidgets('Flavor.prod では NotFoundScreen が表示されること', (tester) async {
    await tester.pumpWidget(buildTestWidget(flavor: Flavor.prod));
    await tester.pumpAndSettle();

    expect(find.byType(NotFoundScreen), findsOneWidget);
  });

  testWidgets('Flavor.dev では画面が正常に表示され、データが表示されること', (tester) async {
    await tester.pumpWidget(buildTestWidget(flavor: Flavor.dev));
    await tester.pumpAndSettle();

    expect(find.byType(NotFoundScreen), findsNothing);
    expect(find.text('ストレージ確認・編集'), findsOneWidget);

    // SharedPreferences のデータ表示確認
    expect(find.text('pref_key_1'), findsOneWidget);
    expect(find.text('pref_val_1'), findsOneWidget);
    expect(find.text('pref_key_2'), findsOneWidget);
    expect(find.text('123'), findsOneWidget);

    // タブを SecureStorage に切り替え
    await tester.tap(find.text('SecureStorage'));
    await tester.pumpAndSettle();

    expect(find.text('sec_key_1'), findsOneWidget);
    expect(find.text('sec_val_1'), findsOneWidget);
  });

  testWidgets('SharedPreferencesタブでキーを追加できること', (tester) async {
    await tester.pumpWidget(buildTestWidget(flavor: Flavor.dev));
    await tester.pumpAndSettle();

    // FABをタップしてダイアログを開く
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('キーの追加'), findsOneWidget);

    // キーと値を入力
    await tester.enterText(
      find.widgetWithText(TextField, 'キー'),
      'new_pref_key',
    );
    await tester.enterText(
      find.widgetWithText(TextField, '値'),
      'new_pref_val',
    );

    // 保存ボタン(OK)をタップ
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // 追加されたキーが表示されること
    expect(find.text('new_pref_key'), findsOneWidget);
    expect(find.text('new_pref_val'), findsOneWidget);
  });

  testWidgets('SharedPreferencesタブでbool型のキーを追加できること', (tester) async {
    await tester.pumpWidget(buildTestWidget(flavor: Flavor.dev));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'キー'),
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

    expect(find.text('new_bool_key'), findsOneWidget);
    expect(find.text('false'), findsOneWidget);
  });

  testWidgets('SharedPreferencesタブでキーを編集できること', (tester) async {
    await tester.pumpWidget(buildTestWidget(flavor: Flavor.dev));
    await tester.pumpAndSettle();

    // タイルをタップして編集ダイアログを開く
    await tester.tap(find.text('pref_key_1'));
    await tester.pumpAndSettle();

    expect(find.text('キーの編集'), findsOneWidget);

    // 新しい値を入力
    await tester.enterText(
      find.widgetWithText(TextField, '値'),
      'updated_pref_val',
    );

    // 保存
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('updated_pref_val'), findsOneWidget);
  });

  testWidgets('SharedPreferencesタブでbool型のキーを編集できること', (tester) async {
    await tester.pumpWidget(buildTestWidget(flavor: Flavor.dev));
    await tester.pumpAndSettle();

    // bool型のタイルをタップして編集ダイアログを開く
    await tester.tap(find.text('pref_key_3'));
    await tester.pumpAndSettle();

    expect(find.text('キーの編集'), findsOneWidget);

    // スイッチをオフにする
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('false'), findsOneWidget);
  });

  testWidgets('SharedPreferencesタブでキーを削除できること', (tester) async {
    await tester.pumpWidget(buildTestWidget(flavor: Flavor.dev));
    await tester.pumpAndSettle();

    expect(find.text('pref_key_1'), findsOneWidget);

    // 削除ボタンをタップ
    final deleteButtons = find.byIcon(Icons.delete_outline);
    await tester.tap(deleteButtons.first);
    await tester.pumpAndSettle();

    expect(find.text('pref_key_1'), findsNothing);
  });

  testWidgets('SharedPreferencesタブで一括削除ができること', (tester) async {
    await tester.pumpWidget(buildTestWidget(flavor: Flavor.dev));
    await tester.pumpAndSettle();

    expect(find.text('pref_key_1'), findsOneWidget);

    // 一括削除ボタンをタップ
    await tester.tap(find.byIcon(Icons.delete_forever));
    await tester.pumpAndSettle();

    expect(find.text('すべてのデータを削除しますか？'), findsOneWidget);

    // 削除を選択
    await tester.tap(find.widgetWithText(TextButton, '削除'));
    await tester.pumpAndSettle();

    expect(find.text('No SharedPreferences data found.'), findsOneWidget);
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
      find.widgetWithText(TextField, 'キー'),
      'new_sec_key',
    );
    await tester.enterText(
      find.widgetWithText(TextField, '値'),
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

    expect(find.text('new_sec_key'), findsOneWidget);

    // 2. 編集
    await tester.tap(find.text('sec_key_1'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, '値'),
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

    expect(find.text('updated_sec_val'), findsOneWidget);

    // 3. 削除
    when(() => mockSecureStorage.readAll()).thenAnswer(
      (_) async => {
        'new_sec_key': 'new_sec_val',
      },
    );

    final deleteButtons = find.byIcon(Icons.delete_outline);
    await tester.tap(deleteButtons.first);
    await tester.pumpAndSettle();

    expect(find.text('sec_key_1'), findsNothing);

    // 4. 一括削除
    when(() => mockSecureStorage.readAll()).thenAnswer((_) async => {});

    await tester.tap(find.byIcon(Icons.delete_forever));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, '削除'));
    await tester.pumpAndSettle();

    expect(find.text('No SecureStorage data found.'), findsOneWidget);
  });

  testWidgets('ダイアログの閉じるボタンやキャンセルボタンが正しく動作すること', (tester) async {
    await tester.pumpWidget(buildTestWidget(flavor: Flavor.dev));
    await tester.pumpAndSettle();

    // 1. SharedPreferences一括削除のキャンセル
    await tester.tap(find.byIcon(Icons.delete_forever));
    await tester.pumpAndSettle();
    expect(find.text('すべてのデータを削除しますか？'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, '閉じる'));
    await tester.pumpAndSettle();
    expect(find.text('すべてのデータを削除しますか？'), findsNothing);

    // 2. SharedPreferences追加のキャンセル
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('キーの追加'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, '閉じる'));
    await tester.pumpAndSettle();
    expect(find.text('キーの追加'), findsNothing);

    // 3. SharedPreferences編集のキャンセル
    await tester.tap(find.text('pref_key_1'));
    await tester.pumpAndSettle();
    expect(find.text('キーの編集'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, '閉じる'));
    await tester.pumpAndSettle();
    expect(find.text('キーの編集'), findsNothing);

    // SecureStorageタブに切り替え
    await tester.tap(find.text('SecureStorage'));
    await tester.pumpAndSettle();

    // 4. SecureStorage追加のキャンセル
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('キーの追加'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, '閉じる'));
    await tester.pumpAndSettle();
    expect(find.text('キーの追加'), findsNothing);

    // 5. SecureStorage編集のキャンセル
    await tester.tap(find.text('sec_key_1'));
    await tester.pumpAndSettle();
    expect(find.text('キーの編集'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, '閉じる'));
    await tester.pumpAndSettle();
    expect(find.text('キーの編集'), findsNothing);
  });

  testWidgets('SharedPreferencesタブでint型およびdouble型のキーを追加・編集できること', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestWidget(flavor: Flavor.dev));
    await tester.pumpAndSettle();

    // 1. int型の追加
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'キー'), 'new_int_key');
    await tester.tap(
      find.byWidgetPredicate((widget) => widget is DropdownButtonFormField),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('int').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, '値'), '456');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('new_int_key'), findsOneWidget);
    expect(find.text('456'), findsOneWidget);

    // 2. double型の追加
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'キー'),
      'new_double_key',
    );
    await tester.tap(
      find.byWidgetPredicate((widget) => widget is DropdownButtonFormField),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('double').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, '値'), '9.99');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('new_double_key'), findsOneWidget);
    expect(find.text('9.99'), findsOneWidget);

    // 3. int型の編集
    await tester.tap(find.text('pref_key_2'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, '値'), '789');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('789'), findsOneWidget);

    // 4. double型の編集
    await tester.tap(find.text('pref_key_4'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, '値'), '4.56');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('4.56'), findsOneWidget);
  });

  testWidgets('SharedPreferences追加ダイアログでbool型のスイッチ切り替え動作が正しく動くこと', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestWidget(flavor: Flavor.dev));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'キー'),
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

    expect(find.text('new_bool_key_2'), findsOneWidget);
    final tileFinder = find.ancestor(
      of: find.text('true'),
      matching: find.widgetWithText(ListTile, 'new_bool_key_2'),
    );
    expect(tileFinder, findsOneWidget);
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
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('ja'),
          home: DeveloperStorageScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Simulated Prefs Error'), findsOneWidget);

    await tester.tap(find.text('SecureStorage'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Simulated Secure Error'), findsOneWidget);
  });
}
