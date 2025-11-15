// 不正なURLにアクセスしたときの画面。
// 初心者向けメモ：実アプリでは「トップへ戻る」などの導線を置くのが定番です。

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// NotFoundScreen ウィジェット
class NotFoundScreen extends StatelessWidget {
  /// コンストラクタ
  const NotFoundScreen({super.key, this.unknownPath});

  /// 不明なパス（URL）
  final String? unknownPath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('ページが見つかりませんでした。'),
            if (unknownPath != null) ...[
              const SizedBox(height: 8),
              Text('path: $unknownPath'),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/'),
              child: const Text('ホームへ戻る'),
            ),
          ],
        ),
      ),
    );
  }
}
