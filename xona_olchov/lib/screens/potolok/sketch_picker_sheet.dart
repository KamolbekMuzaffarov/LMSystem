import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../data/sketch_store.dart';
import '../../models/room_sketch.dart';
import '../../theme/app_theme.dart';
import '../../widgets/sketch_painter.dart';
import '../../widgets/sketch_view.dart';
import '../../widgets/ui_bits.dart';

/// Saqlangan chizmalardan birini tanlash oynasi.
///
/// Shift yuzasi pol yuzasiga teng — shu sabab hisob uchun tayyor chizma
/// qo'lda kiritilgan songa qaraganda aniqroq.
class SketchPickerSheet extends StatelessWidget {
  const SketchPickerSheet({super.key, required this.sketches});

  final List<RoomSketch> sketches;

  static Future<RoomSketch?> show(BuildContext context) {
    final store = SketchScope.read(context);
    return showModalBottomSheet<RoomSketch>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => SketchPickerSheet(sketches: store.sketches),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      builder: (context, controller) {
        if (sketches.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(28),
            child: EmptyState(
              icon: Icons.straighten,
              title: 'Chizma yo‘q',
              message:
                  'Avval «Chizmalar» bo‘limida xonani o‘lchang — '
                  'yuzasi shu yerda o‘zi paydo bo‘ladi.',
            ),
          );
        }
        return ListView.separated(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          itemCount: sketches.length + 1,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            if (index == 0) {
              return const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text(
                  'Qaysi xona?',
                  style: TextStyle(
                    fontFamily: kSerif,
                    fontSize: 20,
                    color: AppColors.textPrimary,
                  ),
                ),
              );
            }
            final sketch = sketches[index - 1];
            return Material(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => Navigator.of(context).pop(sketch),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 54,
                        height: 54,
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: SketchView(
                          geometry: sketch.geometry,
                          detail: SketchDetail.thumbnail,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              sketch.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${Fmt.area(sketch.area)} · '
                              '${sketch.geometry.vertices.length} burchak',
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
