import 'dart:async';
import 'dart:ui';

import 'package:flutter_sample/l10n/app_localizations.dart';
import 'package:flutter_sample/src/core/config/locale_provider.dart';
import 'package:flutter_sample/src/core/utils/logger_provider.dart';
import 'package:flutter_sample/src/core/utils/package_info_provider.dart';
import 'package:flutter_sample/src/features/home_widget/data/home_widget_data_source.dart';
import 'package:flutter_sample/src/features/home_widget/domain/home_widget_constants.dart';
import 'package:flutter_sample/src/features/memos/domain/memo_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talker_flutter/talker_flutter.dart';

part 'home_widget_service.g.dart';

/// ホーム画面ウィジェットとの連携（データ保存・同期・更新リクエスト）を担当するサービス
class HomeWidgetService {
  /// コンストラクタ
  HomeWidgetService({
    required HomeWidgetDataSource dataSource,
    required Talker logger,
    required AppLocalizations Function() l10nProvider,
    required String appGroupId,
  }) : _dataSource = dataSource,
       _logger = logger,
       _l10nProvider = l10nProvider,
       _appGroupId = appGroupId;

  final HomeWidgetDataSource _dataSource;
  final Talker _logger;
  final AppLocalizations Function() _l10nProvider;
  final String _appGroupId;

  /// 初期設定（App Group IDの登録）を行う
  Future<void> initialize() async {
    try {
      await _dataSource.setAppGroupId(_appGroupId);
      _logger.info(
        '📱 [HomeWidgetService] Initialized with appGroupId: $_appGroupId',
      );
    } on Exception catch (e, st) {
      _logger.handle(
        e,
        st,
        '⚠️ [HomeWidgetService] Failed to set App Group ID',
      );
    }
  }

  /// メモ一覧データからウィジェット共有ストレージを更新し、ウィジェット再描画をリクエストする
  Future<void> updateMemoWidget({required List<MemoModel> memos}) async {
    try {
      _logger.info(
        '📱 [HomeWidgetService] Updating widget with ${memos.length} memos',
      );

      final l10n = _l10nProvider();

      // 削除されていない有効なメモのみを抽出
      final activeMemos = memos.where((m) => !m.isDeleted).toList();

      if (activeMemos.isEmpty) {
        // メモが0件の場合の多言語化表示データ
        await _dataSource.saveWidgetData<int>(
          HomeWidgetConstants.keyMemoCount,
          0,
        );
        await _dataSource.saveWidgetData<String>(
          HomeWidgetConstants.keyLatestMemoId,
          '',
        );
        await _dataSource.saveWidgetData<String>(
          HomeWidgetConstants.keyLatestMemoTitle,
          l10n.widgetMemoEmptyTitle,
        );
        await _dataSource.saveWidgetData<String>(
          HomeWidgetConstants.keyLatestMemoContent,
          l10n.widgetMemoEmptyContent,
        );
        await _dataSource.saveWidgetData<String>(
          HomeWidgetConstants.keyLatestMemoUpdatedAt,
          '',
        );
      } else {
        // 最新更新日時のメモを取得（更新日時で最新のものを先頭にする）
        final sortedMemos = [...activeMemos]
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        final latestMemo = sortedMemos.first;

        final updatedAtText =
            '${latestMemo.updatedAt.month}/${latestMemo.updatedAt.day} '
            '${latestMemo.updatedAt.hour.toString().padLeft(2, '0')}:'
            '${latestMemo.updatedAt.minute.toString().padLeft(2, '0')}';

        await _dataSource.saveWidgetData<int>(
          HomeWidgetConstants.keyMemoCount,
          activeMemos.length,
        );
        await _dataSource.saveWidgetData<String>(
          HomeWidgetConstants.keyLatestMemoId,
          latestMemo.id,
        );
        await _dataSource.saveWidgetData<String>(
          HomeWidgetConstants.keyLatestMemoTitle,
          latestMemo.title,
        );
        await _dataSource.saveWidgetData<String>(
          HomeWidgetConstants.keyLatestMemoContent,
          latestMemo.content,
        );
        await _dataSource.saveWidgetData<String>(
          HomeWidgetConstants.keyLatestMemoUpdatedAt,
          updatedAtText,
        );
      }

      // ウィジェットの再描画（更新）をリクエスト
      await _dataSource.updateWidget(
        name: HomeWidgetConstants.androidWidgetName,
        iOSName: HomeWidgetConstants.iOSWidgetName,
      );

      _logger.info(
        '✅ [HomeWidgetService] Successfully requested widget update',
      );
    } on Exception catch (e, st) {
      _logger.handle(
        e,
        st,
        '⚠️ [HomeWidgetService] Failed to update memo widget',
      );
    }
  }

  /// ウィジェットタップによるアプリ起動時のURIを取得する
  Future<Uri?> getInitiallyLaunchedUri() async {
    try {
      return await _dataSource.initiallyLaunchedFromHomeWidget();
    } on Exception catch (e, st) {
      _logger.handle(
        e,
        st,
        '⚠️ [HomeWidgetService] Failed to get initial launch URI',
      );
      return null;
    }
  }

  /// ウィジェットタップによるバックグラウンド復帰時のURIストリーム
  Stream<Uri?> get widgetClicked => _dataSource.widgetClicked;
}

/// [HomeWidgetService] を提供するプロバイダー
@riverpod
HomeWidgetService homeWidgetService(Ref ref) {
  final dataSource = ref.watch(homeWidgetDataSourceProvider);
  final logger = ref.watch(loggerProvider);

  AppLocalizations getL10n() {
    final preferredLocale =
        ref.read(localeProvider).value ?? PlatformDispatcher.instance.locale;
    final matchedLocale = AppLocalizations.supportedLocales.firstWhere(
      (supported) => supported.languageCode == preferredLocale.languageCode,
      orElse: () => AppLocalizations.supportedLocales.first,
    );
    return lookupAppLocalizations(matchedLocale);
  }

  final packageInfo = ref.watch(packageInfoProvider);
  final appGroupId = HomeWidgetConstants.appGroupIdFor(packageInfo.packageName);

  return HomeWidgetService(
    dataSource: dataSource,
    logger: logger,
    l10nProvider: getL10n,
    appGroupId: appGroupId,
  );
}
