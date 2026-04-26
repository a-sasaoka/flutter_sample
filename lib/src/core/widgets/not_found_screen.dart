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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.notFoundTitle)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.notFoundMessage),
            if (unknownPath != null) ...[
              const SizedBox(height: 8),
              Text('path: $unknownPath'),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/'),
              child: Text(l10n.notFoundBackToHome),
            ),
          ],
        ),
      ),
    );
  }
}
