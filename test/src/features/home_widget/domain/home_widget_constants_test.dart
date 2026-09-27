import 'package:checks/checks.dart';
import 'package:flutter_sample/src/features/home_widget/domain/home_widget_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HomeWidgetConstants', () {
    test('appGroupIdFor: パッケージ名から正しい App Group ID を生成すること', () {
      final appGroupId = HomeWidgetConstants.appGroupIdFor('jp.example.sample');
      check(appGroupId).equals('group.jp.example.sample');
    });

    group('qualifiedAndroidNameFor', () {
      test('Flavorサフィックス（local）が付いている場合、サフィックスを除去して完全修飾クラス名を生成すること', () {
        final qualifiedName = HomeWidgetConstants.qualifiedAndroidNameFor(
          packageName: 'jp.example.sample.local',
          flavorName: 'local',
        );
        check(qualifiedName).equals('jp.example.sample.MemoWidgetProvider');
      });

      test('Flavorサフィックス（dev）が付いている場合、サフィックスを除去して完全修飾クラス名を生成すること', () {
        final qualifiedName = HomeWidgetConstants.qualifiedAndroidNameFor(
          packageName: 'jp.example.sample.dev',
          flavorName: 'dev',
        );
        check(qualifiedName).equals('jp.example.sample.MemoWidgetProvider');
      });

      test('Flavorサフィックス（stg）が付いている場合、サフィックスを除去して完全修飾クラス名を生成すること', () {
        final qualifiedName = HomeWidgetConstants.qualifiedAndroidNameFor(
          packageName: 'jp.example.sample.stg',
          flavorName: 'stg',
        );
        check(qualifiedName).equals('jp.example.sample.MemoWidgetProvider');
      });

      test('本番環境（prod）などサフィックスが付いていない場合、そのままパッケージ名を使って完全修飾クラス名を生成すること', () {
        final qualifiedName = HomeWidgetConstants.qualifiedAndroidNameFor(
          packageName: 'jp.example.sample',
          flavorName: 'prod',
        );
        check(qualifiedName).equals('jp.example.sample.MemoWidgetProvider');
      });

      test('Flavorサフィックスと一致しないパッケージ名の場合、サフィックスを除去せずに生成すること', () {
        final qualifiedName = HomeWidgetConstants.qualifiedAndroidNameFor(
          packageName: 'jp.example.sample.other',
          flavorName: 'local',
        );
        check(
          qualifiedName,
        ).equals('jp.example.sample.other.MemoWidgetProvider');
      });
    });

    test('定数値が正しく定義されていること', () {
      check(HomeWidgetConstants.iOSWidgetName).equals('MemoWidget');
      check(HomeWidgetConstants.androidWidgetName).equals('MemoWidgetProvider');
      check(HomeWidgetConstants.keyMemoCount).equals('widget_memo_count');
      check(HomeWidgetConstants.keyLatestMemoId).equals('widget_memo_id');
      check(HomeWidgetConstants.keyLatestMemoTitle).equals('widget_memo_title');
      check(
        HomeWidgetConstants.keyLatestMemoContent,
      ).equals('widget_memo_content');
      check(
        HomeWidgetConstants.keyLatestMemoUpdatedAt,
      ).equals('widget_memo_updated_at');
      check(HomeWidgetConstants.deepLinkScheme).equals('flsamplelocal');
      check(HomeWidgetConstants.deepLinkHost).equals('memos');
      check(HomeWidgetConstants.deepLinkPathCreate).equals('/memos/create');
      check(HomeWidgetConstants.deepLinkQueryParamId).equals('id');
    });
  });
}
