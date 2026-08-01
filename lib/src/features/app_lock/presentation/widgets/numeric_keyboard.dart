import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 🔐 パスコード入力用のテンキーウィジェット
class NumericKeyboard extends StatelessWidget {
  /// コンストラクタ
  const NumericKeyboard({
    required this.onNumberPressed,
    required this.onBackspacePressed,
    this.onBiometricPressed,
    super.key,
  });

  /// 数字ボタンが押された時のコールバック
  final ValueChanged<String> onNumberPressed;

  /// Backspace（削除）ボタンが押された時のコールバック
  final VoidCallback onBackspacePressed;

  /// 生体認証ボタンが押された時のオプショナルコールバック
  final VoidCallback? onBiometricPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['1', '2', '3'].map(_buildKey).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['4', '5', '6'].map(_buildKey).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['7', '8', '9'].map(_buildKey).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // 左下: 生体認証ボタン (指定されている場合) または空枠
            if (onBiometricPressed != null)
              _buildIconButton(
                icon: Icons.fingerprint,
                onPressed: () {
                  unawaited(HapticFeedback.lightImpact());
                  onBiometricPressed?.call();
                },
              )
            else
              const SizedBox(width: 72, height: 72),

            // 中央下: '0'
            _buildKey('0'),

            // 右下: Backspaceボタン
            _buildIconButton(
              icon: Icons.backspace_outlined,
              onPressed: () {
                unawaited(HapticFeedback.lightImpact());
                onBackspacePressed();
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKey(String number) {
    return SizedBox(
      width: 72,
      height: 72,
      child: OutlinedButton(
        onPressed: () {
          unawaited(HapticFeedback.lightImpact());
          onNumberPressed(number);
        },
        style: OutlinedButton.styleFrom(
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          number,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 72,
      height: 72,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 28),
      ),
    );
  }
}
