import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/estimate.dart';
import '../core/formatters.dart';
import '../core/geometry.dart';
import '../models/opening.dart';
import '../models/wall.dart';
import '../theme/app_theme.dart';
import '../widgets/sketch_view.dart';
import '../widgets/ui_bits.dart';

/// Ko'p burchakli xona uchun tayyor shablonlar.
enum ShapeTemplate {
  rectangle(
    'To‘rtburchak',
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

  const ShapeTemplate(this.title, this.icon, this.walls);

  final String title;
  final IconData icon;
  final List<(double, double)> walls;
}

/// Chizmaning jonli ko'rinishi.
class PreviewCard extends StatelessWidget {
  const PreviewCard({
    super.key,
    required this.geometry,
    required this.showAngles,
  });

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
      child: SketchView(geometry: geometry, showAngles: showAngles),
    );
  }
}

/// Balandlik va zaxira foizini kiritish bo'limi.
class HeightSection extends StatelessWidget {
  const HeightSection({
    super.key,
    required this.controller,
    required this.reservePercent,
    required this.estimate,
    required this.outOfRange,
    required this.onReserveChanged,
  });

  final TextEditingController controller;
  final double reservePercent;
  final RoomEstimate estimate;

  /// Kiritilgan balandlik ruxsat etilgan oraliqdan tashqarida.
  final bool outOfRange;

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
        if (outOfRange) ...<Widget>[
          const SizedBox(height: 10),
          NoteBanner(
            text: 'Balandlik ${Fmt.number(RoomEstimate.minHeight, digits: 1)}'
                '–${RoomEstimate.maxHeight.round()} m oralig‘ida bo‘lishi '
                'kerak — bu qiymat saqlanmaydi.',
            tone: NoteTone.warning,
            icon: Icons.warning_amber_rounded,
          ),
        ],
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
                label: Text(option == 0 ? 'Yo‘q' : '+${option.round()}%'),
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
                  label: estimate.hasOpenings ? 'Devorlar (sof)' : 'Devorlar',
                  value: Fmt.area(estimate.wallArea!),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatTile(
                  label: 'Hajmi',
                  value: Fmt.volume(estimate.volume!),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Bitta eshik/derazaning tahrirlash holati.
class OpeningDraft {
  OpeningDraft({
    required this.kind,
    required double width,
    required double height,
    this.count = 1,
  })  : widthController =
            TextEditingController(text: Fmt.number(width)),
        heightController = TextEditingController(text: Fmt.number(height));

  OpeningDraft.from(Opening opening)
      : kind = opening.kind,
        count = opening.count,
        widthController =
            TextEditingController(text: Fmt.number(opening.width)),
        heightController =
            TextEditingController(text: Fmt.number(opening.height));

  /// Tanlangan tur bo'yicha standart o'lchamlar bilan yangi qator.
  factory OpeningDraft.preset(OpeningKind kind) => OpeningDraft(
        kind: kind,
        width: kind.defaultWidth,
        height: kind.defaultHeight,
      );

  OpeningKind kind;
  int count;
  final TextEditingController widthController;
  final TextEditingController heightController;

  Opening toOpening() => Opening(
        kind: kind,
        width: Fmt.parseNumber(widthController.text) ?? 0,
        height: Fmt.parseNumber(heightController.text) ?? 0,
        count: count,
      );

  void dispose() {
    widthController.dispose();
    heightController.dispose();
  }
}

/// Eshik va derazalar bo'limi.
class OpeningsSection extends StatelessWidget {
  const OpeningsSection({
    super.key,
    required this.drafts,
    required this.openings,
    required this.onAdd,
    required this.onKindChanged,
    required this.onCountChanged,
    required this.onRemove,
  });

  final List<OpeningDraft> drafts;

  /// Hisobga kirayotgan (yaroqli) ochiq joylar.
  final List<Opening> openings;

  final ValueChanged<OpeningKind> onAdd;
  final void Function(int index, OpeningKind kind) onKindChanged;
  final void Function(int index, int count) onCountChanged;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (drafts.isEmpty)
          const NoteBanner(
            text: 'Eshik va derazalarni qo‘shsangiz, ularning yuzasi '
                'devorlardan ayriladi, eshiklar eni esa plintus '
                'uzunligidan chiqariladi.',
            icon: Icons.sensor_door_outlined,
          )
        else ...<Widget>[
          for (var i = 0; i < drafts.length; i++)
            Padding(
              padding: EdgeInsets.only(
                bottom: i == drafts.length - 1 ? 0 : 10,
              ),
              child: _OpeningRow(
                draft: drafts[i],
                onKindChanged: (kind) => onKindChanged(i, kind),
                onCountChanged: (value) => onCountChanged(i, value),
                onRemove: () => onRemove(i),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: StatTile(
                  label: 'Ochiq joylar',
                  value: '${openings.pieces} ta',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatTile(
                  label: 'Ayriladigan yuza',
                  value: Fmt.area(openings.totalArea),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final kind in OpeningKind.values)
              ActionChip(
                label: Text('${kind.title} qo‘shish'),
                avatar: Icon(
                  switch (kind) {
                    OpeningKind.door => Icons.sensor_door_outlined,
                    OpeningKind.window => Icons.window_outlined,
                    OpeningKind.other => Icons.crop_free,
                  },
                  size: 15,
                  color: AppColors.shapeStroke,
                ),
                backgroundColor: AppColors.surfaceHigh,
                onPressed: () => onAdd(kind),
              ),
          ],
        ),
      ],
    );
  }
}

class _OpeningRow extends StatelessWidget {
  const _OpeningRow({
    required this.draft,
    required this.onKindChanged,
    required this.onCountChanged,
    required this.onRemove,
  });

