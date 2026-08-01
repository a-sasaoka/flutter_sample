import 'package:flutter/material.dart';

/// 🔐 パスコードの入力桁数をドットで表示するウィジェット
class PinCodeField extends StatelessWidget {
  /// コンストラクタ
  const PinCodeField({
    required this.length,
    required this.maxLength,
    super.key,
  });

  /// 現在入力されている桁数
  final int length;

  /// 入力可能な最大桁数
  final int maxLength;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(maxLength, (index) {
        final isFilled = index < length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 12),
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled
                ? theme.colorScheme.primary
                : theme.colorScheme.surfaceContainerHighest,
            border: Border.all(
              color: isFilled
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
              width: 2,
            ),
          ),
        );
      }),
    );
  }
}
