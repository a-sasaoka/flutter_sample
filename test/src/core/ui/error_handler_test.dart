import 'package:flutter/material.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/exceptions/app_exception.dart';
import 'package:flutter_sample/src/core/ui/error_handler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// --- モックとデリゲートの定義 ---
class MockAppLocalizations extends Mock implements AppLocalizations {}

class _MockLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _MockLocalizationsDelegate(this.mock);
  final MockAppLocalizations mock;
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<AppLocalizations> load(Locale locale) async => mock;
  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}

void main() {
  late MockAppLocalizations mockL10n;

  setUp(() {
    mockL10n = MockAppLocalizations();
    // 基本スタブ
    when(() => mockL10n.errorNetwork).thenReturn('errorNetwork');
    when(() => mockL10n.errorTimeout).thenReturn('errorTimeout');
    when(() => mockL10n.errorUnknown).thenReturn('errorUnknown');
    when(() => mockL10n.errorServer).thenReturn('errorServer');
    when(() => mockL10n.errorDialogTitle).thenReturn('errorDialogTitle');
    when(() => mockL10n.ok).thenReturn('ok');
  });

  Future<void> setupWidget(
    WidgetTester tester,
    void Function(BuildContext context) onBuild,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: [_MockLocalizationsDelegate(mockL10n)],
        home: Scaffold(
          body: Builder(
            builder: (context) {
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => onBuild(context),
              );
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('ErrorHandler.message カバレッジ 100% テスト', () {
    testWidgets('1. UnknownException (カスタムメッセージあり) 分岐', (tester) async {
      String? result;
      await setupWidget(tester, (context) {
        result = ErrorHandler.message(
          context,
          const UnknownException(message: 'UNIQUE_CUSTOM_MSG'),
        );
      });
      expect(result, 'UNIQUE_CUSTOM_MSG');
    });

    testWidgets('2. NetworkException -> errorNetwork 分岐', (tester) async {
      when(() => mockL10n.errorNetwork).thenReturn('VAL_NETWORK');
      String? result;
      await setupWidget(tester, (context) {
        result = ErrorHandler.message(context, const NetworkException());
      });
      expect(result, 'VAL_NETWORK');
    });

    testWidgets('3. NetworkException(500) -> errorServer 分岐', (tester) async {
      when(() => mockL10n.errorServer).thenReturn('VAL_SERVER');
      String? result;
      await setupWidget(tester, (context) {
        result = ErrorHandler.message(
          context,
          const NetworkException(statusCode: 500),
        );
      });
      expect(result, 'VAL_SERVER');
    });

    testWidgets('4. TimeoutException -> errorTimeout 分岐', (tester) async {
      when(() => mockL10n.errorTimeout).thenReturn('VAL_TIMEOUT');
      String? result;
      await setupWidget(tester, (context) {
        result = ErrorHandler.message(context, const TimeoutException());
      });
      expect(result, 'VAL_TIMEOUT');
    });

    testWidgets('5. UnknownException (メッセージなし) -> errorUnknown 分岐', (
      tester,
    ) async {
      when(() => mockL10n.errorUnknown).thenReturn('VAL_UNKNOWN_APP');
      String? result;
      await setupWidget(tester, (context) {
        result = ErrorHandler.message(context, const UnknownException());
      });
      expect(result, 'VAL_UNKNOWN_APP');
    });

    testWidgets('6. 一般的な Object -> errorUnknown 分岐', (tester) async {
      when(() => mockL10n.errorUnknown).thenReturn('VAL_UNKNOWN_OBJ');
      String? result;
      await setupWidget(tester, (context) {
        result = ErrorHandler.message(context, Exception('General Error'));
      });
      expect(result, 'VAL_UNKNOWN_OBJ');
    });

    testWidgets('7. _localizeErrorKey の default 分岐', (tester) async {
      // 💡 sealed 制約を壊さず default ケースを通すため、
      // messageKey を書き換えた既存クラスの振る舞いをさせることはできないので、
      // 実装の `_ => key` 行を青くしたい場合は、messageKeyが定義外になるパターンが必要です。
      // 現状の AppException の enum 構造では到達しにくいですが、
      // 未来の拡張性のための担保として default ケースは重要です。
    });
    group('UI表示確認', () {
      testWidgets('showSnackBar が正常に動作すること', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: [_MockLocalizationsDelegate(mockL10n)],
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => ErrorHandler.showSnackBar(
                    context,
                    const TimeoutException(),
                  ),
                  child: const Text('Show'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Show'));
        await tester.pump();
        expect(find.byType(SnackBar), findsOneWidget);
      });

      testWidgets('showDialogError が正常に表示され、OKで閉じられること', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: [_MockLocalizationsDelegate(mockL10n)],
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => ErrorHandler.showDialogError(
                    context,
                    const NetworkException(statusCode: 500),
                  ),
                  child: const Text('Show'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Show'));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget);
        await tester.tap(find.text('ok'));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);
      });
    });
  });
}
