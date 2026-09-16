import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../core/app_info.dart';
import '../core/formatters.dart';
import '../data/sketch_store.dart';
import '../models/room_sketch.dart';
import '../theme/app_theme.dart';
import '../widgets/sketch_painter.dart';
import '../widgets/sketch_view.dart';
import '../widgets/ui_bits.dart';
import '../services/backup_service.dart';
import 'about_sheet.dart';
import 'backup_sheet.dart';
import 'detail_screen.dart';
import 'editor_screen.dart';

enum MenuAction { backup, csv, restore, about }

enum SortMode {
  recent('Avval yangilari'),
  oldest('Avval eskilari'),
  largest('Yuzasi katta'),
  name('Nomi bo‘yicha');

  const SortMode(this.title);

  final String title;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  SortMode _sort = SortMode.recent;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<RoomSketch> _visible(List<RoomSketch> all) {
    final query = _query.trim().toLowerCase();
    final filtered = query.isEmpty
        ? List<RoomSketch>.of(all)
        : all.where((sketch) {
            return sketch.displayName.toLowerCase().contains(query) ||
                sketch.description.toLowerCase().contains(query) ||
                (sketch.location?.address ?? '').toLowerCase().contains(query);
          }).toList();

    switch (_sort) {
      case SortMode.recent:
        filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      case SortMode.oldest:
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case SortMode.largest:
        filtered.sort((a, b) => b.area.compareTo(a.area));
      case SortMode.name:
        filtered.sort(
          (a, b) => a.displayName.toLowerCase().compareTo(
            b.displayName.toLowerCase(),
          ),
        );
    }
    return filtered;
  }

  Future<void> _onMenu(MenuAction action) async {
    switch (action) {
      case MenuAction.about:
        await AboutSheet.show(context);
      case MenuAction.restore:
        await BackupSheet.showRestore(context);
      case MenuAction.backup:
        await _export(BackupService.shareBackup);
      case MenuAction.csv:
        await _export(BackupService.shareCsv);
    }
  }

  /// Barcha chizmalarni fayl qilib ulashadi (JSON zaxira yoki CSV jadval).
  Future<void> _export(
    Future<String?> Function(List<RoomSketch> sketches) share,
  ) async {
    final store = SketchScope.read(context);
    if (store.count == 0) {
      context.showSnack('Hali saqlanadigan chizma yo‘q');
      return;
    }
    final error = await share(store.sketches);
    if (error != null && mounted) context.showSnack(error);
  }

  Future<void> _openEditor([RoomSketch? sketch]) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => EditorScreen(initial: sketch)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = SketchScope.of(context);
    final all = store.sketches;
    final items = _visible(all);
    final totalArea = all.fold<double>(0, (sum, item) => sum + item.area);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppInfo.name),
        actions: <Widget>[
          PopupMenuButton<SortMode>(
            tooltip: 'Saralash',
            icon: const Icon(Icons.sort, color: AppColors.textSecondary),
            color: AppColors.surfaceHigh,
            initialValue: _sort,
            onSelected: (value) => setState(() => _sort = value),
            itemBuilder: (context) => <PopupMenuEntry<SortMode>>[
              for (final mode in SortMode.values)
                PopupMenuItem<SortMode>(value: mode, child: Text(mode.title)),
            ],
          ),
          PopupMenuButton<MenuAction>(
            tooltip: 'Menyu',
            color: AppColors.surfaceHigh,
            position: PopupMenuPosition.under,
            icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
            onSelected: _onMenu,
            itemBuilder: (context) => const <PopupMenuEntry<MenuAction>>[
              PopupMenuItem<MenuAction>(
                value: MenuAction.backup,
                child: MenuRow(
                  icon: Icons.save_alt,
                  text: 'Zaxira nusxa saqlash',
                ),
              ),
              PopupMenuItem<MenuAction>(
                value: MenuAction.csv,
                child: MenuRow(
                  icon: Icons.table_chart_outlined,
                  text: 'Jadval (CSV) yuklab olish',
                ),
              ),
              PopupMenuItem<MenuAction>(
                value: MenuAction.restore,
                child: MenuRow(icon: Icons.restore, text: 'Zaxiradan tiklash'),
              ),
              PopupMenuItem<MenuAction>(
                value: MenuAction.about,
                child: MenuRow(icon: Icons.info_outline, text: 'Ilova haqida'),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openEditor,
        icon: const Icon(Icons.add),
        label: const Text('Yangi chizma'),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            if (all.isNotEmpty) _Header(count: all.length, area: totalArea),
            if (all.length > 3)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  textInputAction: TextInputAction.search,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Nom, tavsif yoki manzil bo‘yicha qidirish',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            color: AppColors.textSecondary,
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          ),
                  ),
                ),
              ),
            Expanded(
              child: all.isEmpty
                  ? EmptyState(
                      title: 'Hali chizma yo‘q',
                      message:
                          'Xonaning o‘lchamlarini kiriting — ilova chizmasini '
                          'chizib, yuzasini hisoblab beradi va abadiy saqlaydi.',
                      action: FilledButton.icon(
                        onPressed: _openEditor,
                        icon: const Icon(Icons.add),
                        label: const Text('Birinchi chizmani yaratish'),
                      ),
                    )
                  : items.isEmpty
                  ? const EmptyState(
                      icon: Icons.search_off,
                      title: 'Topilmadi',
                      message:
                          'Qidiruvga mos chizma yo‘q. Boshqa so‘z bilan '
                          'urinib ko‘ring.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                      itemCount: items.length,
                      scrollCacheExtent: const ScrollCacheExtent.pixels(600),
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final sketch = items[index];
                        return SketchCard(
                          key: ValueKey<String>(sketch.id),
                          sketch: sketch,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => DetailScreen(sketchId: sketch.id),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.count, required this.area});

  final int count;
  final double area;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: <Widget>[
          Expanded(
            child: StatTile(label: 'Chizmalar', value: '$count ta'),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: StatTile(
              label: 'Umumiy yuza',
              value: Fmt.area(area),
              accent: true,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ro'yxatdagi bitta chizma kartasi.
class SketchCard extends StatelessWidget {
  const SketchCard({super.key, required this.sketch, required this.onTap});

  final RoomSketch sketch;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.outline),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(8),
                child: SketchView(
                  geometry: sketch.geometry,
                  detail: SketchDetail.thumbnail,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      sketch.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: kSerif,
                        fontSize: 17,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: <Widget>[
                        MiniChip(
                          icon: Icons.crop_square,
                          text: Fmt.area(sketch.area),
                          accent: true,
                        ),
                        MiniChip(
                          icon: Icons.timeline,
                          text: Fmt.meters(sketch.perimeter),
                        ),
                        MiniChip(
                          icon: Icons.shape_line_outlined,
                          text: '${sketch.geometry.vertices.length} burchak',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        Icon(
                          sketch.hasLocation
                              ? Icons.place_outlined
                              : Icons.schedule,
                          size: 13,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            sketch.hasLocation
                                ? (sketch.location!.address ??
                                      sketch.location!.coordinatesText)
                                : Fmt.relative(sketch.updatedAt),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
