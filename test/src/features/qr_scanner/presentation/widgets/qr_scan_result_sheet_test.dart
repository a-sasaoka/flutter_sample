import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/features/qr_scanner/application/url_launcher_service.dart';
import 'package:flutter_sample/src/features/qr_scanner/presentation/widgets/qr_scan_result_sheet.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:talker_flutter/talker_flutter.dart';

class MockUrlLauncherService extends Mock implements UrlLauncherService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QrScanResultSheet', () {
    late MockUrlLauncherService mockUrlService;

    setUp(() {
      mockUrlService = MockUrlLauncherService();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (
            methodCall,
          ) async {
            return null;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    Widget createWidget({
      required String rawValue,
      required ProviderContainer container,
    }) {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('ja')],
          home: Scaffold(body: QrScanResultSheet(rawValue: rawValue)),
        ),
      );
    }

    testWidgets('URLの場合、「URLを開く」ボタンが表示されタップで openUrl が実行されること', (tester) async {
      when(
        () => mockUrlService.isWebUrl('https://example.com'),
      ).thenReturn(true);
      when(
        () => mockUrlService.openUrl('https://example.com'),
      ).thenAnswer((_) async => true);

      final container = ProviderContainer(
        overrides: [
          urlLauncherServiceProvider.overrideWithValue(mockUrlService),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        createWidget(rawValue: 'https://example.com', container: container),
      );
      await tester.pumpAndSettle();

      check(find.text('スキャン結果')).findsOne();
      check(find.text('https://example.com')).findsOne();
      check(find.text('URLを開く')).findsOne();

      await tester.tap(find.text('URLを開く'));
      await tester.pumpAndSettle();

      verify(() => mockUrlService.openUrl('https://example.com')).called(1);
    });

    testWidgets('URLを開くのに失敗した場合、SnackBarが表示されること', (tester) async {
      when(() => mockUrlService.isWebUrl('https://fail.test')).thenReturn(true);
      when(
        () => mockUrlService.openUrl('https://fail.test'),
      ).thenAnswer((_) async => false);

      final container = ProviderContainer(
        overrides: [
          urlLauncherServiceProvider.overrideWithValue(mockUrlService),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        createWidget(rawValue: 'https://fail.test', container: container),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('URLを開く'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      check(find.text('URLを開けませんでした')).findsOne();
    });

    testWidgets('URLを開く処理で例外が発生した場合、ログが記録され SnackBar が表示されること', (tester) async {
      when(
        () => mockUrlService.isWebUrl('https://error.test'),
      ).thenReturn(true);
      when(
        () => mockUrlService.openUrl('https://error.test'),
      ).thenThrow(PlatformException(code: 'ACTIVITY_NOT_FOUND'));

      final container = ProviderContainer(
        overrides: [
          urlLauncherServiceProvider.overrideWithValue(mockUrlService),
          loggerProvider.overrideWithValue(
            Talker(settings: TalkerSettings(useConsoleLogs: false)),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        createWidget(rawValue: 'https://error.test', container: container),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('URLを開く'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      check(find.text('URLを開けませんでした')).findsOne();
    });

    testWidgets('URLではないテキストの場合、「URLを開く」ボタンが表示されないこと', (tester) async {
      when(() => mockUrlService.isWebUrl('hello world')).thenReturn(false);

      final container = ProviderContainer(
        overrides: [
          urlLauncherServiceProvider.overrideWithValue(mockUrlService),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        createWidget(rawValue: 'hello world', container: container),
      );
      await tester.pumpAndSettle();

      check(find.text('hello world')).findsOne();
      check(find.text('URLを開く')).findsNothing();
    });

    testWidgets('コピーボタンをタップすると SnackBar が表示されること', (tester) async {
      when(() => mockUrlService.isWebUrl('test copy')).thenReturn(false);

      final container = ProviderContainer(
        overrides: [
          urlLauncherServiceProvider.overrideWithValue(mockUrlService),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        createWidget(rawValue: 'test copy', container: container),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('コピー'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      check(find.text('クリップボードにコピーしました')).findsOne();
    });

    testWidgets('QrScanResultSheet.show でボトムシートとして表示できること', (tester) async {
      when(() => mockUrlService.isWebUrl('https://show.test')).thenReturn(true);

      final container = ProviderContainer(
        overrides: [
          urlLauncherServiceProvider.overrideWithValue(mockUrlService),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('ja')],
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () =>
                      QrScanResultSheet.show(context, 'https://show.test'),
                  child: const Text('Open Sheet'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      check(find.text('https://show.test')).findsOne();

      // もう一度スキャンで閉じる
      await tester.tap(find.text('もう一度スキャン'));
      await tester.pumpAndSettle();

      check(find.text('https://show.test')).findsNothing();
    });
  });
}
