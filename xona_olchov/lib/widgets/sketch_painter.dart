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

  /// Devordan qanchalik uzoqda turishi — kesishuv bo'lsa kattalashtiriladi.
  double gap = SketchPainter.labelGap;

  Rect rectFor(Offset pixelAnchor) {
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

  /// Devor yozuvi bilan devor orasidagi masofa.
  static const double labelGap = 7;

  /// Kesishuvni hal qilishda yozuvni ko'pi bilan shuncha suramiz.
  static const double _maxLabelGap = 64;

  /// Umumiy o'lcham strelkasi bilan chizma orasidagi masofa.
  static const double _spanGap = 12;

  /// Yuza yozuvi bilan chizma orasidagi masofa.
  static const double _areaGap = 12;

  @override
  void paint(Canvas canvas, Size size) {
    if (geometry.isEmpty || size.isEmpty) return;

    // Maydon juda tor bo'lsa yozuvlarni kichraytirib qayta joylashtiramiz.
    var factor = 1.0;
    var labels = const <_EdgeLabel>[];
    TextPainter? spanPainter;
    TextPainter? areaPainter;
    _Layout? layout;
    for (var attempt = 0; attempt < 4; attempt++) {
      labels = _isFull ? _buildEdgeLabels(factor) : const <_EdgeLabel>[];
      spanPainter = _isFull && showSpan ? _buildSpanLabel(factor) : null;
      areaPainter = _isFull && showArea ? _buildAreaLabel(factor) : null;
      layout = _fit(size, labels, spanPainter, areaPainter);
      if (layout == null) return;
      if (layout.fits) break;
      factor *= 0.8;
    }
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

    // Strelka va yuza yozuvi uchun ajratilgan doimiy (piksel) bo'shliqlar.
    final spanBand =
        spanPainter == null ? 0.0 : spanPainter.height + _spanGap + 4;
    final areaBand = areaPainter == null ? 0.0 : areaPainter.height + _areaGap;
    const edgePad = 6.0;

    final availableWidth = math.max(size.width - edgePad * 2, 1.0);
    final availableHeight = math.max(
      size.height - edgePad * 2 - spanBand - areaBand,
      1.0,
    );

    var scale = math.min(availableWidth / width, availableHeight / height);
    if (!scale.isFinite || scale <= 0) return null;

    // Bir piksel zaxira — chetga tegib turgan yozuv qolmasin.
    final targetWidth = math.max(size.width - 1, 1.0);
    final targetHeight = math.max(size.height - 1, 1.0);

    Rect measure(double value) {
      final probe = _Layout(
        scale: value,
        origin: Offset(-bounds.left * value, -bounds.top * value),
      );
      return _resolveLabels(
        probe,
        labels,
        Rect.fromLTWH(0, 0, width * value, height * value),
      );
    }

    double fitOf(Rect measured) {
      final totalWidth = math.max(
        measured.width,
        math.max(spanPainter?.width ?? 0, areaPainter?.width ?? 0),
      );
      final totalHeight = measured.height + spanBand + areaBand;
      final fitX =
          totalWidth <= targetWidth ? 1.0 : targetWidth / totalWidth;
      final fitY =
          totalHeight <= targetHeight ? 1.0 : targetHeight / totalHeight;
      return math.min(fitX, fitY);
    }

    // Yozuvlar piksel o'lchamda, shakl esa masshtabga bog'liq. Shu sababli
    // kerakli masshtabni to'g'ridan-to'g'ri yechamiz: joy = shakl×masshtab +
    // yozuvlar (o'zgarmas qism).
    for (var pass = 0; pass < 6; pass++) {
      final measured = measure(scale);
      if (fitOf(measured) >= 1.0) break;
      final constantWidth = measured.width - width * scale;
      final constantHeight =
          measured.height - height * scale + spanBand + areaBand;
      final byWidth = (targetWidth - constantWidth) / width;
      final byHeight = (targetHeight - constantHeight) / height;
      final solved = math.min(byWidth, byHeight);
      if (!solved.isFinite) break;
      final next = solved.clamp(scale * 0.2, scale);
      if (next <= 0 || (scale - next).abs() < 0.001) break;
      scale = next;
    }

    // Yakuniy o'lchash: yozuv masofalari ham shu masshtabga mos bo'lishi kerak.
    final content = measure(scale);
    final fits = fitOf(content) >= 1.0;

    // Butun kompozitsiyani markazga tekislaymiz: strelka + shakl + yozuvlar + yuza.
    final total = Rect.fromLTRB(
      content.left,
      content.top - spanBand,
      content.right,
      content.bottom + areaBand,
    );
    final shift = Offset(
      (size.width - total.width) / 2 - total.left,
      (size.height - total.height) / 2 - total.top,
    );

    return _Layout(
      scale: scale,
      origin: Offset(
        -bounds.left * scale + shift.dx,
        -bounds.top * scale + shift.dy,
      ),
      contentTop: content.top + shift.dy,
      contentBottom: content.bottom + shift.dy,
      fits: fits,
    );
  }

  /// Devor yozuvlarini joylashtiradi: ustma-ust tushganlarini tashqariga suradi.
  ///
  /// Botiq (ichkariga kirgan) burchaklarda qo'shni devorlarning yozuvlari bir
  /// nuqtaga yaqin tushadi — shuning uchun ularni bir-biridan ajratamiz.
  Rect _resolveLabels(
    _Layout layout,
    List<_EdgeLabel> labels,
    Rect shapeRect,
  ) {
    for (final label in labels) {
      label.gap = labelGap;
    }

    for (var pass = 0; pass < 5; pass++) {
      var moved = false;
      for (var i = 1; i < labels.length; i++) {
        for (var j = 0; j < i; j++) {
          final a = labels[i].rectFor(layout.toPixel(labels[i].anchor));
          final b = labels[j].rectFor(layout.toPixel(labels[j].anchor));
          if (!a.overlaps(b)) continue;
          final overlapX = math.min(a.right, b.right) - math.max(a.left, b.left);
          final overlapY = math.min(a.bottom, b.bottom) - math.max(a.top, b.top);
          final push = math.min(overlapX, overlapY) + 3;
          final next = math.min(labels[i].gap + push, _maxLabelGap);
          if (next <= labels[i].gap) continue;
          labels[i].gap = next;
          moved = true;
        }
      }
      if (!moved) break;
    }

    var used = shapeRect;
    for (final label in labels) {
      used = used.expandToInclude(label.rectFor(layout.toPixel(label.anchor)));
    }
    return used;
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
      final rect = label.rectFor(layout.toPixel(label.anchor));
      label.painter.paint(canvas, rect.topLeft);
    }
  }

  void _paintSpan(Canvas canvas, _Layout layout, TextPainter painter) {
    final bounds = geometry.bounds;
    final topLeft = layout.toPixel(Offset(bounds.left, bounds.top));
    final left = topLeft.dx;
    final right = layout.toPixel(Offset(bounds.right, bounds.top)).dx;

    // Strelka shakldan ham, devor yozuvlaridan ham yuqorida turadi.
    final y = math.min(topLeft.dy, layout.contentTop) - _spanGap;

    final linePaint = Paint()
      ..color = mutedColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(left, y), Offset(right, y), linePaint);
    _drawArrowHead(canvas, Offset(left, y), -1, linePaint);
    _drawArrowHead(canvas, Offset(right, y), 1, linePaint);

    // Uchlaridagi qisqa belgilar (chizma uslubida).
    final tickPaint = Paint()
      ..color = mutedColor.withValues(alpha: 0.55)
      ..strokeWidth = 1;
    for (final x in <double>[left, right]) {
      canvas.drawLine(Offset(x, y - 4), Offset(x, y + 4), tickPaint);
    }

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
      var inward = _normalize(toPrev + toNext);
      // Botiq (reflex) burchakda yo'nalishlar yig'indisi xonadan tashqariga
      // qaraydi — yozuvni teskari tomonga suramiz.
      if (angle > 180) inward = -inward;
      final base = layout.toPixel(current);
      final center = base + inward * (angle > 180 ? 22 : 18);
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
    final shapeBottom = layout.toPixel(Offset(bounds.left, bounds.bottom)).dy;
    // Pastdagi devor yozuvi bilan qo'shilib ketmasligi uchun uning ostiga.
    final base = math.max(shapeBottom, layout.contentBottom);
    final y = math.min(base + _areaGap, size.height - painter.height);
    painter.paint(canvas, Offset((size.width - painter.width) / 2, y));
  }

  // --- Yozuvlar ------------------------------------------------------------

  List<_EdgeLabel> _buildEdgeLabels(double factor) {
    final bounds = geometry.bounds;
    final result = <_EdgeLabel>[];
    for (final edge in geometry.edges) {
      if (!edge.showLength || edge.length <= 0) continue;
      // Umumiy o'lcham strelkasi shu devor uzunligini allaqachon ko'rsatgan
      // bo'lsa, uni ikkinchi marta yozmaymiz.
      if (_duplicatesSpan(edge, bounds)) continue;
      final text = Fmt.meters(edge.length);
      final painter = _textPainter(
        text,
        color: edge.implied ? AppColors.accent : textColor,
        size: 12.5 * factor,
        weight: FontWeight.w500,
      );
      result.add(_EdgeLabel(painter, edge.mid, edge.outwardNormal));
    }
    return result;
  }

  /// Devor yozuvi umumiy o'lcham strelkasi bilan bir xilmi.
  bool _duplicatesSpan(RoomEdge edge, Rect bounds) {
    if (!showSpan) return false;
    // Faqat shaklning yuqori chegarasida yotgan, tashqariga (yuqoriga) qaragan
    // va uzunligi umumiy o'lchamga teng devor.
    if (edge.outwardNormal.dy > -0.98) return false;
    if ((edge.length - bounds.width).abs() > 0.01) return false;
    if ((edge.start.dy - bounds.top).abs() > 0.001) return false;
    if ((edge.end.dy - bounds.top).abs() > 0.001) return false;
    return true;
  }

  TextPainter _buildSpanLabel(double factor) => _textPainter(
        Fmt.meters(geometry.bounds.width),
        color: textColor,
        size: 12.5 * factor,
        weight: FontWeight.w500,
      );

  TextPainter _buildAreaLabel(double factor) => _textPainter(
        'S ≈ ${Fmt.area(geometry.area)}',
        color: mutedColor,
        size: 12.5 * factor,
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
  const _Layout({
    required this.scale,
    required this.origin,
    this.contentTop = 0,
    this.contentBottom = 0,
    this.fits = true,
  });

  final double scale;
  final Offset origin;

  /// Shakl va devor yozuvlarining eng yuqori cheti (piksel).
  final double contentTop;

  /// Shakl va devor yozuvlarining eng pastki cheti (piksel).
  final double contentBottom;

  /// Butun kompozitsiya maydonga sig'dimi.
  final bool fits;

  Offset toPixel(Offset point) => Offset(
        origin.dx + point.dx * scale,
        origin.dy + point.dy * scale,
      );
}
