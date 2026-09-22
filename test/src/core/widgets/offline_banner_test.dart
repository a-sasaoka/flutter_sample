import 'package:checks/checks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_checks/flutter_checks.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/utils/connectivity_provider.dart';
import 'package:flutter_sample/src/core/widgets/offline_banner.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// テスト中にオンライン状態を動的に変更するための通知クラス
class _TestOnlineNotifier extends Notifier<bool> {
  _TestOnlineNotifier({required bool initial}) : _initial = initial;

  final bool _initial;

  @override
  bool build() => _initial;

  /// 現在のオンライン状態を取得する
  bool get isOnline => state;

  /// オンライン状態を更新するセッター
  set isOnline(bool value) => state = value;
}

void main() {
  group('OfflineBanner ウィジェットテスト', () {
    Widget buildTestWidget({
      required bool isOnline,
      Duration restoreDisplayDuration = const Duration(milliseconds: 500),
      Duration animationDuration = const Duration(milliseconds: 100),
    }) {
      return ProviderScope(
        overrides: [isOnlineProvider.overrideWith((ref) => isOnline)],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ja'),
          home: Scaffold(
            body: Stack(
              children: [
                const Center(child: Text('Main Content')),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: OfflineBanner(
                    animationDuration: animationDuration,
                    restoreDisplayDuration: restoreDisplayDuration,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    testWidgets('初回起動時（オンライン）はバナーが非表示であること', (tester) async {
      await tester.pumpWidget(buildTestWidget(isOnline: true));
      await tester.pumpAndSettle();

      // オフライン・オンライン復帰の文言が表示されていないこと
      check(find.text('ネットワークに接続していません')).findsNothing();
      check(find.text('インターネットに接続されました')).findsNothing();
      check(find.byIcon(Icons.wifi_off)).findsNothing();
      check(find.byIcon(Icons.wifi)).findsNothing();
    });

    testWidgets('初回起動時（オフライン）は赤色のオフラインバナーが表示されること', (tester) async {
      await tester.pumpWidget(buildTestWidget(isOnline: false));
      await tester.pumpAndSettle();

      // 赤色のオフラインバナーが表示されていること
      check(find.text('ネットワークに接続していません')).findsOne();
      check(find.byIcon(Icons.wifi_off)).findsOne();
      check(find.text('インターネットに接続されました')).findsNothing();

      final material = tester.widget<Material>(
        find.descendant(
          of: find.byType(OfflineBanner),
          matching: find.byType(Material),
        ),
      );
      check(material.color).equals(Colors.red.shade800);
    });

    testWidgets('オンラインからオフラインへ変化した際、赤色のオフラインバナーが表示されること', (tester) async {
      // 1. 最初はオンラインで起動する通知Notifierを作成
      final notifier = _TestOnlineNotifier(initial: true);
      final testOnlineProvider = NotifierProvider<_TestOnlineNotifier, bool>(
        () => notifier,
      );
      final container = ProviderContainer(
        overrides: [
          isOnlineProvider.overrideWith((ref) => ref.watch(testOnlineProvider)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('ja'),
            home: Scaffold(
              body: OfflineBanner(
                animationDuration: Duration(milliseconds: 100),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      check(find.text('ネットワークに接続していません')).findsNothing();

      // 2. オフラインに切り替え（通知を発火）
      notifier.isOnline = false;
      await tester.pumpAndSettle();

      // オフラインバナーが表示されること
      check(find.text('ネットワークに接続していません')).findsOne();
      check(find.byIcon(Icons.wifi_off)).findsOne();
    });

    testWidgets('オフラインからオンライン復旧時、緑帯が表示され、指定時間後に自動で非表示になること', (tester) async {
      final notifier = _TestOnlineNotifier(initial: false);
      final testOnlineProvider = NotifierProvider<_TestOnlineNotifier, bool>(
        () => notifier,
      );
      final container = ProviderContainer(
        overrides: [
          isOnlineProvider.overrideWith((ref) => ref.watch(testOnlineProvider)),
        ],
      );
      addTearDown(container.dispose);

      // 1. 最初はオフラインで起動
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('ja'),
            home: Scaffold(
              body: OfflineBanner(
                animationDuration: Duration(milliseconds: 100),
                restoreDisplayDuration: Duration(milliseconds: 500),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      check(find.text('ネットワークに接続していません')).findsOne();

      // 2. オンラインへ復旧（通知を発火）
      notifier.isOnline = true;
      await tester.pump();

      // 緑色の復帰バナーが表示されていること
      check(find.text('インターネットに接続されました')).findsOne();
      check(find.byIcon(Icons.wifi)).findsOne();
      final material = tester.widget<Material>(
        find.descendant(
          of: find.byType(OfflineBanner),
          matching: find.byType(Material),
        ),
      );
      check(material.color).equals(Colors.green.shade700);

      // 3. 500ミリ秒待機すると非表示になること
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      check(find.text('インターネットに接続されました')).findsNothing();
    });

    testWidgets('同一ステータス（オンライン継続）の更新では再表示されないこと', (tester) async {
      final notifier = _TestOnlineNotifier(initial: true);
      final testOnlineProvider = NotifierProvider<_TestOnlineNotifier, bool>(
        () => notifier,
      );
      final container = ProviderContainer(
        overrides: [
          isOnlineProvider.overrideWith((ref) => ref.watch(testOnlineProvider)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('ja'),
            home: Scaffold(body: OfflineBanner()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      check(find.text('ネットワークに接続していません')).findsNothing();

      // 再び同じ true をセット
      notifier.isOnline = true;
      await tester.pumpAndSettle();

      check(find.text('ネットワークに接続していません')).findsNothing();
      check(find.text('インターネットに接続されました')).findsNothing();
    });
  });
}
