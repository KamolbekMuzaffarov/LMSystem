import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/opening.dart';
import '../models/room_sketch.dart';
import '../theme/app_theme.dart';
import '../widgets/sketch_painter.dart';
import 'formatters.dart';

/// Chizmani rasm (PNG) qilib beradi — ulashish va saqlash uchun.
///
/// Widget daraxtidan mustaqil ishlaydi: [ui.PictureRecorder] ustiga chiziladi,
/// shuning uchun ekranda ko'rinmayotgan chizmani ham rasmga aylantirish mumkin.
abstract final class SketchImage {
  static const double _margin = 56;

  static Future<Uint8List> render(
    RoomSketch sketch, {
    double width = 1240,
    double height = 1500,
    bool showAngles = false,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, height));
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width, height),
      Paint()..color = AppColors.background,
    );

    final maxTextWidth = width - _margin * 2;
    var y = _margin;

    y += _paintText(
      canvas,
      sketch.displayName,
      Offset(_margin, y),
      size: 46,
      color: AppColors.textPrimary,
      family: kSerif,
      maxWidth: maxTextWidth,
    );
    y += 10;
    y += _paintText(
      canvas,
      Fmt.dateTime(sketch.updatedAt),
      Offset(_margin, y),
      size: 24,
      color: AppColors.textSecondary,
      maxWidth: maxTextWidth,
    );

    if (sketch.hasLocation) {
      y += 6;
      final point = sketch.location!;
      y += _paintText(
        canvas,
        point.address ?? point.coordinatesText,
        Offset(_margin, y),
        size: 24,
        color: AppColors.textSecondary,
        maxWidth: maxTextWidth,
      );
    }

    // Pastdagi ko'rsatkichlar uchun joy qoldiramiz.
    final estimate = sketch.estimate;
    final rows = <(String, String)>[
      ('Yuza', Fmt.area(sketch.area)),
      ('Perimetr', Fmt.meters(sketch.perimeter)),
      ('Burchaklar', '${sketch.geometry.vertices.length} ta'),
      if (estimate.hasHeight) ('Balandlik', Fmt.meters(sketch.height!)),
      if (estimate.wallArea != null)
        (
          estimate.hasOpenings ? 'Devorlar yuzasi (sof)' : 'Devorlar yuzasi',
          Fmt.area(estimate.wallArea!),
        ),
      if (estimate.volume != null) ('Hajmi', Fmt.volume(estimate.volume!)),
      if (estimate.hasOpenings)
        (
          'Eshik / deraza',
          '${sketch.openings.pieces} ta · ${Fmt.area(estimate.openingArea)}',
        ),
      ('Plintus', Fmt.meters(estimate.skirtingLength)),
    ];
    const rowHeight = 46.0;
    final footerHeight = rows.length * rowHeight + 56;

    final drawTop = y + 32;
    final drawHeight = height - drawTop - footerHeight - _margin;

    if (drawHeight > 80) {
      canvas.save();
      canvas.translate(_margin, drawTop);
      SketchPainter(
        geometry: sketch.geometry,
        showAngles: showAngles,
        textScale: 2.1,
      ).paint(canvas, Size(maxTextWidth, drawHeight));
      canvas.restore();
    }

    var footerY = height - _margin - rows.length * rowHeight;
    canvas.drawLine(
      Offset(_margin, footerY - 26),
      Offset(width - _margin, footerY - 26),
      Paint()
        ..color = AppColors.outline
        ..strokeWidth = 1.5,
    );

    for (final row in rows) {
      _paintText(
        canvas,
        row.$1,
        Offset(_margin, footerY),
        size: 26,
        color: AppColors.textSecondary,
        maxWidth: maxTextWidth / 2,
      );
      _paintText(
        canvas,
        row.$2,
        Offset(_margin, footerY),
        size: 28,
        color: AppColors.textPrimary,
        maxWidth: maxTextWidth,
        align: TextAlign.right,
        alignWidth: maxTextWidth,
      );
      footerY += rowHeight;
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(width.round(), height.round());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    picture.dispose();
    if (data == null) {
      throw StateError("Rasmni tayyorlab bo'lmadi");
    }
    return data.buffer.asUint8List();
  }

  /// Matnni chizadi va egallagan balandligini qaytaradi.
  static double _paintText(
    Canvas canvas,
    String text,
    Offset offset, {
    required double size,
    required Color color,
    required double maxWidth,
    String? family,
    TextAlign align = TextAlign.left,
    double? alignWidth,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontFamily: family,
          height: 1.25,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: align,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: alignWidth ?? maxWidth);
    painter.paint(canvas, offset);
    return painter.height;
  }

  /// Fayl nomi: "Yotoqxona-2026-09-12.png"
  static String fileName(RoomSketch sketch) {
    final safe = sketch.displayName
        .replaceAll(RegExp(r'[^\w\s-]', unicode: true), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '-');
    final date = sketch.updatedAt;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final base = safe.isEmpty ? 'chizma' : safe;
    return '$base-${date.year}-$month-$day.png';
  }
}
