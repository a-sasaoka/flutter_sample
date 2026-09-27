import 'dart:async';
import 'dart:ui';

import 'package:checks/checks.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/config/locale_provider.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/core/utils/package_info_provider.dart';
import 'package:flutter_sample/src/features/home_widget/application/home_widget_service.dart';
import 'package:flutter_sample/src/features/home_widget/data/home_widget_data_source.dart';
import 'package:flutter_sample/src/features/home_widget/domain/home_widget_constants.dart';
import 'package:flutter_sample/src/features/memos/domain/memo_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:talker_flutter/talker_flutter.dart';

class MockHomeWidgetDataSource extends Mock implements HomeWidgetDataSource {}

class MockTalker extends Mock implements Talker {}

class MockAppLocalizations extends Mock implements AppLocalizations {}

class MockPackageInfo extends Mock implements PackageInfo {}

class _FakeLocaleNotifier extends LocaleNotifier {
  _FakeLocaleNotifier(this.locale);
  final Locale? locale;

  @override
  Future<Locale?> build() async => locale;
}

void main() {
  group('HomeWidgetService', () {
    late MockHomeWidgetDataSource mockDataSource;
    late MockTalker mockLogger;
    late MockAppLocalizations mockL10n;
    late HomeWidgetService service;
    const testAppGroupId = 'group.jp.example.sample.test';

    setUp(() {
      mockDataSource = MockHomeWidgetDataSource();
      mockLogger = MockTalker();
      mockL10n = MockAppLocalizations();

      when(() => mockL10n.widgetMemoEmptyTitle).thenReturn('メモがありません');
      when(
        () => mockL10n.widgetMemoEmptyContent,
      ).thenReturn('＋ボタンから最初のメモを作成しましょう！');

      service = HomeWidgetService(
        dataSource: mockDataSource,
        logger: mockLogger,
        l10nProvider: () => mockL10n,
        appGroupId: testAppGroupId,
      );
    });

    group('initialize', () {
      test('正常系: App Group IDが設定されログが出力されること', () async {
        when(
          () => mockDataSource.setAppGroupId(any()),
        ).thenAnswer((_) async => true);

        await service.initialize();

        verify(() => mockDataSource.setAppGroupId(testAppGroupId)).called(1);
        verify(
          () => mockLogger.info(
            '📱 [HomeWidgetService] Initialized with appGroupId: '
            '$testAppGroupId',
          ),
        ).called(1);
      });

      test('異常系: setAppGroupId が例外を投げた場合に安全に捕捉されること', () async {
        final exception = Exception('Native failure');
        when(() => mockDataSource.setAppGroupId(any())).thenThrow(exception);

        await service.initialize();

        verify(() => mockDataSource.setAppGroupId(testAppGroupId)).called(1);
        verify(
          () => mockLogger.handle(
            exception,
            any(),
            '⚠️ [HomeWidgetService] Failed to set App Group ID',
          ),
        ).called(1);
      });
    });

    group('updateMemoWidget', () {
      test('メモが0件のとき、空状態の多言語化データが保存されウィジェット更新がリクエストされること', () async {
        when(
          () => mockDataSource.saveWidgetData<int>(any(), any()),
        ).thenAnswer((_) async => true);
        when(
          () => mockDataSource.saveWidgetData<String>(any(), any()),
        ).thenAnswer((_) async => true);
        when(
          () => mockDataSource.updateWidget(
            name: any(named: 'name'),
            androidName: any(named: 'androidName'),
            iOSName: any(named: 'iOSName'),
            qualifiedAndroidName: any(named: 'qualifiedAndroidName'),
          ),
        ).thenAnswer((_) async => true);

        await service.updateMemoWidget(memos: []);

        verify(
          () => mockDataSource.saveWidgetData<int>(
            HomeWidgetConstants.keyMemoCount,
            0,
          ),
        ).called(1);
        verify(
          () => mockDataSource.saveWidgetData<String>(
            HomeWidgetConstants.keyLatestMemoId,
            '',
          ),
        ).called(1);
        verify(
          () => mockDataSource.saveWidgetData<String>(
            HomeWidgetConstants.keyLatestMemoTitle,
            'メモがありません',
          ),
        ).called(1);
        verify(
          () => mockDataSource.saveWidgetData<String>(
            HomeWidgetConstants.keyLatestMemoContent,
            '＋ボタンから最初のメモを作成しましょう！',
          ),
        ).called(1);
        verify(
          () => mockDataSource.saveWidgetData<String>(
            HomeWidgetConstants.keyLatestMemoUpdatedAt,
            '',
          ),
        ).called(1);
        verify(
          () => mockDataSource.updateWidget(
            name: HomeWidgetConstants.androidWidgetName,
            iOSName: HomeWidgetConstants.iOSWidgetName,
          ),
        ).called(1);
      });

      test('メモが存在するとき、削除済みが除外され最新の更新日時メモが保存されること', () async {
        final olderMemo = MemoModel(
          id: 'memo-1',
          title: '古いメモ',
          content: '古い内容',
          createdAt: DateTime(2026, 9, 20, 10),
          updatedAt: DateTime(2026, 9, 20, 10),
        );
        final latestMemo = MemoModel(
          id: 'memo-2',
          title: '最新メモ',
          content: '最新内容',
          createdAt: DateTime(2026, 9, 25, 9),
          updatedAt: DateTime(2026, 9, 27, 11, 30),
        );
        final deletedMemo = MemoModel(
          id: 'memo-3',
          title: '削除済みメモ',
          content: '削除された内容',
          createdAt: DateTime(2026, 9, 28, 10),
          updatedAt: DateTime(2026, 9, 28, 10),
          isDeleted: true,
        );

        when(
          () => mockDataSource.saveWidgetData<int>(any(), any()),
        ).thenAnswer((_) async => true);
        when(
          () => mockDataSource.saveWidgetData<String>(any(), any()),
        ).thenAnswer((_) async => true);
        when(
          () => mockDataSource.updateWidget(
            name: any(named: 'name'),
            androidName: any(named: 'androidName'),
            iOSName: any(named: 'iOSName'),
            qualifiedAndroidName: any(named: 'qualifiedAndroidName'),
          ),
        ).thenAnswer((_) async => true);

        await service.updateMemoWidget(
          memos: [olderMemo, latestMemo, deletedMemo],
        );

        verify(
          () => mockDataSource.saveWidgetData<int>(
            HomeWidgetConstants.keyMemoCount,
            2,
          ),
        ).called(1);
        verify(
          () => mockDataSource.saveWidgetData<String>(
            HomeWidgetConstants.keyLatestMemoId,
            'memo-2',
          ),
        ).called(1);
        verify(
          () => mockDataSource.saveWidgetData<String>(
            HomeWidgetConstants.keyLatestMemoTitle,
            '最新メモ',
          ),
        ).called(1);
        verify(
          () => mockDataSource.saveWidgetData<String>(
            HomeWidgetConstants.keyLatestMemoContent,
            '最新内容',
          ),
        ).called(1);
        verify(
          () => mockDataSource.saveWidgetData<String>(
            HomeWidgetConstants.keyLatestMemoUpdatedAt,
            '9/27 11:30',
          ),
        ).called(1);
        verify(
          () => mockDataSource.updateWidget(
            name: HomeWidgetConstants.androidWidgetName,
            iOSName: HomeWidgetConstants.iOSWidgetName,
          ),
        ).called(1);
      });

      test('全メモが削除済みのとき、0件（空状態）として扱われること', () async {
        final deletedMemo = MemoModel(
          id: 'memo-del',
          title: '削除メモ',
          content: '削除内容',
          createdAt: DateTime(2026, 9, 27),
          updatedAt: DateTime(2026, 9, 27),
          isDeleted: true,
        );

        when(
          () => mockDataSource.saveWidgetData<int>(any(), any()),
        ).thenAnswer((_) async => true);
        when(
          () => mockDataSource.saveWidgetData<String>(any(), any()),
        ).thenAnswer((_) async => true);
        when(
          () => mockDataSource.updateWidget(
            name: any(named: 'name'),
            androidName: any(named: 'androidName'),
            iOSName: any(named: 'iOSName'),
            qualifiedAndroidName: any(named: 'qualifiedAndroidName'),
          ),
        ).thenAnswer((_) async => true);

        await service.updateMemoWidget(memos: [deletedMemo]);

        verify(
          () => mockDataSource.saveWidgetData<int>(
            HomeWidgetConstants.keyMemoCount,
            0,
          ),
        ).called(1);
        verify(
          () => mockDataSource.saveWidgetData<String>(
            HomeWidgetConstants.keyLatestMemoTitle,
            'メモがありません',
          ),
        ).called(1);
      });

      test('例外発生時にクラッシュせずロガーにエラーが記録されること', () async {
        final exception = Exception('Widget update failure');
        when(
          () => mockDataSource.saveWidgetData<int>(any(), any()),
        ).thenThrow(exception);

        await service.updateMemoWidget(memos: []);

        verify(
          () => mockLogger.handle(
            exception,
            any(),
            '⚠️ [HomeWidgetService] Failed to update memo widget',
          ),
        ).called(1);
      });
    });

    group('getInitiallyLaunchedUri', () {
      test('正常系: 起動時URIを取得できること', () async {
        final testUri = Uri.parse('sampleapp://memos/create');
        when(
          () => mockDataSource.initiallyLaunchedFromHomeWidget(),
        ).thenAnswer((_) async => testUri);

        final result = await service.getInitiallyLaunchedUri();

        check(result).equals(testUri);
      });

      test('異常系: 例外発生時はnullを返しロガーに記録されること', () async {
        final exception = Exception('Launch URI error');
        when(
          () => mockDataSource.initiallyLaunchedFromHomeWidget(),
        ).thenThrow(exception);

        final result = await service.getInitiallyLaunchedUri();

        check(result).isNull();
        verify(
          () => mockLogger.handle(
            exception,
            any(),
            '⚠️ [HomeWidgetService] Failed to get initial launch URI',
          ),
        ).called(1);
      });
    });

    test('widgetClicked は dataSource.widgetClicked をそのまま返すこと', () async {
      final controller = StreamController<Uri?>();
      addTearDown(controller.close);

      when(
        () => mockDataSource.widgetClicked,
      ).thenAnswer((_) => controller.stream);

      final stream = service.widgetClicked;

      final expectation = stream.first;
      final expectedUri = Uri.parse('sampleapp://memos');
      controller.add(expectedUri);

      final actualUri = await expectation;
      check(actualUri).equals(expectedUri);
    });

    group('homeWidgetServiceProvider', () {
      test('ProviderContainer から正しくインスタンスが生成されること', () {
        final mockPackageInfo = MockPackageInfo();
        when(
          () => mockPackageInfo.packageName,
        ).thenReturn('jp.example.sample.local');

        final container = ProviderContainer(
          overrides: [
            homeWidgetDataSourceProvider.overrideWithValue(mockDataSource),
            loggerProvider.overrideWithValue(mockLogger),
            packageInfoProvider.overrideWithValue(mockPackageInfo),
          ],
        );
        addTearDown(container.dispose);

        final actualService = container.read(homeWidgetServiceProvider);
        check(actualService).isA<HomeWidgetService>();
      });

      test('ProviderContainer から取得したサービスで updateMemoWidget を実行した際、 '
          'getL10n が端末言語（またはデフォルト）で呼び出され多言語データが保存されること', () async {
        final mockPackageInfo = MockPackageInfo();
        when(
          () => mockPackageInfo.packageName,
        ).thenReturn('jp.example.sample.local');
        when(
          () => mockDataSource.saveWidgetData<int>(any(), any()),
        ).thenAnswer((_) async => true);
        when(
          () => mockDataSource.saveWidgetData<String>(any(), any()),
        ).thenAnswer((_) async => true);
        when(
          () => mockDataSource.updateWidget(
            name: any(named: 'name'),
            iOSName: any(named: 'iOSName'),
            androidName: any(named: 'androidName'),
            qualifiedAndroidName: any(named: 'qualifiedAndroidName'),
          ),
        ).thenAnswer((_) async => true);

        final container = ProviderContainer(
          overrides: [
            homeWidgetDataSourceProvider.overrideWithValue(mockDataSource),
            loggerProvider.overrideWithValue(mockLogger),
            packageInfoProvider.overrideWithValue(mockPackageInfo),
          ],
        );
        addTearDown(container.dispose);

        final actualService = container.read(homeWidgetServiceProvider);
        await actualService.updateMemoWidget(memos: []);

        verify(
          () => mockDataSource.saveWidgetData<int>(
            HomeWidgetConstants.keyMemoCount,
            0,
          ),
        ).called(1);
        verify(
          () => mockDataSource.saveWidgetData<String>(
            HomeWidgetConstants.keyLatestMemoTitle,
            any(),
          ),
        ).called(1);
      });

      test('localeProvider に設定がある場合（日本語）、そのロケールで getL10n が動作すること', () async {
        final mockPackageInfo = MockPackageInfo();
        when(
          () => mockPackageInfo.packageName,
        ).thenReturn('jp.example.sample.local');
        when(
          () => mockDataSource.saveWidgetData<int>(any(), any()),
        ).thenAnswer((_) async => true);
        when(
          () => mockDataSource.saveWidgetData<String>(any(), any()),
        ).thenAnswer((_) async => true);
        when(
          () => mockDataSource.updateWidget(
            name: any(named: 'name'),
            iOSName: any(named: 'iOSName'),
            androidName: any(named: 'androidName'),
            qualifiedAndroidName: any(named: 'qualifiedAndroidName'),
          ),
        ).thenAnswer((_) async => true);

        final container = ProviderContainer(
          overrides: [
            homeWidgetDataSourceProvider.overrideWithValue(mockDataSource),
            loggerProvider.overrideWithValue(mockLogger),
            packageInfoProvider.overrideWithValue(mockPackageInfo),
            localeProvider.overrideWith(
              () => _FakeLocaleNotifier(const Locale('ja')),
            ),
          ],
        );
        addTearDown(container.dispose);

        container.listen(localeProvider, (_, _) {});
        await Future<void>.delayed(Duration.zero);

        final actualService = container.read(homeWidgetServiceProvider);
        await actualService.updateMemoWidget(memos: []);

        verify(
          () => mockDataSource.saveWidgetData<String>(
            HomeWidgetConstants.keyLatestMemoTitle,
            'メモがありません',
          ),
        ).called(1);
      });

      test(
        'localeProvider にサポート対象外の言語（fr-FR）が指定されている場合、デフォルト言語（en）にフォールバックすること',
        () async {
          final mockPackageInfo = MockPackageInfo();
          when(
            () => mockPackageInfo.packageName,
          ).thenReturn('jp.example.sample.local');
          when(
            () => mockDataSource.saveWidgetData<int>(any(), any()),
          ).thenAnswer((_) async => true);
          when(
            () => mockDataSource.saveWidgetData<String>(any(), any()),
          ).thenAnswer((_) async => true);
          when(
            () => mockDataSource.updateWidget(
              name: any(named: 'name'),
              iOSName: any(named: 'iOSName'),
              androidName: any(named: 'androidName'),
              qualifiedAndroidName: any(named: 'qualifiedAndroidName'),
            ),
          ).thenAnswer((_) async => true);

          final container = ProviderContainer(
            overrides: [
              homeWidgetDataSourceProvider.overrideWithValue(mockDataSource),
              loggerProvider.overrideWithValue(mockLogger),
              packageInfoProvider.overrideWithValue(mockPackageInfo),
              localeProvider.overrideWith(
                () => _FakeLocaleNotifier(const Locale('fr', 'FR')),
              ),
            ],
          );
          addTearDown(container.dispose);

          container.listen(localeProvider, (_, _) {});
          await Future<void>.delayed(Duration.zero);

          final actualService = container.read(homeWidgetServiceProvider);
          await actualService.updateMemoWidget(memos: []);

          verify(
            () => mockDataSource.saveWidgetData<String>(
              HomeWidgetConstants.keyLatestMemoTitle,
              'No memos yet',
            ),
          ).called(1);
        },
      );
    });
  });
}