  final OpeningDraft draft;
  final ValueChanged<OpeningKind> onKindChanged;
  final ValueChanged<int> onCountChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<OpeningKind>(
                    value: draft.kind,
                    isDense: true,
                    isExpanded: true,
                    dropdownColor: AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(12),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                    onChanged: (value) {
                      if (value != null) onKindChanged(value);
                    },
                    items: <DropdownMenuItem<OpeningKind>>[
                      for (final kind in OpeningKind.values)
                        DropdownMenuItem<OpeningKind>(
                          value: kind,
                          child: Text(kind.title),
                        ),
                    ],
                  ),
                ),
              ),
              _CountStepper(
                value: draft.count,
                onChanged: onCountChanged,
              ),
              IconButton(
                tooltip: 'Olib tashlash',
                onPressed: onRemove,
                icon: const Icon(
                  Icons.remove_circle_outline,
                  size: 19,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: <Widget>[
              Expanded(
                child: MeasureField(
                  controller: draft.widthController,
                  label: 'Eni',
                  hint: '0.80',
                  isDense: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MeasureField(
                  controller: draft.heightController,
                  label: 'Bo‘yi',
                  hint: '2.05',
                  isDense: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CountStepper extends StatelessWidget {
  const _CountStepper({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  static const int maxCount = 99;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _StepButton(
          icon: Icons.remove,
          onPressed: value > 1 ? () => onChanged(value - 1) : null,
        ),
        SizedBox(
          width: 30,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        _StepButton(
          icon: Icons.add,
          onPressed: value < maxCount ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 30,
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 16,
          color: onPressed == null
              ? AppColors.textSecondary.withValues(alpha: 0.4)
              : AppColors.shapeStroke,
        ),
      ),
    );
  }
}

/// Ko'p burchakli rejimdagi bitta devor qatori.
class WallRow extends StatelessWidget {
  const WallRow({
    super.key,
    required this.index,
    required this.controller,
    required this.turn,
    required this.isLast,
    required this.onTurnChanged,
    required this.onRemove,
  });

  final int index;
  final TextEditingController controller;
  final double turn;
  final bool isLast;
  final ValueChanged<double> onTurnChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
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
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: measureInputFormatters,
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
              : TurnSelector(value: turn, onChanged: onTurnChanged),
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

/// Burilish burchagini tanlash tugmasi.
class TurnSelector extends StatelessWidget {
  const TurnSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final double value;
  final ValueChanged<double> onChanged;

  /// Ruxsat etilgan burilish: ±180° ichida.
  ///
  /// Aynan ±180° devorni o'zi ustiga qaytaradi, shuning uchun chetdan
  /// bir oz ichkarida ushlab turamiz.
  static double clamp(double degrees) {
    if (!degrees.isFinite) return 0;
    const limit = 179.9;
    return degrees.clamp(-limit, limit);
  }

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
              'Musbat son — o‘ngga, manfiy son — chapga burilish '
              '(−179.9° … 179.9°).',
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
    if (result != null) onChanged(clamp(result));
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
            child: MenuRow(
              icon: switch (item) {
                TurnPreset.rightAngleRight => Icons.turn_right,
                TurnPreset.rightAngleLeft => Icons.turn_left,
                TurnPreset.straight => Icons.straight,
                TurnPreset.custom => Icons.rotate_right,
              },
              text: item.title,
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

/// Pastdagi saqlash paneli.
class SaveBar extends StatelessWidget {
  const SaveBar({
    super.key,
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
