import 'package:flutter/material.dart';

import 'core/app_info.dart';
import 'data/sketch_store.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

class XonaOlchovApp extends StatelessWidget {
  const XonaOlchovApp({super.key, required this.store});

  final SketchStore store;

  @override
  Widget build(BuildContext context) {
    return SketchScope(
      store: store,
      child: MaterialApp(
        title: AppInfo.name,
        debugShowCheckedModeBanner: false,
        // Ilova faqat qorong'i mavzuda — tizim sozlamasiga bog'liq emas.
        theme: AppTheme.build(),
        scrollBehavior: const _SmoothScrollBehavior(),
        home: const HomeScreen(),
        builder: (context, child) {
          // Tizim shrift o'lchami juda katta bo'lsa ham chizma buzilmasin.
          final media = MediaQuery.of(context);
          return MediaQuery(
            data: media.copyWith(
              textScaler: media.textScaler.clamp(
                minScaleFactor: 0.9,
                maxScaleFactor: 1.25,
              ),
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}

class _SmoothScrollBehavior extends MaterialScrollBehavior {
  const _SmoothScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return StretchingOverscrollIndicator(
      axisDirection: details.direction,
      child: child,
    );
  }
}
