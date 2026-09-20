import 'package:flutter/material.dart';
import 'package:flutter_sample/src/core/ui/l10n_extension.dart';

/// QRコードスキャン用のオーバーレイ（枠外を暗くし、四角いガイドを描画）
class QrScannerOverlay extends StatelessWidget {
  /// コンストラクタ
  const QrScannerOverlay({
    super.key,
    this.scanWindowSize = const Size(260, 260),
  });

  /// スキャン枠のサイズ
  final Size scanWindowSize;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return IgnorePointer(
      child: Stack(
        children: [
          // 枠外を暗くくり抜くカスタムペインター
          CustomPaint(
            size: Size.infinite,
            painter: _QrScannerOverlayPainter(
              scanWindowSize: scanWindowSize,
              borderColor: primaryColor,
            ),
          ),
          // 枠の下の案内文
          Align(
            child: Padding(
              padding: EdgeInsets.only(top: scanWindowSize.height + 48),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  l10n.qrScannerScanPrompt,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QrScannerOverlayPainter extends CustomPainter {
  const _QrScannerOverlayPainter({
    required this.scanWindowSize,
    required this.borderColor,
  });

  final Size scanWindowSize;
  final Color borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final scanRect = Rect.fromCenter(
      center: center,
      width: scanWindowSize.width,
      height: scanWindowSize.height,
    );

    // 1. 枠の外側を半透明の黒で塗りつぶす
    final backgroundPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.55);
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(backgroundPath, backgroundPaint);

    // 2. 四隅のコーナー枠線を描画
    final cornerPaint = Paint()
      ..color = borderColor
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLength = 24.0;
    const cornerRadius = 16.0;

    // 左上
    final topLeft = Path()
      ..moveTo(scanRect.left, scanRect.top + cornerLength)
      ..lineTo(scanRect.left, scanRect.top + cornerRadius)
      ..arcToPoint(
        Offset(scanRect.left + cornerRadius, scanRect.top),
        radius: const Radius.circular(cornerRadius),
      )
      ..lineTo(scanRect.left + cornerLength, scanRect.top);
    canvas.drawPath(topLeft, cornerPaint);

    // 右上
    final topRight = Path()
      ..moveTo(scanRect.right - cornerLength, scanRect.top)
      ..lineTo(scanRect.right - cornerRadius, scanRect.top)
      ..arcToPoint(
        Offset(scanRect.right, scanRect.top + cornerRadius),
        radius: const Radius.circular(cornerRadius),
      )
      ..lineTo(scanRect.right, scanRect.top + cornerLength);
    canvas.drawPath(topRight, cornerPaint);

    // 左下
    final bottomLeft = Path()
      ..moveTo(scanRect.left, scanRect.bottom - cornerLength)
      ..lineTo(scanRect.left, scanRect.bottom - cornerRadius)
      ..arcToPoint(
        Offset(scanRect.left + cornerRadius, scanRect.bottom),
        radius: const Radius.circular(cornerRadius),
      )
      ..lineTo(scanRect.left + cornerLength, scanRect.bottom);
    canvas.drawPath(bottomLeft, cornerPaint);

    // 右下
    final bottomRight = Path()
      ..moveTo(scanRect.right - cornerLength, scanRect.bottom)
      ..lineTo(scanRect.right - cornerRadius, scanRect.bottom)
      ..arcToPoint(
        Offset(scanRect.right, scanRect.bottom - cornerRadius),
        radius: const Radius.circular(cornerRadius),
      )
      ..lineTo(scanRect.right, scanRect.bottom - cornerLength);
    canvas.drawPath(bottomRight, cornerPaint);
  }

  @override
  bool shouldRepaint(covariant _QrScannerOverlayPainter oldDelegate) =>
      oldDelegate.scanWindowSize != scanWindowSize ||
      oldDelegate.borderColor != borderColor;
}
