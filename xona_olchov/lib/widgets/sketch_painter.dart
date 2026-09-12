import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../core/geometry.dart';
import '../theme/app_theme.dart';

/// Chizma qanday darajada batafsil chiziladi.
enum SketchDetail {
  /// Ro'yxatdagi kichik ko'rinish — faqat shakl.
  thumbnail,

  /// To'liq chizma — o'lchamlar, umumiy uzunlik va yuza bilan.
  full,
}

class _EdgeLabel {
  _EdgeLabel(this.painter, this.anchor, this.normal);

  final TextPainter painter;

  /// Qirraning o'rtasi (chizma koordinatalarida).
  final Offset anchor;

  /// Tashqariga qaragan birlik vektor.
  final Offset normal;

  Rect rectFor(Offset pixelAnchor, double gap) {
    final size = painter.size;
    final center = pixelAnchor +
        Offset(
          normal.dx * (gap + size.width / 2),
          normal.dy * (gap + size.height / 2),
        );
    return Rect.fromCenter(
      center: center,
      width: size.width,
      height: size.height,
    );
  }
}

/// Xona chizmasini chizadi: shakl, devor uzunliklari, umumiy o'lcham va yuza.
class SketchPainter extends CustomPainter {
  SketchPainter({
    required this.geometry,
    this.detail = SketchDetail.full,
    this.showSpan = true,
    this.showArea = true,
    this.showAngles = false,
    this.fillColor = AppColors.shapeFill,
    this.strokeColor = AppColors.shapeStroke,
    this.textColor = AppColors.textPrimary,
    this.mutedColor = AppColors.textSecondary,
    this.textScale = 1,
  });

  final RoomGeometry geometry;
  final SketchDetail detail;
  final bool showSpan;
  final bool showArea;
  final bool showAngles;
  final Color fillColor;
  final Color strokeColor;
  final Color textColor;
  final Color mutedColor;
  final double textScale;

  bool get _isFull => detail == SketchDetail.full;

  static const double _labelGap = 7;
  static const double _spanGap = 16;

  @override
  void paint(Canvas canvas, Size size) {
    if (geometry.isEmpty || size.isEmpty) return;

    final labels = _isFull ? _buildEdgeLabels() : const <_EdgeLabel>[];
    final spanPainter = _isFull && showSpan ? _buildSpanLabel() : null;
    final areaPainter = _isFull && showArea ? _buildAreaLabel() : null;

    final layout = _fit(size, labels, spanPainter, areaPainter);
    if (layout == null) return;

    _paintShape(canvas, layout);
    if (!_isFull) return;

    if (spanPainter != null) _paintSpan(canvas, layout, spanPainter);
    _paintEdgeLabels(canvas, layout, labels);
    if (showAngles) _paintAngles(canvas, layout);
    if (areaPainter != null) _paintArea(canvas, layout, size, areaPainter);
  }

  // --- Joylashtirish -------------------------------------------------------

