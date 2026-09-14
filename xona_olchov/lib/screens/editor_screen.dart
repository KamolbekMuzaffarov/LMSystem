import 'package:flutter/material.dart';

import '../core/estimate.dart';
import '../core/formatters.dart';
import '../core/geometry.dart';
import '../core/ids.dart';
import '../data/sketch_store.dart';
import '../models/geo_point.dart';
import '../models/opening.dart';
import '../models/room_sketch.dart';
import '../models/wall.dart';
import '../theme/app_theme.dart';
import '../widgets/location_picker.dart';
import '../widgets/ui_bits.dart';
import 'editor_parts.dart';

/// Bitta devor qatorining tahrirlash holati.
class _WallDraft {
  _WallDraft({String text = '', this.turn = 90})
      : controller = TextEditingController(text: text);

  final TextEditingController controller;
  double turn;

  double get length => Fmt.parseNumber(controller.text) ?? 0;

  void dispose() => controller.dispose();
}

/// Kiritilgan o'lchamlardan hisoblangan holat — bir qurilishda bir marta.
class _Draft {
  const _Draft({
    required this.walls,
    required this.startHeading,
    required this.geometry,
    required this.openings,
  });

  final List<Wall> walls;
  final double startHeading;
  final RoomGeometry geometry;
  final List<Opening> openings;
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

