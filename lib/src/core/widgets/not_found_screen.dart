// 不正なURLにアクセスしたときの画面。
// 初心者向けメモ：実アプリでは「トップへ戻る」などの導線を置くのが定番です。

import 'package:flutter/material.dart';
import 'package:flutter_sample/l10n/app_localizations.dart';
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
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.notFoundTitle)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppLocalizations.of(context)!.notFoundMessage),
            if (unknownPath != null) ...[
              const SizedBox(height: 8),
              Text('path: $unknownPath'),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/'),
              child: Text(AppLocalizations.of(context)!.notFoundBackToHome),
            ),
          ],
        ),
      ),
    );
  }
}