  _Layout? _fit(
    Size size,
    List<_EdgeLabel> labels,
    TextPainter? spanPainter,
    TextPainter? areaPainter,
  ) {
    final bounds = geometry.bounds;
    final width = math.max(bounds.width, 0.001);
    final height = math.max(bounds.height, 0.001);

    final topExtra = spanPainter == null
        ? 0.0
        : spanPainter.height + _spanGap + 10;
    final bottomExtra = areaPainter == null ? 0.0 : areaPainter.height + 14;
    const edgePad = 6.0;

    var available = Size(
      math.max(size.width - edgePad * 2, 1),
      math.max(size.height - edgePad * 2 - topExtra - bottomExtra, 1),
    );

    var scale = math.min(available.width / width, available.height / height);
    if (!scale.isFinite || scale <= 0) return null;

    // Yozuvlar piksel o'lchamda bo'lgani uchun masshtabni bir necha marta
    // aniqlashtiramiz — hech bir yozuv chetdan chiqib ketmasin.
    var origin = Offset.zero;
    for (var pass = 0; pass < 4; pass++) {
      origin = Offset(
        edgePad + (available.width - width * scale) / 2 - bounds.left * scale,
        edgePad +
            topExtra +
            (available.height - height * scale) / 2 -
            bounds.top * scale,
      );
      final layout = _Layout(scale: scale, origin: origin);

      var used = Rect.fromLTWH(
        origin.dx + bounds.left * scale,
        origin.dy + bounds.top * scale,
        width * scale,
        height * scale,
      );
      for (final label in labels) {
        used = used.expandToInclude(
          label.rectFor(layout.toPixel(label.anchor), _labelGap),
        );
      }
      if (spanPainter != null) {
        used = used.expandToInclude(
          Rect.fromLTWH(
            used.left,
            used.top - (spanPainter.height + _spanGap),
            math.max(used.width, spanPainter.width),
            spanPainter.height + _spanGap,
          ),
        );
      }

      final overflowX = used.width > size.width ? size.width / used.width : 1.0;
      final overflowY = used.height > size.height - bottomExtra
          ? (size.height - bottomExtra) / used.height
          : 1.0;
      final correction = math.min(overflowX, overflowY);
      if (correction > 0.995) {
        // Markazga tekislaymiz.
        final dx = (size.width - used.width) / 2 - (used.left - origin.dx);
        final dy = (size.height - bottomExtra - used.height) / 2 -
            (used.top - origin.dy);
        return _Layout(scale: scale, origin: Offset(dx, dy));
      }
      scale *= correction.clamp(0.2, 1.0);
    }
    return _Layout(scale: scale, origin: origin);
  }

  // --- Chizish -------------------------------------------------------------

