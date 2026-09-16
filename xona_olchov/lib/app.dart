import 'package:flutter/material.dart';

import 'core/app_info.dart';
import 'data/potolok_store.dart';
import 'data/sketch_store.dart';
import 'screens/root_shell.dart';
import 'theme/app_theme.dart';

class XonaOlchovApp extends StatelessWidget {
  const XonaOlchovApp({super.key, required this.store, required this.potolok});

  /// Chizmalar ombori.
  final SketchStore store;

  /// Potolok bo'limining ombori (arizalar va sozlamalar).
  final PotolokStore potolok;

  @override
  Widget build(BuildContext context) {
    return SketchScope(
      store: store,
      child: PotolokScope(
        store: potolok,
        child: MaterialApp(
          title: AppInfo.name,
          debugShowCheckedModeBanner: false,
          // Ilova faqat qorong'i mavzuda — tizim sozlamasiga bog'liq emas.
          theme: AppTheme.build(),
          scrollBehavior: const _SmoothScrollBehavior(),
          home: const RootShell(),
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
