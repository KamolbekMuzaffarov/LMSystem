import 'package:flutter/material.dart';

import '../core/estimate.dart';
import '../core/formatters.dart';
import '../theme/app_theme.dart';
import 'ui_bits.dart';

/// Material hisobi: pol/potolok, devorlar, hajm va zaxira bilan miqdor.
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
  _Surface _surface = _Surface.floor;

  @override
  void dispose() {
    _perUnit.dispose();
    super.dispose();
  }

  double _baseArea() {
    final estimate = widget.estimate;
    return switch (_surface) {
      _Surface.floor => estimate.floorArea,
      _Surface.walls => estimate.wallArea ?? 0,
      _Surface.both => estimate.totalSurface ?? estimate.floorArea,
    };
  }

  @override
  Widget build(BuildContext context) {
    final estimate = widget.estimate;
    final surfaces = <_Surface>[
      _Surface.floor,
      if (estimate.hasHeight) _Surface.walls,
      if (estimate.hasHeight) _Surface.both,
    ];
    final base = _baseArea();
    final needed = estimate.withReserve(base);
    final perUnit = Fmt.parseNumber(_perUnit.text);
    final units = perUnit == null
        ? 0
        : RoomEstimate.unitsNeeded(needed, perUnit);

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
                    label: 'Devorlar',
                    value: Fmt.area(estimate.wallArea!),
                  ),
                ),
              ],
              if (estimate.volume != null) ...<Widget>[
                const SizedBox(width: 10),
                Expanded(
                  child: StatTile(
                    label: 'Hajmi',
                    value: '${Fmt.number(estimate.volume!)} m³',
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
                for (final surface in surfaces)
                  ButtonSegment<_Surface>(
                    value: surface,
                    label: Text(surface.title),
                  ),
              ],
              selected: <_Surface>{_surface},
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
                    Expanded(
                      child: Text(
                        'Kerakli miqdor',
                        style: const TextStyle(
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
                    '${Fmt.area(base)} + ${estimate.reservePercent.round()}% zaxira',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const Divider(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _perUnit,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          labelText: '1 quti / rulon',
                          hintText: '2.50',
                          suffixText: 'm²',
                          fillColor: AppColors.surface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          units == 0 ? '—' : '$units ta',
                          style: const TextStyle(
                            fontFamily: kSerif,
                            fontSize: 22,
                            height: 1.1,
                            color: AppColors.shapeStroke,
                          ),
                        ),
                        const Text(
                          'kerak',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