  // Eshik va derazalar
  final List<OpeningDraft> _openings = <OpeningDraft>[];

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
        _walls.add(_WallDraft(text: Fmt.number(wall.length), turn: wall.turn));
      }
    }
    if (_walls.isEmpty) _applyTemplate(ShapeTemplate.rectangle, notify: false);

    for (final opening in initial?.openings ?? const <Opening>[]) {
      _openings.add(OpeningDraft.from(opening));
    }

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
    for (final opening in _openings) {
      _watchOpening(opening);
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

  void _watchOpening(OpeningDraft draft) {
    _watch(draft.widthController);
    _watch(draft.heightController);
  }

  void _unwatchOpening(OpeningDraft draft) {
    _unwatch(draft.widthController);
    _unwatch(draft.heightController);
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
    for (final opening in _openings) {
      opening.dispose();
    }
    _seenText.clear();
    super.dispose();
  }

  // --- Geometriya ----------------------------------------------------------

  double _value(TextEditingController controller) =>
      Fmt.parseNumber(controller.text) ?? 0;

  _Draft _draft() {
    final built = _buildWalls();
    return _Draft(
      walls: built.walls,
      startHeading: built.startHeading,
      geometry: RoomGeometry.fromWalls(
        built.walls,
        startHeading: built.startHeading,
      ),
      openings: <Opening>[
        for (final draft in _openings)
          if (draft.toOpening().isValid) draft.toOpening(),
      ],
    );
  }

  ({List<Wall> walls, double startHeading}) _buildWalls() {
    const none = (walls: <Wall>[], startHeading: 0.0);
    switch (_kind) {
      case RoomKind.rectangle:
        final length = _value(_lengthController);
        final width = _value(_widthController);
        if (length <= 0 || width <= 0) return none;
        final built = ShapePresets.rectangle(length: length, width: width);
        return (walls: built.walls, startHeading: built.startHeading + _rotation);

      case RoomKind.trapezoid:
        final span = _value(_spanController);
        final sideA = _value(_sideAController);
        final sideB = _value(_sideBController);
        if (span <= 0 || sideA <= 0 || sideB <= 0) return none;
        final built = ShapePresets.trapezoid(
          span: span,
          sideA: sideA,
          sideB: sideB,
        );
        return (walls: built.walls, startHeading: built.startHeading + _rotation);

      case RoomKind.polygon:
        return (
          walls: <Wall>[
            for (final draft in _walls)
              if (draft.length > 0) Wall(length: draft.length, turn: draft.turn),
          ],
          startHeading: _rotation,
        );
    }
  }

  /// Kiritilgan balandlik: bo'sh yoki oraliqdan tashqarida bo'lsa `null`.
  double? _height() =>
      RoomEstimate.validHeight(Fmt.parseNumber(_heightController.text));

  /// Balandlik yozilgan, lekin ruxsat etilgan oraliqda emas.
  bool get _heightOutOfRange =>
      Fmt.parseNumber(_heightController.text) != null && _height() == null;

  Map<String, double> _presetInputs() {
    return switch (_kind) {
      RoomKind.rectangle => <String, double>{
          'length': _value(_lengthController),
          'width': _value(_widthController),
          'rotation': _rotation,
        },
      RoomKind.trapezoid => <String, double>{
          'span': _value(_spanController),
          'sideA': _value(_sideAController),
          'sideB': _value(_sideBController),
          'rotation': _rotation,
        },
      RoomKind.polygon => <String, double>{'rotation': _rotation},
    };
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
      context.showSnack('Kamida 3 ta devor bo‘lishi kerak');
      return;
    }
    setState(() {
      final draft = _walls.removeAt(index);
      _unwatch(draft.controller);
      draft.dispose();
      _dirty = true;
    });
  }

  void _applyTemplate(ShapeTemplate template, {bool notify = true}) {
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

  // --- Eshik va derazalar --------------------------------------------------

  void _addOpening(OpeningKind kind) {
    final draft = OpeningDraft.preset(kind);
    _watchOpening(draft);
    setState(() {
      _openings.add(draft);
      _dirty = true;
    });
  }

  void _removeOpening(int index) {
    setState(() {
      final draft = _openings.removeAt(index);
      _unwatchOpening(draft);
      draft.dispose();
      _dirty = true;
    });
  }

  // --- Saqlash -------------------------------------------------------------

  Future<void> _save() async {
    final draft = _draft();
    final geometry = draft.geometry;

    if (draft.walls.isEmpty || geometry.vertices.length < 3) {
      context.showSnack('Kamida 3 ta devor o‘lchamini kiriting');
      return;
    }
    if (!geometry.hasArea) {
      context.showSnack(
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
    final height = _height();

    final bool ok;
    if (_isEditing) {
      ok = await store.update(
        widget.initial!.copyWith(
          name: name,
          description: _descriptionController.text.trim(),
          kind: _kind,
          walls: draft.walls,
          startHeading: draft.startHeading,
          presetInputs: _presetInputs(),
          location: _location,
          clearLocation: _location == null,
          height: height,
          clearHeight: height == null,
          reservePercent: _reservePercent,
          openings: draft.openings,
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
          walls: draft.walls,
          startHeading: draft.startHeading,
          presetInputs: _presetInputs(),
          location: _location,
          height: height,
          reservePercent: _reservePercent,
          openings: draft.openings,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    if (!mounted) return;
    setState(() => _saving = false);
    if (!ok) {
      context.showSnack('Saqlashda xato: ${store.lastError ?? "noma‘lum"}');
      return;
    }
    // Xabar ekran yopilgandan keyin ko'rinadi — messenger'ni oldindan olamiz.
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Chizma yangilandi' : 'Chizma saqlandi'),
        ),
      );
  }

  Future<bool> _confirmExit() async {
    if (!_dirty || _saving) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Saqlanmagan o‘zgarishlar'),
        content: const Text('Chizma hali saqlanmadi. Chiqib ketilsinmi?'),
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
    final draft = _draft();
    final geometry = draft.geometry;
    final implied = geometry.impliedEdge;
    final estimate = RoomEstimate(
      floorArea: geometry.area,
      perimeter: geometry.perimeter,
      height: _height(),
      reservePercent: _reservePercent,
      openings: draft.openings,
    );

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
            PreviewCard(geometry: geometry, showAngles: _showAngles),
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
              child: HeightSection(
                controller: _heightController,
                reservePercent: _reservePercent,
                estimate: estimate,
                outOfRange: _heightOutOfRange,
                onReserveChanged: (value) => setState(() {
                  _reservePercent = value;
                  _dirty = true;
                }),
              ),
            ),
            const SizedBox(height: 12),
            SectionCard(
              title: 'Eshik va derazalar',
              icon: Icons.sensor_door_outlined,
              subtitle: 'Devor yuzasi va plintus hisobidan ayriladi',
              child: OpeningsSection(
                drafts: _openings,
                openings: draft.openings,
                onAdd: _addOpening,
                onRemove: _removeOpening,
                onKindChanged: (index, kind) => setState(() {
                  _openings[index].kind = kind;
                  _dirty = true;
                }),
                onCountChanged: (index, count) => setState(() {
                  _openings[index].count = count;
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
        bottomNavigationBar: SaveBar(
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
                for (final template in ShapeTemplate.values)
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
                child: WallRow(
                  index: i,
                  controller: _walls[i].controller,
                  turn: _walls[i].turn,
                  isLast: i == _walls.length - 1,
                  onTurnChanged: (value) => setState(() {
                    _walls[i].turn = TurnSelector.clamp(value);
                    _dirty = true;
                  }),
                  onRemove: () => _removeWall(i),
                ),
              ),
            const SizedBox(height: 4),
            OutlinedButton.icon(
              onPressed: _addWall,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Devor qo‘shish'),
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
