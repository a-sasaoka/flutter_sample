import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_sample/src/core/ui/l10n_extension.dart';
import 'package:flutter_sample/src/core/utils/connectivity_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// ネットワーク切断・復旧を全画面で自動通知するグローバルバナー
class OfflineBanner extends ConsumerStatefulWidget {
  /// コンストラクタ
  const OfflineBanner({
    this.animationDuration = const Duration(milliseconds: 300),
    this.restoreDisplayDuration = const Duration(seconds: 2),
    super.key,
  });

  /// アニメーション時間（テスト用カスタマイズ可能）
  final Duration animationDuration;

  /// オンライン復帰時のバナー表示維持時間（テスト用カスタマイズ可能）
  final Duration restoreDisplayDuration;

  @override
  ConsumerState<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends ConsumerState<OfflineBanner> {
  bool _isVisible = false;
  bool _isOnlineBanner = false;
  bool? _lastIsOnline;
  Timer? _hideTimer;

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _handleConnectivityChange(bool isOnline) {
    if (_lastIsOnline == null) {
      _lastIsOnline = isOnline;
      if (!isOnline) {
        _isVisible = true;
        _isOnlineBanner = false;
      }
      return;
    }

    if (_lastIsOnline == isOnline) {
      return;
    }

    _lastIsOnline = isOnline;
    _hideTimer?.cancel();

    if (!isOnline) {
      setState(() {
        _isVisible = true;
        _isOnlineBanner = false;
      });
    } else {
      setState(() {
        _isVisible = true;
        _isOnlineBanner = true;
      });
      _hideTimer = Timer(widget.restoreDisplayDuration, () {
        if (mounted) {
          setState(() {
            _isVisible = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(isOnlineProvider, (_, next) {
      _handleConnectivityChange(next);
    });

    final currentIsOnline = ref.watch(isOnlineProvider);
    if (_lastIsOnline == null) {
      _handleConnectivityChange(currentIsOnline);
    }

    final l10n = context.l10n;
    final theme = Theme.of(context);

    final backgroundColor = _isOnlineBanner
        ? Colors.green.shade700
        : Colors.red.shade800;
    final icon = _isOnlineBanner ? Icons.wifi : Icons.wifi_off;
    final message = _isOnlineBanner
        ? l10n.offlineBannerOnline
        : l10n.offlineBannerOffline;

    return AnimatedSize(
      duration: widget.animationDuration,
      curve: Curves.easeInOut,
      child: _isVisible
          ? Material(
              color: backgroundColor,
              elevation: 4,
              child: SafeArea(
                bottom: false,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 16, color: Colors.white),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          message,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
