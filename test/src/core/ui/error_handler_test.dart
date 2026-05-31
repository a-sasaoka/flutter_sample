import 'package:checks/checks.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/exceptions/app_exception.dart';
import 'package:flutter_sample/src/core/exceptions/firebase_auth_error_codes.dart';
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
    when(
      () => mockL10n.errorUnauthenticated,
    ).thenReturn('errorUnauthenticated');
    when(() => mockL10n.errorUnauthorized).thenReturn('errorUnauthorized');
    when(() => mockL10n.errorDataParse).thenReturn('errorDataParse');
    when(() => mockL10n.errorDatabase).thenReturn('errorDatabase');
    when(() => mockL10n.errorBadRequest).thenReturn('errorBadRequest');
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
            const AppException.unknown(message: 'UNIQUE_CUSTOM_MSG'),
          );
        },
      );
      check(result).equals('UNIQUE_CUSTOM_MSG');
    });

    testWidgets('2. AppException (Network/Server/Timeout/Unknown) の分岐が正しいこと', (
      tester,
    ) async {
      await setupWidget(
        tester,
        onBuild: (context) {
          // それぞれの Enum (型) に応じて正しい多言語化キーが返るか検証
          check(
            ErrorHandler.message(context, const AppException.network()),
          ).equals('errorNetwork');
          check(
            ErrorHandler.message(
              context,
              const AppException.server(statusCode: 500),
            ),
          ).equals('errorServer (500)');
          check(
            ErrorHandler.message(context, const AppException.unauthenticated()),
          ).equals('errorUnauthenticated');
          check(
            ErrorHandler.message(context, const AppException.unauthorized()),
          ).equals('errorUnauthorized');
          check(
            ErrorHandler.message(context, const AppException.dataParse()),
          ).equals('errorDataParse');
          check(
            ErrorHandler.message(context, const AppException.database()),
          ).equals('errorDatabase');
          check(
            ErrorHandler.message(
              context,
              const AppException.badRequest(statusCode: 400),
            ),
          ).equals('errorBadRequest (400)');
          check(
            ErrorHandler.message(context, const AppException.timeout()),
          ).equals('errorTimeout');
          check(
            ErrorHandler.message(context, const AppException.cancel()),
          ).equals('errorUnknown');
          check(
            ErrorHandler.message(context, const AppException.unknown()),
          ).equals('errorUnknown');
        },
      );
    });

    testWidgets('2-2. AppException (カスタムメッセージ優先) の分岐が正しいこと', (tester) async {
      await setupWidget(
        tester,
        onBuild: (context) {
          check(
            ErrorHandler.message(
              context,
              const AppException.network(message: 'CUSTOM_NETWORK'),
            ),
          ).equals('CUSTOM_NETWORK');
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
            error: const AppException.timeout(),
          );
          result = ErrorHandler.message(context, dioError);
        },
      );
      // TimeoutException として処理されていることを確認
      check(result).equals('errorTimeout');
    });

    testWidgets('4. FirebaseAuthException の各エラーコードが正しく変換されること', (tester) async {
      await setupWidget(
        tester,
        onBuild: (context) {
          check(
            ErrorHandler.message(
              context,
              FirebaseAuthException(code: FirebaseAuthErrorCodes.invalidEmail),
            ),
          ).equals('errorInvalidEmail');
          check(
            ErrorHandler.message(
              context,
              FirebaseAuthException(code: FirebaseAuthErrorCodes.userDisabled),
            ),
          ).equals('errorUserDisabled');
          check(
            ErrorHandler.message(
              context,
              FirebaseAuthException(code: FirebaseAuthErrorCodes.wrongPassword),
            ),
          ).equals('errorLoginFailed');
          check(
            ErrorHandler.message(
              context,
              FirebaseAuthException(
                code: FirebaseAuthErrorCodes.emailAlreadyInUse,
              ),
            ),
          ).equals('errorEmailAlreadyInUse');
          check(
            ErrorHandler.message(
              context,
              FirebaseAuthException(code: FirebaseAuthErrorCodes.weakPassword),
            ),
          ).equals('errorWeakPassword');
          // 未定義のコードは errorUnknown にフォールバックすること
          check(
            ErrorHandler.message(
              context,
              FirebaseAuthException(
                code: 'some-unknown-code',
              ),
            ),
          ).equals('errorUnknown');
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
      check(result).equals('errorUnknown');
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
              const AppException.timeout(),
            ),
            child: const Text('Show'),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump();

      check(find.byType(SnackBar)).findsOne();
    });

    testWidgets('showDialogError が正常に表示され、OKで閉じられること', (tester) async {
      await setupWidget(
        tester,
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => ErrorHandler.showDialogError(
              context,
              const AppException.server(statusCode: 500),
            ),
            child: const Text('Show'),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      check(find.byType(AlertDialog)).findsOne();

      await tester.tap(find.text('ok'));
      await tester.pumpAndSettle();

      check(find.byType(AlertDialog)).findsNothing();
    });
  });
}