  void _paintShape(Canvas canvas, _Layout layout) {
    final vertices = geometry.vertices;
    if (vertices.length < 2) return;

    final start = layout.toPixel(vertices.first);
    final path = Path()..moveTo(start.dx, start.dy);
    for (var i = 1; i < vertices.length; i++) {
      final p = layout.toPixel(vertices[i]);
      path.lineTo(p.dx, p.dy);
    }
    path.close();

    if (vertices.length >= 3) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.fill
          ..color = fillColor,
      );
    }

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _isFull ? 1.6 : 1.2
      ..strokeJoin = StrokeJoin.round
      ..color = strokeColor;

    if (geometry.impliedEdge == null) {
      canvas.drawPath(path, strokePaint);
    } else {
      // Avtomatik yopilgan devor uzuq chiziq bilan ajratiladi.
      final impliedPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokePaint.strokeWidth
        ..color = AppColors.accent;
      for (final edge in geometry.edges) {
        final a = layout.toPixel(edge.start);
        final b = layout.toPixel(edge.end);
        if (edge.implied) {
          _drawDashedLine(canvas, a, b, impliedPaint);
        } else {
          canvas.drawLine(a, b, strokePaint);
        }
      }
    }

    if (_isFull && vertices.length >= 3) {
      final dotPaint = Paint()..color = strokeColor;
      for (final vertex in vertices) {
        canvas.drawCircle(layout.toPixel(vertex), 2.2, dotPaint);
      }
    }
  }

  void _paintEdgeLabels(
    Canvas canvas,
    _Layout layout,
    List<_EdgeLabel> labels,
  ) {
    for (final label in labels) {
      final rect = label.rectFor(layout.toPixel(label.anchor), _labelGap);
      label.painter.paint(canvas, rect.topLeft);
    }
  }

  void _paintSpan(Canvas canvas, _Layout layout, TextPainter painter) {
    final bounds = geometry.bounds;
    final topLeft = layout.toPixel(Offset(bounds.left, bounds.top));
    final left = topLeft.dx;
    final right = layout.toPixel(Offset(bounds.right, bounds.top)).dx;
    final shapeTop = topLeft.dy;
    final y = shapeTop - _spanGap;

    final linePaint = Paint()
      ..color = mutedColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(left, y), Offset(right, y), linePaint);
    _drawArrowHead(canvas, Offset(left, y), -1, linePaint);
    _drawArrowHead(canvas, Offset(right, y), 1, linePaint);

    // Nozik yordamchi chiziqlar.
    final guidePaint = Paint()
      ..color = mutedColor.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(left, y + 3), Offset(left, shapeTop - 2), guidePaint);
    canvas.drawLine(
      Offset(right, y + 3),
      Offset(right, shapeTop - 2),
      guidePaint,
    );

    painter.paint(
      canvas,
      Offset((left + right) / 2 - painter.width / 2, y - painter.height - 4),
    );
  }

  void _paintAngles(Canvas canvas, _Layout layout) {
    final vertices = geometry.vertices;
    if (vertices.length < 3) return;
    for (var i = 0; i < vertices.length; i++) {
      final angle = geometry.interiorAngleAt(i);
      if (!angle.isFinite) continue;
      final painter = _textPainter(
        '${angle.round()}°',
        color: mutedColor,
        size: 10.5,
      );
      // Yozuvni burchakdan ichkariga suramiz.
      final prev = vertices[(i - 1 + vertices.length) % vertices.length];
      final next = vertices[(i + 1) % vertices.length];
      final current = vertices[i];
      final toPrev = _normalize(prev - current);
      final toNext = _normalize(next - current);
      final inward = _normalize(toPrev + toNext);
      final base = layout.toPixel(current);
      final center = base + inward * 18;
      painter.paint(
        canvas,
        center - Offset(painter.width / 2, painter.height / 2),
      );
    }
  }

  void _paintArea(
    Canvas canvas,
    _Layout layout,
    Size size,
    TextPainter painter,
  ) {
    final bounds = geometry.bounds;
    final bottom = layout.toPixel(Offset(bounds.left, bounds.bottom)).dy;
    final y = math.min(bottom + 16, size.height - painter.height);
    painter.paint(canvas, Offset((size.width - painter.width) / 2, y));
  }

  // --- Yozuvlar ------------------------------------------------------------

  List<_EdgeLabel> _buildEdgeLabels() {
    final result = <_EdgeLabel>[];
    for (final edge in geometry.edges) {
      if (!edge.showLength || edge.length <= 0) continue;
      final text = Fmt.meters(edge.length);
      final painter = _textPainter(
        text,
        color: edge.implied ? AppColors.accent : textColor,
        size: 12.5,
        weight: FontWeight.w500,
      );
      result.add(_EdgeLabel(painter, edge.mid, edge.outwardNormal));
    }
    return result;
  }

  TextPainter _buildSpanLabel() => _textPainter(
        Fmt.meters(geometry.bounds.width),
        color: textColor,
        size: 12.5,
        weight: FontWeight.w500,
      );

  TextPainter _buildAreaLabel() => _textPainter(
        'S ≈ ${Fmt.area(geometry.area)}',
        color: mutedColor,
        size: 12.5,
      );

  TextPainter _textPainter(
    String text, {
    required Color color,
    required double size,
    FontWeight weight = FontWeight.w400,
  }) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size * textScale,
          fontWeight: weight,
          height: 1.1,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
  }

  // --- Yordamchilar --------------------------------------------------------

  void _drawArrowHead(Canvas canvas, Offset tip, double direction, Paint paint) {
    const length = 6.0;
    const spread = 3.0;
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(tip.dx - direction * length, tip.dy - spread)
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(tip.dx - direction * length, tip.dy + spread);
    canvas.drawPath(path, paint);
  }

  void _drawDashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dash = 6.0;
    const gap = 4.0;
    final total = (b - a).distance;
    if (total <= 0) return;
    final unit = (b - a) / total;
    var travelled = 0.0;
    while (travelled < total) {
      final end = math.min(travelled + dash, total);
      canvas.drawLine(a + unit * travelled, a + unit * end, paint);
      travelled = end + gap;
    }
  }

  static Offset _normalize(Offset value) {
    final length = value.distance;
    if (length == 0) return Offset.zero;
    return value / length;
  }

  @override
  bool shouldRepaint(SketchPainter oldDelegate) {
    return !identical(oldDelegate.geometry, geometry) ||
        oldDelegate.detail != detail ||
        oldDelegate.showSpan != showSpan ||
        oldDelegate.showArea != showArea ||
        oldDelegate.showAngles != showAngles ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.textScale != textScale;
  }
}

class _Layout {
  const _Layout({required this.scale, required this.origin});

  final double scale;
  final Offset origin;

  Offset toPixel(Offset point) => Offset(
        origin.dx + point.dx * scale,
        origin.dy + point.dy * scale,
      );
}
