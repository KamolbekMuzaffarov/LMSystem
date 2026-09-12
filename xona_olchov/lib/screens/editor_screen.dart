import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/estimate.dart';
import '../core/formatters.dart';
import '../core/geometry.dart';
import '../core/ids.dart';
import '../data/sketch_store.dart';
import '../models/geo_point.dart';
import '../models/room_sketch.dart';
import '../models/wall.dart';
import '../theme/app_theme.dart';
import '../widgets/location_picker.dart';
import '../widgets/sketch_view.dart';
import '../widgets/ui_bits.dart';

/// Bitta devor qatorining tahrirlash holati.
class _WallDraft {
  _WallDraft({String text = '', this.turn = 90})
      : controller = TextEditingController(text: text);

  final TextEditingController controller;
  double turn;

  double get length => Fmt.parseNumber(controller.text) ?? 0;

  void dispose() => controller.dispose();
}

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key, this.initial});

  /// Tahrirlanayotgan chizma. `null` bo'lsa — yangi chizma.
  final RoomSketch? initial;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late RoomKind _kind;
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  // To'rtburchak
  late final TextEditingController _lengthController;
  late final TextEditingController _widthController;

  // Trapetsiya
  late final TextEditingController _spanController;
  late final TextEditingController _sideAController;
  late final TextEditingController _sideBController;

  // Balandlik va material
  late final TextEditingController _heightController;
  double _reservePercent = 0;

  // Ko'p burchakli
  final List<_WallDraft> _walls = <_WallDraft>[];

  /// Har bir maydonning oxirgi ko'rilgan matni. Faqat matn chindan o'zgarganda
  /// "saqlanmagan o'zgarish" belgisi qo'yiladi — fokus yoki kursor harakati
  /// hisobga olinmaydi.
  final Map<TextEditingController, String> _seenText =
      <TextEditingController, String>{};

  GeoPoint? _location;
  double _rotation = 0;
  bool _showAngles = false;
  bool _saving = false;
  bool _dirty = false;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _kind = initial?.kind ?? RoomKind.trapezoid;
    _location = initial?.location;
    _nameController = TextEditingController(text: initial?.name ?? '');
    _descriptionController =
        TextEditingController(text: initial?.description ?? '');

    final inputs = initial?.presetInputs ?? const <String, double>{};
    _lengthController = _numberController(inputs['length']);
    _widthController = _numberController(inputs['width']);
    _spanController = _numberController(inputs['span']);
    _sideAController = _numberController(inputs['sideA']);
    _sideBController = _numberController(inputs['sideB']);
    _heightController = _numberController(initial?.height);
    _reservePercent = initial?.reservePercent ?? 0;

    if (initial != null && initial.kind == RoomKind.polygon) {
      for (final wall in initial.walls) {
        _walls.add(
          _WallDraft(text: Fmt.number(wall.length), turn: wall.turn),
        );
      }
    }
    if (_walls.isEmpty) _applyTemplate(_Template.rectangle, notify: false);

    // Burilish saqlangan holatdan tiklanadi (tayyor shakllar uchun ham).
    _rotation = inputs['rotation'] ??
        (initial != null && initial.kind == RoomKind.polygon
            ? initial.startHeading
            : 0);

    for (final controller in <TextEditingController>[
      _nameController,
      _descriptionController,
      _lengthController,
      _widthController,
      _spanController,
      _sideAController,
      _sideBController,
      _heightController,
    ]) {
      _watch(controller);
    }
    for (final wall in _walls) {
      _watch(wall.controller);
    }
  }

  /// Maydonni kuzatishga qo'yadi.
  void _watch(TextEditingController controller) {
    _seenText[controller] = controller.text;
    controller.addListener(() => _onControllerChanged(controller));
  }

  void _unwatch(TextEditingController controller) {
    _seenText.remove(controller);
  }

  TextEditingController _numberController(double? value) {
    return TextEditingController(
      text: value == null ? '' : Fmt.number(value),
    );
  }

  void _onControllerChanged(TextEditingController controller) {
    if (!mounted) return;
    // Kursor yoki fokus o'zgarishi ham xabar beradi — faqat matnni tekshiramiz.
    if (_seenText[controller] == controller.text) return;
    _seenText[controller] = controller.text;
    setState(() => _dirty = true);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _spanController.dispose();
    _sideAController.dispose();
    _sideBController.dispose();
    _heightController.dispose();
    for (final wall in _walls) {
      wall.dispose();
    }
    _seenText.clear();
    super.dispose();
  }

  // --- Geometriya ----------------------------------------------------------

  ({List<Wall> walls, double startHeading}) _buildWalls() {
    switch (_kind) {
      case RoomKind.rectangle:
        final length = Fmt.parseNumber(_lengthController.text) ?? 0;
        final width = Fmt.parseNumber(_widthController.text) ?? 0;
        if (length <= 0 || width <= 0) {
          return (walls: const <Wall>[], startHeading: 0.0);
        }
        final built = ShapePresets.rectangle(length: length, width: width);
        return (walls: built.walls, startHeading: built.startHeading + _rotation);

      case RoomKind.trapezoid:
        final span = Fmt.parseNumber(_spanController.text) ?? 0;
        final sideA = Fmt.parseNumber(_sideAController.text) ?? 0;
        final sideB = Fmt.parseNumber(_sideBController.text) ?? 0;
        if (span <= 0 || sideA <= 0 || sideB <= 0) {
          return (walls: const <Wall>[], startHeading: 0.0);
        }
        final built = ShapePresets.trapezoid(
          span: span,
          sideA: sideA,
          sideB: sideB,
        );
        return (walls: built.walls, startHeading: built.startHeading + _rotation);

      case RoomKind.polygon:
        final walls = <Wall>[];
        for (final draft in _walls) {
          if (draft.length > 0) {
            walls.add(Wall(length: draft.length, turn: draft.turn));
          }
        }
        return (walls: walls, startHeading: _rotation);
    }
  }

  /// Kiritilgan balandlik (bo'sh yoki noto'g'ri bo'lsa `null`).
  double? _height() {
    final value = Fmt.parseNumber(_heightController.text);
    if (value == null || value <= 0 || value > 30) return null;
    return value;
  }

  Map<String, double> _presetInputs() {
    switch (_kind) {
      case RoomKind.rectangle:
        return <String, double>{
          'length': Fmt.parseNumber(_lengthController.text) ?? 0,
          'width': Fmt.parseNumber(_widthController.text) ?? 0,
          'rotation': _rotation,
        };
      case RoomKind.trapezoid:
        return <String, double>{
          'span': Fmt.parseNumber(_spanController.text) ?? 0,
          'sideA': Fmt.parseNumber(_sideAController.text) ?? 0,
          'sideB': Fmt.parseNumber(_sideBController.text) ?? 0,
          'rotation': _rotation,
        };
      case RoomKind.polygon:
        return <String, double>{'rotation': _rotation};
    }
  }

  // --- Devorlar ------------------------------------------------------------

  void _addWall() {
    final draft = _WallDraft(turn: 90);
    _watch(draft.controller);
    setState(() {
      _walls.add(draft);
      _dirty = true;
    });
  }

  void _removeWall(int index) {
    if (_walls.length <= 3) {
      _snack('Kamida 3 ta devor bo‘lishi kerak');
      return;
    }
    final draft = _walls.removeAt(index);
    _unwatch(draft.controller);
    draft.dispose();
    setState(() => _dirty = true);
  }

  void _applyTemplate(_Template template, {bool notify = true}) {
    for (final wall in _walls) {
      _unwatch(wall.controller);
      wall.dispose();
    }
    _walls
      ..clear()
      ..addAll(
        template.walls.map(
          (item) => _WallDraft(
            text: item.$1 == 0 ? '' : Fmt.number(item.$1),
            turn: item.$2,
          ),
        ),
      );
    for (final wall in _walls) {
      _watch(wall.controller);
    }
    if (notify) setState(() => _dirty = true);
  }

  // --- Saqlash -------------------------------------------------------------

  Future<void> _save() async {
    final built = _buildWalls();
    final geometry = RoomGeometry.fromWalls(
      built.walls,
      startHeading: built.startHeading,
    );

    if (built.walls.isEmpty || geometry.vertices.length < 3) {
      _snack('Kamida 3 ta devor o‘lchamini kiriting');
      return;
    }
    if (!geometry.hasArea) {
      _snack(
        geometry.selfIntersecting
            ? 'Devorlar kesishmoqda — burilishlarni tekshiring'
            : 'Yuzani hisoblab bo‘lmadi, o‘lchamlarni tekshiring',
      );
      return;
    }

    setState(() => _saving = true);
    final store = SketchScope.read(context);
    final now = DateTime.now();
    final name = _nameController.text.trim().isEmpty
        ? 'Xona ${store.count + 1}'
        : _nameController.text.trim();

    final bool ok;
    if (_isEditing) {
      ok = await store.update(
        widget.initial!.copyWith(
          name: name,
          description: _descriptionController.text.trim(),
          kind: _kind,
          walls: built.walls,
          startHeading: built.startHeading,
          presetInputs: _presetInputs(),
          location: _location,
          clearLocation: _location == null,
          height: _height(),
          clearHeight: _height() == null,
          reservePercent: _reservePercent,
          updatedAt: now,
        ),
      );
    } else {
      ok = await store.add(
        RoomSketch(
          id: Ids.generate(),
          name: name,
          description: _descriptionController.text.trim(),
          kind: _kind,
          walls: built.walls,
          startHeading: built.startHeading,
          presetInputs: _presetInputs(),
          location: _location,
          height: _height(),
          reservePercent: _reservePercent,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    if (!mounted) return;
    setState(() => _saving = false);
    if (!ok) {
      _snack('Saqlashda xato: ${store.lastError ?? "noma‘lum"}');
      return;
    }
    Navigator.of(context).pop();
    _snack(_isEditing ? 'Chizma yangilandi' : 'Chizma saqlandi');
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _confirmExit() async {
    if (!_dirty || _saving) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Saqlanmagan o‘zgarishlar'),
        content: const Text(
          'Chizma hali saqlanmadi. Chiqib ketilsinmi?',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Qolish'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.accent),
            child: const Text('Chiqish'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // --- UI ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final built = _buildWalls();
    final geometry = RoomGeometry.fromWalls(
      built.walls,
      startHeading: built.startHeading,
    );
    final implied = geometry.impliedEdge;

    return PopScope<Object?>(
      key: const Key('editor-pop-scope'),
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (await _confirmExit() && mounted) {
          navigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Chizmani tahrirlash' : 'Yangi chizma'),
          actions: <Widget>[
            IconButton(
              tooltip: 'Burchaklarni ko‘rsatish',
              onPressed: () => setState(() => _showAngles = !_showAngles),
              icon: Icon(
                _showAngles ? Icons.architecture : Icons.architecture_outlined,
                color: _showAngles
                    ? AppColors.shapeStroke
                    : AppColors.textSecondary,
              ),
            ),
            IconButton(
              tooltip: 'Chizmani burish',
              onPressed: () => setState(() {
                _rotation = (_rotation + 90) % 360;
                _dirty = true;
              }),
              icon: const Icon(
                Icons.rotate_90_degrees_cw_outlined,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: <Widget>[
            _PreviewCard(geometry: geometry, showAngles: _showAngles),
            const SizedBox(height: 12),
            if (geometry.selfIntersecting)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: NoteBanner(
                  text: 'Devorlar bir-birini kesib o‘tmoqda. Burilish '
                      'yo‘nalishlarini tekshiring — yuza noto‘g‘ri chiqadi.',
                  tone: NoteTone.danger,
                  icon: Icons.warning_amber_rounded,
                ),
              ),
            if (implied != null && !geometry.selfIntersecting)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: NoteBanner(
                  text: 'Xona yopilishi uchun oxirgi devor avtomatik '
                      'qo‘shildi: ${Fmt.meters(implied.length)} '
                      '(chizmada uzuq chiziq).',
                  tone: NoteTone.warning,
                  icon: Icons.auto_fix_high_outlined,
                ),
              ),
            SectionCard(
              title: 'Xona shakli',
              icon: Icons.category_outlined,
              subtitle: _kind.subtitle,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  SegmentedButton<RoomKind>(
                    segments: <ButtonSegment<RoomKind>>[
                      for (final kind in RoomKind.values)
                        ButtonSegment<RoomKind>(
                          value: kind,
                          label: Text(kind.title),
                        ),
                    ],
                    selected: <RoomKind>{_kind},
                    showSelectedIcon: false,
                    onSelectionChanged: (selection) => setState(() {
                      _kind = selection.first;
                      _dirty = true;
                    }),
                  ),
                  const SizedBox(height: 16),
                  _buildInputs(),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: 'Chizma ma‘lumotlari',
              icon: Icons.description_outlined,
              child: Column(
                children: <Widget>[
                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Nomi',
                      hintText: 'Masalan: Yotoqxona, 2-qavat zali',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 4,
                    minLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Tavsif',
                      hintText: 'Potolok balandligi, material, izohlar…',
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: 'Balandlik va material',
              icon: Icons.height,
              subtitle: 'Devorlar yuzasi, hajm va zaxira hisobi uchun',
              child: _HeightSection(
                controller: _heightController,
                reservePercent: _reservePercent,
                estimate: RoomEstimate(
                  floorArea: geometry.area,
                  perimeter: geometry.perimeter,
                  height: _height(),
                  reservePercent: _reservePercent,
                ),
                onReserveChanged: (value) => setState(() {
                  _reservePercent = value;
                  _dirty = true;
                }),
              ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: 'Lokatsiya',
              icon: Icons.place_outlined,
              subtitle: 'Chizma olingan joyni saqlab qo‘ying',
              child: LocationPicker(
                value: _location,
                onChanged: (value) => setState(() {
                  _location = value;
                  _dirty = true;
                }),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _SaveBar(
          saving: _saving,
          area: geometry.area,
          perimeter: geometry.perimeter,
          onSave: _saving ? null : _save,
        ),
      ),
    );
  }

  Widget _buildInputs() {
    switch (_kind) {
      case RoomKind.rectangle:
        return Row(
          children: <Widget>[
            Expanded(
              child: MeasureField(
                controller: _lengthController,
                label: 'Uzunligi',
                hint: '5.40',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MeasureField(
                controller: _widthController,
                label: 'Kengligi',
                hint: '3.20',
                textInputAction: TextInputAction.done,
              ),
            ),
          ],
        );

      case RoomKind.trapezoid:
        return Column(
          children: <Widget>[
            MeasureField(
              controller: _spanController,
              label: 'Uzunligi (ikki tomon orasidagi masofa)',
              hint: '17.38',
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: MeasureField(
                    controller: _sideAController,
                    label: 'Chap tomoni',
                    hint: '2.96',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MeasureField(
                    controller: _sideBController,
                    label: 'O‘ng tomoni',
                    hint: '3.17',
                    textInputAction: TextInputAction.done,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const NoteBanner(
              text: 'Yuza formulasi: S = (chap + o‘ng) ÷ 2 × uzunlik.',
              icon: Icons.functions,
            ),
          ],
        );

      case RoomKind.polygon:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final template in _Template.values)
                  ActionChip(
                    label: Text(template.title),
                    avatar: Icon(
                      template.icon,
                      size: 15,
                      color: AppColors.shapeStroke,
                    ),
                    backgroundColor: AppColors.surfaceHigh,
                    onPressed: () => _applyTemplate(template),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            for (var i = 0; i < _walls.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _WallRow(
                  index: i,
                  draft: _walls[i],
                  isLast: i == _walls.length - 1,
                  onTurnChanged: (value) => setState(() {
                    _walls[i].turn = value;
                    _dirty = true;
                  }),
                  onRemove: () => _removeWall(i),
                ),
              ),
            const SizedBox(height: 4),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _addWall,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Devor qo‘shish'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const NoteBanner(
              text: 'Har bir devor uzunligini yozing va undan keyin qaysi '
                  'tomonga burilishini tanlang. Oxirgi devor boshlang‘ich '
                  'nuqtaga avtomatik ulanadi.',
              icon: Icons.tips_and_updates_outlined,
            ),
          ],
        );
    }
  }
}

/// Balandlik va zaxira foizini kiritish bo'limi.
class _HeightSection extends StatelessWidget {
  const _HeightSection({
    required this.controller,
    required this.reservePercent,
    required this.estimate,
    required this.onReserveChanged,
  });

  final TextEditingController controller;
  final double reservePercent;
  final RoomEstimate estimate;
  final ValueChanged<double> onReserveChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        MeasureField(
          controller: controller,
          label: 'Xona balandligi (ixtiyoriy)',
          hint: '2.80',
        ),
        const SizedBox(height: 14),
        const Text(
          'Material zaxirasi',
          style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: <Widget>[
            for (final option in RoomEstimate.reserveOptions)
              ChoiceChip(
                label: Text(option == 0 ? "Yo'q" : '+${option.round()}%'),
                selected: (reservePercent - option).abs() < 0.01,
                onSelected: (_) => onReserveChanged(option),
                selectedColor: AppColors.shapeFill,
                backgroundColor: AppColors.surfaceHigh,
                showCheckmark: false,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
                side: BorderSide.none,
              ),
          ],
        ),
        if (estimate.hasHeight) ...<Widget>[
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: StatTile(
                  label: 'Devorlar yuzasi',
                  value: Fmt.area(estimate.wallArea!),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatTile(
                  label: 'Hajmi',
                  value: '${Fmt.number(estimate.volume!)} m³',
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Ko'p burchakli xona uchun tayyor shablonlar.
enum _Template {
  rectangle(
    "To‘rtburchak",
    Icons.crop_square,
    <(double, double)>[(5, 90), (4, 90), (5, 90), (4, 90)],
  ),
  lShape(
    'L-shakl',
    Icons.crop_7_5,
    <(double, double)>[
      (6, 90),
      (3, 90),
      (3, -90),
      (3, 90),
      (3, 90),
      (6, 90),
    ],
  ),
  uShape(
    'U-shakl',
    Icons.crop_16_9,
    <(double, double)>[
      (8, 90),
      (6, 90),
      (2.5, 90),
      (3.5, -90),
      (3, -90),
      (3.5, 90),
      (2.5, 90),
      (6, 90),
    ],
  ),
  empty(
    'Bo‘sh (4 devor)',
    Icons.grid_4x4,
    <(double, double)>[(0, 90), (0, 90), (0, 90), (0, 90)],
  );

  const _Template(this.title, this.icon, this.walls);

  final String title;
  final IconData icon;
  final List<(double, double)> walls;
}

class _WallRow extends StatelessWidget {
  const _WallRow({
    required this.index,
    required this.draft,
    required this.isLast,
    required this.onTurnChanged,
    required this.onRemove,
  });

  final int index;
  final _WallDraft draft;
  final bool isLast;
  final ValueChanged<double> onTurnChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.shapeFill,
            shape: BoxShape.circle,
          ),
          child: Text(
            '${index + 1}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 4,
          child: TextField(
            controller: draft.controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            decoration: const InputDecoration(
              isDense: true,
              hintText: '0.00',
              suffixText: 'm',
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 5,
          child: isLast
              ? Container(
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'Boshiga ulanadi',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              : _TurnSelector(value: draft.turn, onChanged: onTurnChanged),
        ),
        IconButton(
          tooltip: 'Devorni olib tashlash',
          onPressed: onRemove,
          icon: const Icon(
            Icons.remove_circle_outline,
            size: 19,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _TurnSelector extends StatelessWidget {
  const _TurnSelector({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  Future<void> _custom(BuildContext context) async {
    final controller = TextEditingController(text: Fmt.number(value, digits: 1));
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Burilish burchagi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Musbat son — o‘ngga, manfiy son — chapga burilish.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\-]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Burchak',
                suffixText: '°',
              ),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Bekor'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(
              Fmt.parseNumber(controller.text),
            ),
            child: const Text('Tanlash'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final preset = TurnPreset.match(value);
    final label = preset == TurnPreset.custom
        ? '${Fmt.number(value, digits: 1)}°'
        : preset.title;

    return PopupMenuButton<TurnPreset>(
      tooltip: 'Burilish',
      color: AppColors.surfaceHigh,
      position: PopupMenuPosition.under,
      onSelected: (selected) {
        if (selected == TurnPreset.custom) {
          _custom(context);
        } else {
          onChanged(selected.degrees);
        }
      },
      itemBuilder: (context) => <PopupMenuEntry<TurnPreset>>[
        for (final item in TurnPreset.values)
          PopupMenuItem<TurnPreset>(
            value: item,
            child: Row(
              children: <Widget>[
                Icon(
                  switch (item) {
                    TurnPreset.rightAngleRight => Icons.turn_right,
                    TurnPreset.rightAngleLeft => Icons.turn_left,
                    TurnPreset.straight => Icons.straight,
                    TurnPreset.custom => Icons.rotate_right,
                  },
                  size: 17,
                  color: AppColors.shapeStroke,
                ),
                const SizedBox(width: 10),
                Text(item.title),
              ],
            ),
          ),
      ],
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              value > 0
                  ? Icons.turn_right
                  : value < 0
                      ? Icons.turn_left
                      : Icons.straight,
              size: 17,
              color: AppColors.shapeStroke,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.expand_more,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.geometry, required this.showAngles});

  final RoomGeometry geometry;
  final bool showAngles;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.outline),
      ),
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
      child: SketchView(
        geometry: geometry,
        showAngles: showAngles,
      ),
    );
  }
}

class _SaveBar extends StatelessWidget {
  const _SaveBar({
    required this.saving,
    required this.area,
    required this.perimeter,
    required this.onSave,
  });

  final bool saving;
  final double area;
  final double perimeter;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.outline)),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  Fmt.area(area),
                  style: const TextStyle(
                    fontFamily: kSerif,
                    fontSize: 22,
                    height: 1.1,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Perimetr: ${Fmt.meters(perimeter)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: onSave,
            icon: saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined, size: 18),
            label: Text(saving ? 'Saqlanmoqda…' : 'Saqlash'),
          ),
        ],
      ),
    );
  }
}
