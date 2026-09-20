import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/qr_scanner/application/qr_scanner_history_controller.dart';
import 'package:flutter_sample/src/features/qr_scanner/application/url_launcher_service.dart';
import 'package:flutter_sample/src/features/qr_scanner/data/qr_scan_histories_dao.dart';
import 'package:flutter_sample/src/features/qr_scanner/domain/qr_scan_history_model.dart';
import 'package:flutter_sample/src/features/qr_scanner/presentation/qr_scanner_history_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker_flutter/talker_flutter.dart';

class MockQrScanHistoriesDao extends Mock implements QrScanHistoriesDao {}

class MockUrlLauncherService extends Mock implements UrlLauncherService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QrScannerHistoryScreen', () {
    late MockQrScanHistoriesDao mockDao;
    late MockUrlLauncherService mockUrlService;

    setUp(() {
      mockDao = MockQrScanHistoriesDao();
      mockUrlService = MockUrlLauncherService();
      when(() => mockUrlService.isWebUrl(any())).thenReturn(false);
    });

    Widget createWidget({required ProviderContainer container}) {
      return UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('ja')],
          home: QrScannerHistoryScreen(),
        ),
      );
    }

    testWidgets('履歴が空の場合、空案内メッセージが表示されること', (tester) async {
      when(
        () => mockDao.watchAllHistories(),
      ).thenAnswer((_) => Stream.value([]));

      final container = ProviderContainer(
        overrides: [
          qrScanHistoriesDaoProvider.overrideWithValue(mockDao),
          urlLauncherServiceProvider.overrideWithValue(mockUrlService),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(createWidget(container: container));
      await tester.pumpAndSettle();

      check(find.text('スキャン履歴')).findsOne();
      check(find.text('スキャン履歴はありません')).findsOne();
    });

    testWidgets('履歴が存在する場合、一覧表示されスワイプで個別削除できること', (tester) async {
      final now = DateTime(2026, 9, 20, 12);
      final item = QrScanHistoryModel(
        id: 10,
        rawValue: 'https://flutter.dev',
        scannedAt: now,
      );

      when(
        () => mockUrlService.isWebUrl('https://flutter.dev'),
      ).thenReturn(true);

      final fakeController = _FakeHistoryController([item]);
      final container = ProviderContainer(
        overrides: [
          qrScannerHistoryControllerProvider.overrideWith(() => fakeController),
          urlLauncherServiceProvider.overrideWithValue(mockUrlService),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(createWidget(container: container));
      await tester.pumpAndSettle();

      check(find.text('https://flutter.dev')).findsOne();

      // スワイプ削除を実行
      await tester.drag(
        find.text('https://flutter.dev'),
        const Offset(-500, 0),
      );
      await tester.pumpAndSettle();

      check(fakeController.lastDeletedId).equals(10);
      check(find.text('削除しました')).findsOne();
    });

    testWidgets('スワイプ削除で例外が発生した場合、アイテムが復元されスナックバーが表示されないこと', (tester) async {
      final item = QrScanHistoryModel(
        id: 1,
        rawValue: 'https://flutter.dev',
        scannedAt: DateTime(2026, 9, 20),
      );

      final fakeController = _FakeHistoryController([
        item,
      ], throwOnDelete: true);

      final container = ProviderContainer(
        overrides: [
          qrScannerHistoryControllerProvider.overrideWith(() => fakeController),
          urlLauncherServiceProvider.overrideWithValue(mockUrlService),
          loggerProvider.overrideWithValue(
            Talker(settings: TalkerSettings(useConsoleLogs: false)),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(createWidget(container: container));
      await tester.pumpAndSettle();

      check(find.text('https://flutter.dev')).findsOne();

      // スワイプ削除を実行
      await tester.drag(
        find.text('https://flutter.dev'),
        const Offset(-500, 0),
      );
      await tester.pumpAndSettle();

      // エラー発生のためアイテムは画面に復元され、スナックバーは表示されない
      check(fakeController.lastDeletedId).equals(1);
      check(find.text('https://flutter.dev')).findsOne();
      check(find.text('削除しました')).findsNothing();
    });

    testWidgets('履歴アイテムをタップすると結果シートが表示されること', (tester) async {
      final item = QrScanHistoryModel(
        id: 1,
        rawValue: 'https://flutter.dev',
        scannedAt: DateTime(2026, 9, 20),
      );

      final fakeController = _FakeHistoryController([item]);

      final container = ProviderContainer(
        overrides: [
          qrScannerHistoryControllerProvider.overrideWith(() => fakeController),
          urlLauncherServiceProvider.overrideWithValue(mockUrlService),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(createWidget(container: container));
      await tester.pumpAndSettle();

      await tester.tap(find.text('https://flutter.dev'));
      await tester.pumpAndSettle();

      check(find.text('スキャン結果')).findsOne();
    });

    testWidgets('全件削除ダイアログで「削除」を選択すると全削除が実行されること', (tester) async {
      final item = QrScanHistoryModel(
        id: 1,
        rawValue: 'test data',
        scannedAt: DateTime(2026, 9, 20),
      );

      final fakeController = _FakeHistoryController([item]);

      final container = ProviderContainer(
        overrides: [
          qrScannerHistoryControllerProvider.overrideWith(() => fakeController),
          urlLauncherServiceProvider.overrideWithValue(mockUrlService),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(createWidget(container: container));
      await tester.pumpAndSettle();

      // 全件削除アイコンをタップ
      await tester.tap(find.byIcon(Icons.delete_sweep));
      await tester.pumpAndSettle();

      check(find.text('すべてのスキャン履歴を削除しますか？')).findsOne();

      // 削除ボタンをタップ
      await tester.tap(find.widgetWithText(TextButton, '削除'));
      await tester.pumpAndSettle();

      check(find.text('すべての履歴を削除しました')).findsOne();
      check(fakeController.didCallDeleteAll).equals(true);
    });

    testWidgets('全件削除ダイアログで「キャンセル」を選択すると削除されないこと', (tester) async {
      final item = QrScanHistoryModel(
        id: 1,
        rawValue: 'test data',
        scannedAt: DateTime(2026, 9, 20),
      );

      final fakeController = _FakeHistoryController([item]);

      final container = ProviderContainer(
        overrides: [
          qrScannerHistoryControllerProvider.overrideWith(() => fakeController),
          urlLauncherServiceProvider.overrideWithValue(mockUrlService),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(createWidget(container: container));
      await tester.pumpAndSettle();

      // 全件削除アイコンをタップ
      await tester.tap(find.byIcon(Icons.delete_sweep));
      await tester.pumpAndSettle();

      // キャンセルボタンをタップ
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();

      check(find.text('すべてのスキャン履歴を削除しますか？')).findsNothing();
      check(fakeController.didCallDeleteAll).equals(false);
    });
  });
}

class _FakeHistoryController extends QrScannerHistoryController {
  _FakeHistoryController(this.initialList, {this.throwOnDelete = false});
  final List<QrScanHistoryModel> initialList;
  final bool throwOnDelete;
  bool didCallDeleteAll = false;
  int? lastDeletedId;

  @override
  Stream<List<QrScanHistoryModel>> build() => Stream.value(initialList);

  @override
  Future<void> deleteHistory(int id) async {
    lastDeletedId = id;
    if (throwOnDelete) {
      throw Exception('Failed to delete history');
    }
  }

  @override
  Future<void> deleteAllHistories() async {
    didCallDeleteAll = true;
  }
}
