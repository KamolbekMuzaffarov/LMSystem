import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/app_info.dart';
import 'data/sketch_store.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(AppTheme.overlayStyle);
  runApp(const Bootstrap());
}

/// Ombor yuklanguncha ko'rsatiladigan boshlang'ich ekran.
class Bootstrap extends StatefulWidget {
  const Bootstrap({super.key});

  @override
  State<Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<Bootstrap> {
  late Future<SketchStore> _future = SketchStore.open();

  /// Xotira ochilmasa foydalanuvchi qayta urinib ko'radi.
  void _retry() => setState(() => _future = SketchStore.open());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SketchStore>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _SplashApp();
        }
        final store = snapshot.data;
        if (store == null) {
          return _SplashApp(
            error: '${snapshot.error ?? "Noma‘lum xato"}',
            onRetry: _retry,
          );
        }
        return XonaOlchovApp(store: store);
      },
    );
  }
}

class _SplashApp extends StatelessWidget {
  const _SplashApp({this.error, this.onRetry});

  final String? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      home: Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  color: AppColors.shapeFill,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.shapeStroke, width: 1.4),
                ),
                child: const Icon(
                  Icons.square_foot,
                  color: AppColors.shapeStroke,
                  size: 40,
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
              const SizedBox(height: 18),
              if (error == null)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.shapeStroke,
                  ),
                )
              else ...<Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    "Xotirani ochib bo‘lmadi: $error",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Qayta urinish'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
