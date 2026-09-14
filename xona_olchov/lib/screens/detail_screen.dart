import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/formatters.dart';
import '../core/ids.dart';
import '../data/sketch_store.dart';
import '../models/opening.dart';
import '../models/room_sketch.dart';
import '../services/backup_service.dart';
import '../theme/app_theme.dart';
import '../widgets/material_card.dart';
import '../widgets/sketch_view.dart';
import '../widgets/ui_bits.dart';
import 'editor_screen.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key, required this.sketchId});

  final String sketchId;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

enum _DetailAction { share, duplicate }

class _DetailScreenState extends State<DetailScreen> {
  bool _showAngles = false;
  bool _busy = false;

  Future<void> _shareImage(RoomSketch sketch) async {
    setState(() => _busy = true);
    final error = await BackupService.shareSketchImage(sketch);
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) context.showSnack(error);
  }

  Future<void> _duplicate(RoomSketch sketch) async {
    final store = SketchScope.read(context);
    final copy = sketch.duplicate(
      id: Ids.generate(),
      name: '${sketch.displayName} (nusxa)',
    );
    final ok = await store.add(copy);
    if (!mounted) return;
    context.showSnack(ok ? 'Nusxa saqlandi' : "Nusxani saqlab bo'lmadi");
    if (ok) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => DetailScreen(sketchId: copy.id),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = SketchScope.of(context);
    final sketch = store.byId(widget.sketchId);

    if (sketch == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chizma')),
        body: const EmptyState(
          icon: Icons.help_outline,
          title: 'Chizma topilmadi',
          message: 'Bu chizma xotirada mavjud emas.',
        ),
      );
    }

    final geometry = sketch.geometry;

    return Scaffold(
      appBar: AppBar(
        title: Text(sketch.displayName),
        actions: <Widget>[
          IconButton(
            tooltip: 'Burchaklarni ko‘rsatish',
            onPressed: () => setState(() => _showAngles = !_showAngles),
            icon: Icon(
              _showAngles ? Icons.architecture : Icons.architecture_outlined,
              color:
                  _showAngles ? AppColors.shapeStroke : AppColors.textSecondary,
            ),
          ),
          IconButton(
            tooltip: 'Tahrirlash',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => EditorScreen(initial: sketch),
              ),
            ),
            icon: const Icon(Icons.edit_outlined),
          ),
          PopupMenuButton<_DetailAction>(
            tooltip: 'Boshqa amallar',
            color: AppColors.surfaceHigh,
            position: PopupMenuPosition.under,
            enabled: !_busy,
            icon: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.more_vert),
            onSelected: (action) => switch (action) {
              _DetailAction.share => _shareImage(sketch),
              _DetailAction.duplicate => _duplicate(sketch),
            },
            itemBuilder: (context) => const <PopupMenuEntry<_DetailAction>>[
              PopupMenuItem<_DetailAction>(
                value: _DetailAction.share,
                child: MenuRow(
                  icon: Icons.ios_share,
                  text: 'Rasm qilib ulashish',
                ),
              ),
              PopupMenuItem<_DetailAction>(
                value: _DetailAction.duplicate,
                child: MenuRow(
                  icon: Icons.copy_all_outlined,
                  text: 'Nusxa olish',
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: <Widget>[
          _SketchStage(sketch: sketch, showAngles: _showAngles),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: StatTile(
                  label: 'Yuza',
                  value: Fmt.area(sketch.area),
                  accent: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatTile(
                  label: 'Perimetr',
                  value: Fmt.meters(sketch.perimeter),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatTile(
                  label: 'Burchaklar',
                  value: '${geometry.vertices.length} ta',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SectionCard(
            title: 'Devorlar',
            icon: Icons.straighten,
            subtitle: 'Umumiy uzunlik: ${Fmt.meters(sketch.perimeter)}',
            child: Column(
              children: <Widget>[
                for (var i = 0; i < geometry.edges.length; i++)
                  _WallTile(
                    index: i,
                    length: geometry.edges[i].length,
                    angle: geometry.interiorAngleAt(i),
                    implied: geometry.edges[i].implied,
                    isLast: i == geometry.edges.length - 1,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          MaterialCard(estimate: sketch.estimate),
          if (sketch.openings.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            _OpeningsCard(openings: sketch.openings),
          ],
          if (sketch.description.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            SectionCard(
              title: 'Tavsif',
              icon: Icons.notes_outlined,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  sketch.description.trim(),
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ],
          if (sketch.hasLocation) ...<Widget>[
            const SizedBox(height: 12),
            _LocationCard(sketch: sketch),
          ],
          const SizedBox(height: 12),
          SectionCard(
            title: 'Ma‘lumot',
            icon: Icons.schedule,
            child: Column(
              children: <Widget>[
                _InfoRow(
                  label: 'Yaratilgan',
                  value: Fmt.dateTime(sketch.createdAt),
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  label: 'Oxirgi tahrir',
                  value: Fmt.dateTime(sketch.updatedAt),
                ),
                const SizedBox(height: 8),
                _InfoRow(label: 'Shakl turi', value: sketch.kind.title),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const NoteBanner(
            text: 'Bu chizma xotirada doimiy saqlanadi va o‘chirilmaydi. '
                'Kerak bo‘lsa faqat tahrirlash mumkin.',
            icon: Icons.lock_outline,
          ),
        ],
      ),
    );
  }
}

class _SketchStage extends StatelessWidget {
  const _SketchStage({required this.sketch, required this.showAngles});

  final RoomSketch sketch;
  final bool showAngles;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        PageRouteBuilder<void>(
          opaque: false,
          barrierColor: AppColors.background,
          pageBuilder: (_, _, _) => _FullscreenSketch(
            sketch: sketch,
            showAngles: showAngles,
          ),
          transitionsBuilder: (_, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      ),
      child: Container(
        height: 300,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.outline),
        ),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: SketchView(
                geometry: sketch.geometry,
                showAngles: showAngles,
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              child: Icon(
                Icons.fullscreen,
                size: 18,
                color: AppColors.textSecondary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullscreenSketch extends StatelessWidget {
  const _FullscreenSketch({required this.sketch, required this.showAngles});

  final RoomSketch sketch;
  final bool showAngles;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(sketch.displayName),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: InteractiveViewer(
        minScale: 0.8,
        maxScale: 5,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          child: SketchView(
            geometry: sketch.geometry,
            showAngles: showAngles,
            textScale: 1.1,
          ),
        ),
      ),
    );
  }
}

class _WallTile extends StatelessWidget {
  const _WallTile({
    required this.index,
    required this.length,
    required this.angle,
    required this.implied,
    required this.isLast,
  });

  final int index;
  final double length;
  final double angle;
  final bool implied;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        children: <Widget>[
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: implied ? AppColors.accent : AppColors.shapeFill,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: implied ? AppColors.background : AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              implied ? 'Avtomatik yopuvchi devor' : '${index + 1}-devor',
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (angle.isFinite)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                '${angle.round()}°',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          Text(
            Fmt.meters(length),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Eshik va derazalar ro'yxati.
class _OpeningsCard extends StatelessWidget {
  const _OpeningsCard({required this.openings});

  final List<Opening> openings;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Eshik va derazalar',
      icon: Icons.sensor_door_outlined,
      subtitle: '${openings.pieces} ta · ${Fmt.area(openings.totalArea)} '
          'devor yuzasidan ayrildi',
      child: Column(
        children: <Widget>[
          for (var i = 0; i < openings.length; i++)
            Padding(
              padding: EdgeInsets.only(
                bottom: i == openings.length - 1 ? 0 : 8,
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    switch (openings[i].kind) {
                      OpeningKind.door => Icons.sensor_door_outlined,
                      OpeningKind.window => Icons.window_outlined,
                      OpeningKind.other => Icons.crop_free,
                    },
                    size: 16,
                    color: AppColors.shapeStroke,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      openings[i].count > 1
                          ? '${openings[i].kind.title} × ${openings[i].count}'
                          : openings[i].kind.title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    openings[i].sizeText,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    Fmt.area(openings[i].area),
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({required this.sketch});

  final RoomSketch sketch;

  @override
  Widget build(BuildContext context) {
    final point = sketch.location!;
    return SectionCard(
      title: 'Lokatsiya',
      icon: Icons.place_outlined,
      subtitle: point.source.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (point.address != null) ...<Widget>[
            Text(
              point.address!,
              style: const TextStyle(
                fontSize: 14,
                height: 1.45,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  point.coordinatesText,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                  ),
                ),
              ),
              if (point.accuracy != null)
                Text(
                  '±${point.accuracy!.round()} m',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.icon(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    var opened = false;
                    try {
                      opened = await launchUrl(
                        point.mapsUri,
                        mode: LaunchMode.externalApplication,
                      );
                    } catch (_) {
                      opened = false;
                    }
                    if (!opened) {
                      messenger
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text('Xarita ilovasi topilmadi'),
                          ),
                        );
                    }
                  },
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text('Google Maps’da ochish'),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await Clipboard.setData(
                    ClipboardData(text: point.coordinatesText),
                  );
                  messenger
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(content: Text('Koordinatalar nusxalandi')),
                    );
                },
                child: const Icon(Icons.copy_rounded, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}
