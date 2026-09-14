import 'package:flutter/material.dart';

import '../core/app_info.dart';
import '../theme/app_theme.dart';

/// Ilova haqida qisqa ma'lumot.
abstract final class AboutSheet {
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      builder: (context) => const _AboutBody(),
    );
  }
}

class _AboutBody extends StatelessWidget {
  const _AboutBody();

  static const List<(IconData, String, String)> _points =
      <(IconData, String, String)>[
    (
      Icons.straighten,
      "O‘lchamdan chizma",
      "To‘rtburchak, trapetsiya yoki istalgancha burchagi bor xonani "
          "devor-devor kiriting — ilova chizmani chizib, yuza va perimetrni "
          'hisoblaydi.',
    ),
    (
      Icons.lock_outline,
      "O‘chirilmaydigan xotira",
      'Saqlangan chizma qurilma xotirasida qoladi. Ilovada o‘chirish '
          'tugmasi yo‘q — faqat tahrirlash mumkin.',
    ),
    (
      Icons.place_outlined,
      'Lokatsiya',
      'Internet yoqilgan bo‘lsa GPS ruxsati so‘raladi. Xohlasangiz '
          'koordinatani Google Maps havolasidan yoki qo‘lda kiritasiz.',
    ),
    (
      Icons.functions,
      'Hisob-kitob',
      'Yuza Gauss (shoelace) formulasi bilan hisoblanadi — shakl qanchalik '
          'murakkab bo‘lsa ham natija to‘g‘ri chiqadi.',
    ),
    (
      Icons.calculate_outlined,
      'Material hisobi',
      'Balandlikni kiritsangiz devorlar yuzasi va hajmi chiqadi. Eshik va '
          'derazalar devor yuzasidan ayriladi, plintus eshiksiz hisoblanadi. '
          'Zaxira foizi, quti soni va 1 m² narxi bo‘yicha umumiy summa ham bor.',
    ),
    (
      Icons.ios_share,
      'Ulashish va zaxira',
      'Chizmani rasm qilib yuborish, barcha chizmalarni zaxira faylga yoki '
          'Excel ochadigan CSV jadvalga chiqarish va zaxiradan tiklash mumkin.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                AppInfo.name,
                style: TextStyle(
                  fontFamily: kSerif,
                  fontSize: 24,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                AppInfo.tagline,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 22),
              for (final point in _points)
                Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppColors.shapeFill,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          point.$1,
                          size: 17,
                          color: AppColors.shapeStroke,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              point.$2,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              point.$3,
                              style: const TextStyle(
                                fontSize: 12.5,
                                height: 1.45,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
