import 'package:flutter/material.dart';

import '../core/geometry.dart';
import '../theme/app_theme.dart';
import 'sketch_painter.dart';

/// Xona chizmasini ko'rsatuvchi widget.
///
/// [RepaintBoundary] bilan o'ralgan — ro'yxat siljiganda qayta chizilmaydi.
class SketchView extends StatelessWidget {
  const SketchView({
    super.key,
    required this.geometry,
    this.detail = SketchDetail.full,
    this.showSpan = true,
    this.showArea = true,
    this.showAngles = false,
    this.padding = EdgeInsets.zero,
    this.textScale = 1,
  });

  final RoomGeometry geometry;
  final SketchDetail detail;
  final bool showSpan;
  final bool showArea;
  final bool showAngles;
  final EdgeInsets padding;
  final double textScale;

  @override
  Widget build(BuildContext context) {
    if (geometry.isEmpty) {
      return const _EmptySketch();
    }
    return RepaintBoundary(
      child: Padding(
        padding: padding,
        child: CustomPaint(
          painter: SketchPainter(
            geometry: geometry,
            detail: detail,
            showSpan: showSpan,
            showArea: showArea,
            showAngles: showAngles,
            textScale: textScale,
          ),
          size: Size.infinite,
          isComplex: detail == SketchDetail.full,
          willChange: false,
        ),
      ),
    );
  }
}

class _EmptySketch extends StatelessWidget {
  const _EmptySketch();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.architecture_outlined,
              color: AppColors.textSecondary, size: 28),
          SizedBox(height: 8),
          Text(
            "O‘lchamlarni kiriting",
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
