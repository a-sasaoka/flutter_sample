import 'package:flutter/material.dart';

/// [BuildContext] からタップされたウィジェットの [Rect] を取得する拡張
extension SharePositionOriginBuildContextX on BuildContext {
  /// iPadなどのポップオーバー吹き出し位置として使用する [Rect] を取得する
  Rect? get sharePositionOrigin {
    final renderBox = findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) {
      return null;
    }
    final position = renderBox.localToGlobal(Offset.zero);
    return position & renderBox.size;
  }
}
