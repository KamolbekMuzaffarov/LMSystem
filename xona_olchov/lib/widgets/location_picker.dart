import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/geo_point.dart';
import '../services/location_service.dart';
import '../services/maps_link.dart';
import '../theme/app_theme.dart';
import 'ui_bits.dart';

/// Lokatsiyani GPS orqali olish yoki qo'lda kiritish bloki.
class LocationPicker extends StatefulWidget {
  const LocationPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final GeoPoint? value;
  final ValueChanged<GeoPoint?> onChanged;

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  static const LocationService _service = LocationService();

  bool _busy = false;
  String? _hint;

  Future<void> _useGps() async {
    setState(() {
      _busy = true;
      _hint = null;
    });
    final result = await _service.current();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _hint = result.isSuccess ? null : result.userMessage;
    });
    if (result.isSuccess) {
      widget.onChanged(result.point);
      _toast('Lokatsiya olindi');
    }
  }

  Future<void> _enterManually() async {
    final point = await showModalBottomSheet<GeoPoint>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (_) => _ManualLocationSheet(initial: widget.value),
    );
    if (point == null || !mounted) return;
    widget.onChanged(point);
    setState(() => _hint = null);
  }

  Future<void> _openInMaps() async {
    final point = widget.value;
    if (point == null) return;
    final opened = await launchUrl(
      point.mapsUri,
      mode: LaunchMode.externalApplication,
    ).catchError((_) => false);
    if (!opened && mounted) {
      _toast("Xarita ilovasini ochib bo‘lmadi");
    }
  }

  void _toast(String message) {
    if (mounted) context.showSnack(message);
  }

  @override
  Widget build(BuildContext context) {
    final point = widget.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (point != null) ...<Widget>[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(
                  Icons.place,
                  color: AppColors.shapeStroke,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (point.address != null) ...<Widget>[
                        Text(
                          point.address!,
                          style: const TextStyle(
                            fontSize: 13.5,
                            color: AppColors.textPrimary,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 3),
                      ],
                      Text(
                        point.coordinatesText,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                          fontFeatures: <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        point.source.title,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Nusxa olish',
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: point.coordinatesText),
                    );
                    _toast('Koordinatalar nusxalandi');
                  },
                  icon: const Icon(
                    Icons.copy_rounded,
                    size: 17,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: _openInMaps,
                icon: const Icon(Icons.map_outlined, size: 17),
                label: const Text('Xaritada'),
              ),
              OutlinedButton.icon(
                onPressed: _enterManually,
                icon: const Icon(Icons.edit_location_alt_outlined, size: 17),
                label: const Text("O‘zgartirish"),
              ),
              OutlinedButton.icon(
                onPressed: _busy ? null : _useGps,
                icon: _busy
                    ? const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location, size: 17),
                label: const Text('Yangilash'),
              ),
              TextButton.icon(
                onPressed: () => widget.onChanged(null),
                icon: const Icon(Icons.link_off, size: 17),
                label: const Text('Olib tashlash'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ] else ...<Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.icon(
                  onPressed: _busy ? null : _useGps,
                  icon: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location, size: 18),
                  label: Text(_busy ? 'Aniqlanmoqda…' : 'GPS orqali'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _enterManually,
                  icon: const Icon(Icons.edit_location_alt_outlined, size: 18),
                  label: const Text("Qo‘lda"),
                ),
              ),
            ],
          ),
        ],
        if (_hint != null) ...<Widget>[
          const SizedBox(height: 10),
          NoteBanner(
            text: _hint!,
            tone: NoteTone.warning,
            icon: Icons.location_off_outlined,
          ),
        ],
      ],
    );
  }
}

/// Koordinatani qo'lda yoki Google Maps havolasi orqali kiritish oynasi.
class _ManualLocationSheet extends StatefulWidget {
  const _ManualLocationSheet({this.initial});

  final GeoPoint? initial;

  @override
  State<_ManualLocationSheet> createState() => _ManualLocationSheetState();
}

