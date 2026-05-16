import 'package:flutter/material.dart';
import 'package:flutter_sample/src/core/ui/l10n_extension.dart';
import 'package:go_router/go_router.dart';

/// NotFoundScreen ウィジェット
class NotFoundScreen extends StatelessWidget {
  /// コンストラクタ
  const NotFoundScreen({super.key, this.unknownPath});

  /// 不明なパス（URL）
  final String? unknownPath;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.notFoundTitle)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off_outlined,
                size: 80,
                color: Theme.of(
                  context,
                ).colorScheme.error.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.notFoundTitle,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.notFoundMessage,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              if (unknownPath != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'path: $unknownPath',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.home_outlined),
                label: Text(l10n.notFoundBackToHome),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
