import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/ceiling.dart';
import '../theme/app_theme.dart';

/// Shift turining kichik ko'rgazmasi.
///
/// Rasm internetdan yuklanmaydi — har bir tur shu yerda chiziladi, shuning
/// uchun ko'rgazma internetsiz ham, sekin tarmoqda ham bir xil ochiladi.
class CeilingPreview extends StatelessWidget {
  const CeilingPreview({
    super.key,
    required this.design,
    this.radius = 14,
  });

  final CeilingDesign design;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: CustomPaint(
        painter: _CeilingPainter(design),
        isComplex: true,
        size: Size.infinite,
      ),
    );
  }
}

class _CeilingPainter extends CustomPainter {
  const _CeilingPainter(this.design);

  final CeilingDesign design;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    switch (design) {
      case CeilingDesign.glossy:
        _glossy(canvas, rect);
      case CeilingDesign.matte:
        _matte(canvas, rect);
      case CeilingDesign.satin:
        _satin(canvas, rect);
      case CeilingDesign.photoPrint:
        _photoPrint(canvas, rect);
      case CeilingDesign.multiLevel:
        _multiLevel(canvas, rect);
      case CeilingDesign.starrySky:
        _starrySky(canvas, rect);
    }
  }

  /// Oyna kabi aks ettiruvchi yuza — qiya yorug'lik chizig'i bilan.
  void _glossy(Canvas canvas, Rect rect) {
    _fill(canvas, rect, const <Color>[Color(0xFF123E39), Color(0xFF061F1B)]);
    final shine = Paint()
      ..shader = ui.Gradient.linear(
        rect.topLeft,
        rect.bottomRight,
        <Color>[
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: 0.42),
          Colors.white.withValues(alpha: 0),
        ],
        <double>[0.28, 0.46, 0.62],
      );
    canvas.drawRect(rect, shine);
    _lamp(canvas, rect, glow: 0.30);
  }

  /// Tekis, aks ettirmaydigan yuza.
  void _matte(Canvas canvas, Rect rect) {
    _fill(canvas, rect, const <Color>[Color(0xFF2A2A28), Color(0xFF1B1B1A)]);
    final soft = Paint()
      ..shader = ui.Gradient.radial(
        rect.topCenter + Offset(0, rect.height * 0.15),
        rect.width * 0.75,
        <Color>[
          Colors.white.withValues(alpha: 0.10),
          Colors.white.withValues(alpha: 0),
        ],
      );
    canvas.drawRect(rect, soft);
    _lamp(canvas, rect, glow: 0.12);
  }

  /// Yumshoq marvarid yaltirashi.
  void _satin(Canvas canvas, Rect rect) {
    _fill(canvas, rect, const <Color>[Color(0xFF1E3A36), Color(0xFF14211F)]);
    for (var i = 0; i < 3; i++) {
      final dy = rect.height * (0.25 + i * 0.22);
      final paint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(rect.left, dy),
          Offset(rect.right, dy + rect.height * 0.1),
          <Color>[
            AppColors.goldSoft.withValues(alpha: 0),
            AppColors.goldSoft.withValues(alpha: 0.16 - i * 0.04),
            AppColors.goldSoft.withValues(alpha: 0),
          ],
          const <double>[0, 0.5, 1],
        )
        ..strokeWidth = rect.height * 0.09
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(rect.left, dy),
        Offset(rect.right, dy + rect.height * 0.06),
        paint,
      );
    }
    _lamp(canvas, rect, glow: 0.2);
  }

  /// Shiftga bosilgan rasm — osmon va bulutlar.
  void _photoPrint(Canvas canvas, Rect rect) {
    _fill(canvas, rect, const <Color>[Color(0xFF2E6C8E), Color(0xFF7FB4CC)]);
    final cloud = Paint()..color = Colors.white.withValues(alpha: 0.75);
    void puff(double cx, double cy, double r) {
      canvas.drawCircle(
        Offset(rect.left + rect.width * cx, rect.top + rect.height * cy),
        rect.width * r,
        cloud,
      );
    }

    puff(0.26, 0.62, 0.11);
    puff(0.36, 0.58, 0.14);
    puff(0.48, 0.64, 0.10);
    puff(0.72, 0.34, 0.08);
    puff(0.80, 0.31, 0.10);
  }

  /// Ikki daraja va yashirin yoritgich.
  void _multiLevel(Canvas canvas, Rect rect) {
    _fill(canvas, rect, const <Color>[Color(0xFF232323), Color(0xFF141414)]);
    final inner = Rect.fromLTRB(
      rect.left + rect.width * 0.14,
      rect.top + rect.height * 0.18,
      rect.right - rect.width * 0.14,
      rect.bottom - rect.height * 0.18,
    );
    final innerRRect = RRect.fromRectAndRadius(
      inner,
      Radius.circular(rect.shortestSide * 0.12),
    );
    canvas.drawRRect(
      innerRRect,
      Paint()..color = const Color(0xFF0D2E28),
    );
    canvas.drawRRect(
      innerRRect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(rect.shortestSide * 0.035, 1.2)
        ..color = AppColors.gold.withValues(alpha: 0.85)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          rect.shortestSide * 0.035,
        ),
    );
    _lamp(canvas, rect, glow: 0.22);
  }

  /// Optik tolali yulduzlar.
  void _starrySky(Canvas canvas, Rect rect) {
    _fill(canvas, rect, const <Color>[Color(0xFF101A33), Color(0xFF05070F)]);
    // Aniq ketma-ketlik — har chizishda yulduzlar bir joyda turadi.
    final random = math.Random(7);
    final star = Paint()..color = AppColors.goldSoft;
    for (var i = 0; i < 46; i++) {
      final dx = rect.left + random.nextDouble() * rect.width;
      final dy = rect.top + random.nextDouble() * rect.height;
      final radius = rect.shortestSide * (0.006 + random.nextDouble() * 0.014);
      star.color = AppColors.goldSoft.withValues(
        alpha: 0.35 + random.nextDouble() * 0.6,
      );
      canvas.drawCircle(Offset(dx, dy), radius, star);
    }
  }

  void _fill(Canvas canvas, Rect rect, List<Color> colors) {
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(rect.topLeft, rect.bottomRight, colors),
    );
  }

  /// Shiftdagi yoritgich dog'i — yuza qanchalik aks ettirishini ko'rsatadi.
  void _lamp(Canvas canvas, Rect rect, {required double glow}) {
    final center = Offset(
      rect.left + rect.width * 0.74,
      rect.top + rect.height * 0.30,
    );
    final radius = rect.shortestSide * 0.30;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = ui.Gradient.radial(
          center,
          radius,
          <Color>[
            AppColors.goldSoft.withValues(alpha: glow),
            AppColors.goldSoft.withValues(alpha: 0),
          ],
        ),
    );
    canvas.drawCircle(
      center,
      rect.shortestSide * 0.055,
      Paint()..color = AppColors.goldSoft.withValues(alpha: 0.55 + glow),
    );
  }

  @override
  bool shouldRepaint(_CeilingPainter oldDelegate) =>
      oldDelegate.design != design;
}
