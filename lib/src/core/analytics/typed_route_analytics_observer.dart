import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Firebase Analytics の screen_class をカスタマイズして送信するカスタム Observer
class TypedRouteAnalyticsObserver extends NavigatorObserver {
  /// コンストラクタ
  TypedRouteAnalyticsObserver({required this.analytics, required this.talker});

  /// Firebase Analytics インスタンス
  final FirebaseAnalytics analytics;

  /// Talker インスタンス
  final Talker talker;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _sendScreenView(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) {
      _sendScreenView(newRoute);
    }
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) {
      _sendScreenView(previousRoute);
    }
    super.didPop(route, previousRoute);
  }

  void _sendScreenView(Route<dynamic> route) {
    final settings = route.settings;
    final runtimeTypeName = settings.name ?? route.runtimeType.toString();

    // クラス名から GoRouter が生成した $ 記号を除去する
    final screenClass = runtimeTypeName.replaceAll(r'$', '');

    unawaited(
      analytics.logScreenView(
        screenClass: screenClass,
        screenName: screenClass,
      ),
    );

    talker.debug('📊 screen_view → $screenClass');
  }
}
