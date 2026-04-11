import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_lifecycle_provider.g.dart';

/// アプリのライフサイクル（フォアグラウンド/バックグラウンド等）を監視するプロバイダー
@riverpod
class AppLifecycle extends _$AppLifecycle {
  @override
  AppLifecycleState build() {
    final observer = _AppLifecycleObserver((newState) {
      state = newState;
    });

    final binding = WidgetsBinding.instance..addObserver(observer);

    ref.onDispose(() {
      binding.removeObserver(observer);
    });

    return binding.lifecycleState ?? AppLifecycleState.resumed;
  }
}

class _AppLifecycleObserver extends WidgetsBindingObserver {
  _AppLifecycleObserver(this.onStateChanged);
  final ValueChanged<AppLifecycleState> onStateChanged;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    onStateChanged(state);
  }
}