class _ManualLocationSheetState extends State<_ManualLocationSheet> {
  late final TextEditingController _linkController = TextEditingController();
  late final TextEditingController _latController = TextEditingController(
    text: widget.initial == null
        ? ''
        : widget.initial!.latitude.toStringAsFixed(6),
  );
  late final TextEditingController _lngController = TextEditingController(
    text: widget.initial == null
        ? ''
        : widget.initial!.longitude.toStringAsFixed(6),
  );

  String? _error;
  bool _resolving = false;

  @override
  void dispose() {
    _linkController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  void _applyLink(String raw) {
    if (raw.trim().isEmpty) return;
    if (MapsLink.isShortLink(raw)) {
      setState(() {
        _error = 'Qisqartirilgan havolada koordinata yo‘q. Google Maps’da '
            'joyni bosib turing va chiqqan koordinatani nusxalang.';
      });
      return;
    }
    final point = MapsLink.parse(raw);
    if (point == null) {
      setState(() => _error = 'Havoladan koordinata topilmadi');
      return;
    }
    setState(() {
      _error = null;
      _latController.text = point.latitude.toStringAsFixed(6);
      _lngController.text = point.longitude.toStringAsFixed(6);
    });
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text ?? '';
    if (text.isEmpty) {
      setState(() => _error = 'Klipbordda matn yo‘q');
      return;
    }
    _linkController.text = text;
    _applyLink(text);
  }

  Future<void> _submit() async {
    final lat = double.tryParse(_latController.text.trim().replaceAll(',', '.'));
    final lng = double.tryParse(_lngController.text.trim().replaceAll(',', '.'));
    if (lat == null || lng == null) {
      setState(() => _error = 'Koordinatalarni to‘g‘ri kiriting');
      return;
    }
    if (!GeoPoint.isValidLatitude(lat) || !GeoPoint.isValidLongitude(lng)) {
      setState(
        () => _error = 'Kenglik −90…90, uzunlik −180…180 oralig‘ida bo‘lishi kerak',
      );
      return;
    }

    var point = GeoPoint(
      latitude: lat,
      longitude: lng,
      source: _linkController.text.trim().isEmpty
          ? LocationSource.manual
          : LocationSource.mapsLink,
      capturedAt: DateTime.now(),
    );

    // Internet bo'lsa — manzil nomini ham topib qo'yamiz.
    setState(() => _resolving = true);
    const service = LocationService();
    if (await service.hasConnection()) {
      final address = await service.describe(point);
      if (address != null) point = point.copyWith(address: address);
    }
    if (!mounted) return;
    setState(() => _resolving = false);
    Navigator.of(context).pop(point);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Lokatsiyani kiritish',
                style: TextStyle(
                  fontFamily: kSerif,
                  fontSize: 20,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Google Maps’dan havolani joylashtiring yoki koordinatalarni '
                'qo‘lda yozing.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _linkController,
                onChanged: (value) {
                  if (value.contains(RegExp(r'\d'))) _applyLink(value);
                },
                maxLines: 2,
                minLines: 1,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  labelText: 'Havola yoki koordinata',
                  hintText: 'https://maps.google.com/… yoki 41.31, 69.24',
                  suffixIcon: IconButton(
                    tooltip: 'Klipborddan joylash',
                    onPressed: _paste,
                    icon: const Icon(
                      Icons.content_paste,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Expanded(
                    child: MeasureField(
                      controller: _latController,
                      label: 'Kenglik (lat)',
                      suffix: '°',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: MeasureField(
                      controller: _lngController,
                      label: 'Uzunlik (lng)',
                      suffix: '°',
                      textInputAction: TextInputAction.done,
                    ),
                  ),
                ],
              ),
              if (_error != null) ...<Widget>[
                const SizedBox(height: 12),
                NoteBanner(text: _error!, tone: NoteTone.danger),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _resolving ? null : _submit,
                  icon: _resolving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(_resolving ? 'Tekshirilmoqda…' : 'Saqlash'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
