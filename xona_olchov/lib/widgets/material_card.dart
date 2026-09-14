import 'package:flutter/material.dart';

import '../core/estimate.dart';
import '../core/formatters.dart';
import '../models/opening.dart';
import '../theme/app_theme.dart';
import 'ui_bits.dart';

/// Material hisobi: pol/potolok, devorlar, hajm, plintus va narx.
class MaterialCard extends StatefulWidget {
  const MaterialCard({super.key, required this.estimate});

  final RoomEstimate estimate;

  @override
  State<MaterialCard> createState() => _MaterialCardState();
}

enum _Surface {
  floor('Pol / potolok'),
  walls('Devorlar'),
  both('Pol + devorlar');

  const _Surface(this.title);

  final String title;
}

class _MaterialCardState extends State<MaterialCard> {
  final TextEditingController _perUnit = TextEditingController();
  final TextEditingController _price = TextEditingController();
  _Surface _surface = _Surface.floor;

  @override
  void dispose() {
    _perUnit.dispose();
    _price.dispose();
    super.dispose();
  }

  /// Hozir tanlash mumkin bo'lgan yuzalar.
  ///
  /// Balandlik o'chirilsa devor variantlari yo'qoladi — tanlov ham
  /// avtomatik polga qaytadi, aks holda hisob 0 bo'lib qolardi.
  List<_Surface> get _available => <_Surface>[
        _Surface.floor,
        if (widget.estimate.hasHeight) _Surface.walls,
        if (widget.estimate.hasHeight) _Surface.both,
      ];

  double _baseArea(_Surface surface) {
    final estimate = widget.estimate;
    return switch (surface) {
      _Surface.floor => estimate.floorArea,
      _Surface.walls => estimate.wallArea ?? 0,
      _Surface.both => estimate.totalSurface ?? estimate.floorArea,
    };
  }

  @override
  Widget build(BuildContext context) {
    final estimate = widget.estimate;
    final surfaces = _available;
    final surface = surfaces.contains(_surface) ? _surface : _Surface.floor;
    final base = _baseArea(surface);
    final needed = estimate.withReserve(base);
    final perUnit = Fmt.parseNumber(_perUnit.text);
    final units =
        perUnit == null ? 0 : RoomEstimate.unitsNeeded(needed, perUnit);
    final cost = RoomEstimate.totalCost(needed, Fmt.parseNumber(_price.text));

    return SectionCard(
      title: 'Material hisobi',
      icon: Icons.calculate_outlined,
      subtitle: estimate.reservePercent > 0
          ? 'Zaxira +${estimate.reservePercent.round()}% bilan'
          : 'Zaxira qo‘shilmagan',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: StatTile(
                  label: 'Pol / potolok',
                  value: Fmt.area(estimate.floorArea),
                ),
              ),
              if (estimate.wallArea != null) ...<Widget>[
                const SizedBox(width: 10),
                Expanded(
                  child: StatTile(
                    label: estimate.hasOpenings ? 'Devorlar (sof)' : 'Devorlar',
                    value: Fmt.area(estimate.wallArea!),
                  ),
                ),
              ],
              if (estimate.volume != null) ...<Widget>[
                const SizedBox(width: 10),
                Expanded(
                  child: StatTile(
                    label: 'Hajmi',
                    value: Fmt.volume(estimate.volume!),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: StatTile(
                  label: estimate.openings.doorWidth > 0
                      ? 'Plintus (eshiksiz)'
                      : 'Plintus',
                  value: Fmt.meters(estimate.skirtingLength),
                ),
              ),
              if (estimate.hasOpenings) ...<Widget>[
                const SizedBox(width: 10),
                Expanded(
                  child: StatTile(
                    label: 'Eshik / deraza',
                    value: Fmt.area(estimate.openingArea),
                  ),
                ),
              ],
            ],
          ),
          if (!estimate.hasHeight) ...<Widget>[
            const SizedBox(height: 12),
            const NoteBanner(
              text: 'Devorlar yuzasi va hajmini ko‘rish uchun tahrirlashda '
                  'xona balandligini kiriting.',
              icon: Icons.height,
            ),
          ],
          const SizedBox(height: 16),
          if (surfaces.length > 1) ...<Widget>[
            SegmentedButton<_Surface>(
              segments: <ButtonSegment<_Surface>>[
                for (final item in surfaces)
                  ButtonSegment<_Surface>(
                    value: item,
                    label: Text(item.title),
                  ),
              ],
              selected: <_Surface>{surface},
              showSelectedIcon: false,
              onSelectionChanged: (value) =>
                  setState(() => _surface = value.first),
            ),
            const SizedBox(height: 14),
          ],
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Expanded(
                      child: Text(
                        'Kerakli miqdor',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Text(
                      Fmt.area(needed),
                      style: const TextStyle(
                        fontFamily: kSerif,
                        fontSize: 20,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                if (estimate.reservePercent > 0) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    '${Fmt.area(base)} + '
                    '${estimate.reservePercent.round()}% zaxira',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const Divider(height: 20),
                _CalcRow(
                  controller: _perUnit,
                  label: '1 quti / rulon',
                  hint: '2.50',
                  suffix: 'm²',
                  result: units == 0 ? '—' : '$units ta',
                  caption: 'kerak',
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                _CalcRow(
                  controller: _price,
                  label: '1 m² narxi',
                  hint: '85000',
                  suffix: 'so‘m',
                  result: cost == null ? '—' : Fmt.money(cost),
                  caption: 'jami',
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Kiritish maydoni → natija" juftligi.
class _CalcRow extends StatelessWidget {
  const _CalcRow({
    required this.controller,
    required this.label,
    required this.hint,
    required this.suffix,
    required this.result,
    required this.caption,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final String suffix;
  final String result;
  final String caption;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: MeasureField(
            controller: controller,
            label: label,
            hint: hint,
            suffix: suffix,
            isDense: true,
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 84, maxWidth: 132),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  result,
                  maxLines: 1,
                  style: const TextStyle(
                    fontFamily: kSerif,
                    fontSize: 22,
                    height: 1.1,
                    color: AppColors.shapeStroke,
                  ),
                ),
              ),
              Text(
                caption,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
