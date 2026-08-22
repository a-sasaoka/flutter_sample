import 'dart:async';
import 'dart:io';

import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_sample/gen/assets.gen.dart';
import 'package:flutter_sample/src/core/widgets/app_lottie_widget.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';

class _FakeHttpClient extends Fake implements HttpClient {
  _FakeHttpClient(this._responseBytes);

  final List<int> _responseBytes;

  @override
  bool autoUncompress = false;

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    return _FakeHttpClientRequest(_responseBytes);
  }

  @override
  Future<HttpClientRequest> getUrl(Uri url) => openUrl('GET', url);

  @override
  void close({bool force = false}) {}
}

class _FakeHttpClientRequest extends Fake implements HttpClientRequest {
  _FakeHttpClientRequest(this._responseBytes);

  final List<int> _responseBytes;

  @override
  final HttpHeaders headers = _FakeHttpHeaders();

  @override
  bool followRedirects = true;

  @override
  int maxRedirects = 5;

  @override
  bool persistentConnection = false;

  @override
  int contentLength = 0;

  @override
  void add(List<int> data) {}

  @override
  Future<void> addStream(Stream<List<int>> stream) async {
    await stream.drain<void>();
  }

  @override
  Future<HttpClientResponse> close() async {
    return _FakeHttpClientResponse(_responseBytes);
  }
}

class _FakeHttpHeaders extends Fake implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  void forEach(void Function(String name, List<String> values) action) {}

  @override
  List<String>? operator [](String name) => null;

  @override
  String? value(String name) => null;
}

class _FakeHttpClientResponse extends StreamView<List<int>>
    implements HttpClientResponse {
  _FakeHttpClientResponse(List<int> responseBytes)
    : _responseBytes = responseBytes,
      super(Stream<List<int>>.value(responseBytes));

  final List<int> _responseBytes;

  @override
  int get statusCode => HttpStatus.ok;

  @override
  int get contentLength => _responseBytes.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  HttpHeaders get headers => _FakeHttpHeaders();

  @override
  List<Cookie> get cookies => [];

  @override
  Future<Socket> detachSocket() => throw UnimplementedError();

  @override
  String get reasonPhrase => 'OK';

  @override
  bool get isRedirect => false;

  @override
  List<RedirectInfo> get redirects => [];

  @override
  Future<HttpClientResponse> redirect([
    String? method,
    Uri? url,
    bool? followLoops,
  ]) => throw UnimplementedError();

  @override
  bool get persistentConnection => false;

  @override
  X509Certificate? get certificate => null;

  @override
  HttpConnectionInfo? get connectionInfo => null;
}

class _TestHttpOverrides extends HttpOverrides {
  _TestHttpOverrides(this._responseBytes);

  final List<int> _responseBytes;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _FakeHttpClient(_responseBytes);
  }
}

void main() {
  group('AppLottieWidget', () {
    testWidgets('AppLottieWidget.asset で Lottie アニメーションが正しく描画されること', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppLottieWidget.asset(
              lottie: Assets.animations.emptyBox,
              width: 150,
              height: 150,
              animate: false,
            ),
          ),
        ),
      );
      await tester.pump();

      check(find.byType(AppLottieWidget)).findsOne();
      check(find.byType(LottieBuilder)).findsOne();
    });

    testWidgets(
      'AppLottieWidget.network でネットワーク Lottie が正しく読み込まれ onLoaded が呼ばれること',
      (tester) async {
        var onLoadedCalled = false;
        final jsonBytes = File(
          'assets/animations/empty_box.json',
        ).readAsBytesSync();

        final previousOverrides = HttpOverrides.current;
        HttpOverrides.global = _TestHttpOverrides(jsonBytes);

        try {
          await tester.runAsync(() async {
            await NetworkLottie('https://example.com/test.json').load();
          });

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: AppLottieWidget.network(
                  url: 'https://example.com/test.json',
                  width: 120,
                  height: 120,
                  animate: false,
                  onLoaded: (composition) {
                    onLoadedCalled = true;
                  },
                ),
              ),
            ),
          );
          await tester.pump();

          check(find.byType(AppLottieWidget)).findsOne();
          check(find.byType(LottieBuilder)).findsOne();
          check(onLoadedCalled).isTrue();
          check(find.byIcon(Icons.animation)).findsNothing();
        } finally {
          HttpOverrides.global = previousOverrides;
        }
      },
    );

    testWidgets('コントローラーと各種オプションを渡して正しく動作すること', (tester) async {
      late AnimationController testController;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                testController = AnimationController(
                  vsync: const TestVSync(),
                  duration: const Duration(seconds: 1),
                );
                return AppLottieWidget.asset(
                  lottie: Assets.animations.successCheck,
                  controller: testController,
                  repeat: false,
                  reverse: true,
                  fit: BoxFit.cover,
                  animate: false,
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();

      check(find.byType(AppLottieWidget)).findsOne();
      check(find.byType(LottieBuilder)).findsOne();
      testController.dispose();
    });

    testWidgets('エラー時または不正なリソースの時にフォールバックアイコンが表示されること', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                // errorBuilder を直接検証 (network)
                const networkWidget = AppLottieWidget.network(
                  url: 'invalid_url',
                  animate: false,
                );
                final networkBuilt =
                    networkWidget.build(context) as LottieBuilder;
                return networkBuilt.errorBuilder!(
                  context,
                  Exception('load error'),
                  StackTrace.empty,
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();

      check(find.byIcon(Icons.animation)).findsOne();
    });

    testWidgets(
      'AppLottieWidget.asset の errorBuilder が呼ばれた場合にフォールバックアイコンが表示されること',
      (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  // errorBuilder を直接検証 (asset)
                  final assetWidget = AppLottieWidget.asset(
                    lottie: Assets.animations.emptyBox,
                    animate: false,
                  );
                  final assetBuilt =
                      assetWidget.build(context) as LottieBuilder;
                  return assetBuilt.errorBuilder!(
                    context,
                    Exception('asset load error'),
                    StackTrace.empty,
                  );
                },
              ),
            ),
          ),
        );
        await tester.pump();

        check(find.byIcon(Icons.animation)).findsOne();
      },
    );
  });
}
