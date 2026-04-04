import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/exceptions/app_exception.dart';
import 'package:flutter_sample/src/core/ui/error_handler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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
    when(() => mockL10n.errorNetwork).thenReturn('errorNetwork');
    when(() => mockL10n.errorTimeout).thenReturn('errorTimeout');
    when(() => mockL10n.errorUnknown).thenReturn('errorUnknown');
    when(() => mockL10n.errorServer).thenReturn('errorServer');
    when(() => mockL10n.errorDialogTitle).thenReturn('errorDialogTitle');
    when(() => mockL10n.errorInvalidEmail).thenReturn('errorInvalidEmail');
    when(() => mockL10n.errorUserDisabled).thenReturn('errorUserDisabled');
    when(() => mockL10n.errorLoginFailed).thenReturn('errorLoginFailed');
    when(
      () => mockL10n.errorEmailAlreadyInUse,
    ).thenReturn('errorEmailAlreadyInUse');
    when(() => mockL10n.errorWeakPassword).thenReturn('errorWeakPassword');
    when(() => mockL10n.ok).thenReturn('ok');
    when(() => mockL10n.close).thenReturn('close');
  });

  Future<void> setupWidget(
    WidgetTester tester, {
    void Function(BuildContext context)? onBuild,
    Widget? child,
  }) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) {
            if (onBuild != null) {
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => onBuild(context),
              );
              return const Scaffold(body: SizedBox());
            }
            return Scaffold(body: child);
          },
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: [_MockLocalizationsDelegate(mockL10n)],
      ),
    );
    await tester.pumpAndSettle();
  }

  group('ErrorHandler.message テスト', () {
    testWidgets('1. UnknownException (カスタムメッセージあり) 分岐', (tester) async {
      String? result;
      await setupWidget(
        tester,
        onBuild: (context) {
          result = ErrorHandler.message(
            context,
            const UnknownException(message: 'UNIQUE_CUSTOM_MSG'),
          );
        },
      );
      expect(result, 'UNIQUE_CUSTOM_MSG');
    });

    testWidgets('2. AppException (Network/Server/Timeout/Unknown) の分岐が正しいこと', (
      tester,
    ) async {
      await setupWidget(
        tester,
        onBuild: (context) {
          // それぞれの Enum (型) に応じて正しい多言語化キーが返るか検証
          expect(
            ErrorHandler.message(context, const NetworkException()),
            'errorNetwork',
          );
          expect(
            ErrorHandler.message(
              context,
              const NetworkException(statusCode: 500),
            ),
            'errorServer',
          );
          expect(
            ErrorHandler.message(context, const TimeoutException()),
            'errorTimeout',
          );
          expect(
            ErrorHandler.message(context, const UnknownException()),
            'errorUnknown',
          );
        },
      );
    });

    testWidgets('3. DioException でラップされている場合、中身の AppException を取り出して処理すること', (
      tester,
    ) async {
      String? result;
      await setupWidget(
        tester,
        onBuild: (context) {
          // DioException の中に TimeoutException を仕込む
          final dioError = DioException(
            requestOptions: RequestOptions(path: '/'),
            error: const TimeoutException(),
          );
          result = ErrorHandler.message(context, dioError);
        },
      );
      // TimeoutException として処理されていることを確認
      expect(result, 'errorTimeout');
    });

    testWidgets('4. FirebaseAuthException の各エラーコードが正しく変換されること', (tester) async {
      await setupWidget(
        tester,
        onBuild: (context) {
          // 各種 Firebase エラーコードの検証
          expect(
            ErrorHandler.message(
              context,
              FirebaseAuthException(code: 'invalid-email'),
            ),
            'errorInvalidEmail',
          );
          expect(
            ErrorHandler.message(
              context,
              FirebaseAuthException(code: 'user-disabled'),
            ),
            'errorUserDisabled',
          );
          expect(
            ErrorHandler.message(
              context,
              FirebaseAuthException(code: 'wrong-password'),
            ),
            'errorLoginFailed',
          );
          expect(
            ErrorHandler.message(
              context,
              FirebaseAuthException(code: 'email-already-in-use'),
            ),
            'errorEmailAlreadyInUse',
          );
          expect(
            ErrorHandler.message(
              context,
              FirebaseAuthException(code: 'weak-password'),
            ),
            'errorWeakPassword',
          );
          // 未定義のコードは errorUnknown にフォールバックすること
          expect(
            ErrorHandler.message(
              context,
              FirebaseAuthException(code: 'some-unknown-code'),
            ),
            'errorUnknown',
          );
        },
      );
    });

    testWidgets('5. 一般的な Object (予期せぬエラー) は errorUnknown になること', (
      tester,
    ) async {
      String? result;
      await setupWidget(
        tester,
        onBuild: (context) {
          result = ErrorHandler.message(context, Exception('General Error'));
        },
      );
      expect(result, 'errorUnknown');
    });
  });

  group('UI表示確認', () {
    testWidgets('showSnackBar が正常に動作すること', (tester) async {
      await setupWidget(
        tester,
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => ErrorHandler.showSnackBar(
              context,
              const TimeoutException(),
            ),
            child: const Text('Show'),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('showDialogError が正常に表示され、OKで閉じられること', (tester) async {
      await setupWidget(
        tester,
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => ErrorHandler.showDialogError(
              context,
              const NetworkException(statusCode: 500),
            ),
            child: const Text('Show'),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text('ok'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}
