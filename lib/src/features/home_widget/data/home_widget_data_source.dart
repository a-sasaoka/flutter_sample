// coverage:ignore-file
import 'dart:async';

import 'package:home_widget/home_widget.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_widget_data_source.g.dart';

/// [HomeWidget] のネイティブプラットフォーム操作を抽象化するインターフェース
abstract interface class HomeWidgetDataSource {
  /// App Group ID（iOS/Android共通ストレージ領域）を設定する
  Future<bool?> setAppGroupId(String appGroupId);

  /// ウィジェット用の共有ストレージにデータを保存する
  Future<bool?> saveWidgetData<T>(String id, T? data);

  /// ウィジェット用の共有ストレージからデータを取得する
  Future<T?> getWidgetData<T>(String id, {T? defaultValue});

  /// ウィジェットの再描画（更新）をリクエストする
  Future<bool?> updateWidget({
    String? name,
    String? androidName,
    String? iOSName,
    String? qualifiedAndroidName,
  });

  /// ウィジェットタップによるアプリ起動時のURIを取得する
  Future<Uri?> initiallyLaunchedFromHomeWidget();

  /// ウィジェットタップによるバックグラウンド復帰時のURIストリーム
  Stream<Uri?> get widgetClicked;
}

/// [HomeWidgetDataSource] の本番用実装クラス
class HomeWidgetDataSourceImpl implements HomeWidgetDataSource {
  /// コンストラクタ
  const HomeWidgetDataSourceImpl();

  @override
  Future<bool?> setAppGroupId(String appGroupId) {
    return HomeWidget.setAppGroupId(appGroupId);
  }

  @override
  Future<bool?> saveWidgetData<T>(String id, T? data) {
    return HomeWidget.saveWidgetData<T>(id, data);
  }

  @override
  Future<T?> getWidgetData<T>(String id, {T? defaultValue}) {
    return HomeWidget.getWidgetData<T>(id, defaultValue: defaultValue);
  }

  @override
  Future<bool?> updateWidget({
    String? name,
    String? androidName,
    String? iOSName,
    String? qualifiedAndroidName,
  }) {
    return HomeWidget.updateWidget(
      name: name,
      androidName: androidName,
      iOSName: iOSName,
      qualifiedAndroidName: qualifiedAndroidName,
    );
  }

  @override
  Future<Uri?> initiallyLaunchedFromHomeWidget() {
    return HomeWidget.initiallyLaunchedFromHomeWidget();
  }

  @override
  Stream<Uri?> get widgetClicked => HomeWidget.widgetClicked;
}

/// [HomeWidgetDataSource] を提供するプロバイダー
@riverpod
HomeWidgetDataSource homeWidgetDataSource(Ref ref) {
  return const HomeWidgetDataSourceImpl();
}
