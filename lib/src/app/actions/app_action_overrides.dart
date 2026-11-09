import 'package:flutter_sample/src/app/actions/app_action_dispatcher_impl.dart';
import 'package:flutter_sample/src/core/actions/app_action_dispatcher.dart';

/// アプリ機能実行ディスパッチャーのオーバーライド設定を取得します。
List<dynamic> getAppActionOverrides() {
  return [
    appActionDispatcherProvider.overrideWith(AppActionDispatcherImpl.new),
  ];
}
