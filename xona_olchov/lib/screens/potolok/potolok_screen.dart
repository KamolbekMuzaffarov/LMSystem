import 'package:flutter/material.dart';

import '../../core/brand.dart';
import '../../core/formatters.dart';
import '../../data/potolok_store.dart';
import '../../models/ceiling.dart';
import '../../models/lead.dart';
import '../../services/contact_links.dart';
import '../../services/lead_sender.dart';
import '../../services/lead_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui_bits.dart';
import 'assistant_screen.dart';
import 'lead_form_sheet.dart';
import 'leads_screen.dart';
import 'potolok_parts.dart';
import 'sketch_picker_sheet.dart';

/// «Natyajnoy potolok» bo'limi.
///
/// Bir ekranda: narx hisobi, shift turlari, kafolat va aloqa. Har bir yo'l
/// oxirida bitta harakat turadi — qo'ng'iroq yoki ariza.
class PotolokScreen extends StatefulWidget {
  const PotolokScreen({super.key, this.sender});

  /// Testlar uchun tayyor yuboruvchi. Berilmasa o'zi yaratiladi.
  final LeadSender? sender;

  @override
  State<PotolokScreen> createState() => _PotolokScreenState();
}

class _PotolokScreenState extends State<PotolokScreen> {
  final TextEditingController _area = TextEditingController();
  CeilingDesign? _design;
  String? _address;
  LeadSender? _sender;
  bool _flushing = false;

  LeadSender get sender => _sender!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_sender != null) return;
    _sender = widget.sender ?? LeadSender(store: PotolokScope.read(context));
    // Bo'lim ochilganda navbatdagi arizalar jimgina qayta yuboriladi.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _flush();
    });
  }

  @override
  void dispose() {
    _area.dispose();
    // Faqat o'zimiz yaratganini yopamiz.
    if (widget.sender == null) _sender?.dispose();
    super.dispose();
  }

  double? get _areaValue => CeilingPrice.validArea(Fmt.parseNumber(_area.text));

  /// Son kiritilgan, lekin hisobga kirmaydi (0 yoki juda katta).
  bool get _areaOutOfRange =>
      Fmt.parseNumber(_area.text) != null && _areaValue == null;

  CeilingQuote get _quote => CeilingQuote(
    area: _areaValue ?? 0,
    somPerUsd: PotolokScope.of(context).somPerUsd,
  );

  Future<void> _flush() async {
    if (_flushing) return;
    _flushing = true;
    try {
      final delivered = await sender.flushPending();
      if (delivered > 0 && mounted) {
        context.showSnack('$delivered ta ariza yuborildi');
      }
    } finally {
      _flushing = false;
    }
  }

  Future<void> _pickSketch() async {
    final sketch = await SketchPickerSheet.show(context);
    if (sketch == null || !mounted) return;
    setState(() {
      _area.text = sketch.area.toStringAsFixed(2);
      _address = sketch.location?.address;
    });
  }

  void _openAssistant() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const AssistantScreen()));
  }

  Future<void> _order() async {
    final result = await LeadFormSheet.show(
      context,
      sender: sender,
      area: _areaValue,
      design: _design,
      address: _address,
    );
    if (result == null || !mounted) return;
    await _thanks(result);
  }

  /// Natijaga qarab javob beradi — navbatda qolgan arizani «yetkazildi»
  /// deb aytmaydi.
  Future<void> _thanks(SendResult result) async {
    final phone = PotolokScope.read(context).contactPhone;
    final queued = !result.isSent;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          queued ? Icons.cloud_off : Icons.check_circle,
          color: queued ? AppColors.accent : AppColors.gold,
          size: 34,
        ),
        title: Text(queued ? 'Ariza saqlandi' : 'Ariza qabul qilindi'),
        content: Text(
          queued
              ? 'Internet yo‘q — ariza telefoningizda saqlandi va ulanish '
                    'tiklanganda o‘zi jo‘naydi. Shoshilinch bo‘lsa qo‘ng‘iroq '
                    'qiling.'
              : 'Tez orada qo‘ng‘iroq qilamiz. Shoshilinch bo‘lsa — '
                    'o‘zingiz qo‘ng‘iroq qiling, darrov javob beramiz.',
          style: const TextStyle(height: 1.45),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Yopish'),
          ),
          if (phone != null)
            FilledButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                ContactLinks.call(phone);
              },
              icon: const Icon(Icons.call, size: 18),
              label: const Text('Qo‘ng‘iroq'),
            ),
        ],
      ),
    );
  }

  Future<void> _call() async {
    final store = PotolokScope.read(context);
    final phone = store.contactPhone;
    if (phone == null) {
      await _editPhone();
      return;
    }
    final ok = await ContactLinks.call(phone);
    if (!ok && mounted) context.showSnack('Qo‘ng‘iroqni ochib bo‘lmadi');
  }

  Future<void> _editPhone() async {
    final store = PotolokScope.read(context);
    final saved = await PhoneDialog.show(context, store.contactPhone);
    if (saved == null || !mounted) return;
    if (saved.isNotEmpty && !PhoneRules.isValid(saved)) {
      context.showSnack('Raqam noto‘g‘ri — masalan +998 90 123 45 67');
      return;
    }
    await store.setContactPhone(saved.isEmpty ? null : saved);
    if (mounted) {
      context.showSnack(saved.isEmpty ? 'Raqam o‘chirildi' : 'Raqam saqlandi');
    }
  }

  Future<void> _open(Future<bool> Function() action, String error) async {
    final ok = await action();
    if (!ok && mounted) context.showSnack(error);
  }

  @override
  Widget build(BuildContext context) {
    final store = PotolokScope.of(context);
    final pending = store.pendingCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text(Brand.section),
        actions: <Widget>[
          IconButton(
            tooltip: 'AI yordamchi',
            onPressed: _openAssistant,
            icon: const Icon(Icons.support_agent, color: AppColors.gold),
          ),
          IconButton(
            tooltip: 'Arizalarim',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => LeadsScreen(sender: sender),
              ),
            ),
            icon: Badge(
              isLabelVisible: pending > 0,
              backgroundColor: AppColors.accent,
              label: Text('$pending'),
              child: const Icon(
                Icons.inbox_outlined,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _call,
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.background,
        icon: const Icon(Icons.call),
        label: const Text('Qo‘ng‘iroq'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
        children: <Widget>[
          if (pending > 0) ...<Widget>[
            _PendingBanner(count: pending, onRetry: _flush),
            const SizedBox(height: 14),
          ],
          PotolokHero(
            onCall: _call,
            onTelegram: () =>
                _open(ContactLinks.telegram, 'Telegram ochilmadi'),
          ),
          const SizedBox(height: 14),
          _Calculator(
            controller: _area,
            quote: _quote,
            outOfRange: _areaOutOfRange,
            onChanged: () => setState(() {}),
            onPickSketch: _pickSketch,
            onOrder: _order,
          ),
          const SizedBox(height: 14),
          _AssistantCard(onTap: _openAssistant),
          const SizedBox(height: 14),
          DesignGallery(
            selected: _design,
            onSelect: (design) =>
                setState(() => _design = _design == design ? null : design),
          ),
          const SizedBox(height: 14),
          const WhyUsCard(),
          const SizedBox(height: 14),
          const FaqCard(),
          const SizedBox(height: 14),
          ContactCard(
            phone: store.contactPhone == null
                ? null
                : PhoneRules.pretty(store.contactPhone!),
            onCall: _call,
            onEditPhone: _editPhone,
            onChannel: () => _open(ContactLinks.telegram, 'Telegram ochilmadi'),
            onBot: () => _open(
              () => ContactLinks.telegram(Brand.telegramBot),
              'Telegram ochilmadi',
            ),
            onSite: () => _open(ContactLinks.site, 'Saytni ochib bo‘lmadi'),
          ),
          const SizedBox(height: 16),
          const Text(
            'Buxoro va Navoiy bo‘ylab bepul o‘lchov. '
            'Narx 1 m² uchun 6\$ dan boshlanadi — material, profil va '
            'o‘rnatish shu narx ichida.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Narx kalkulyatori.
class _Calculator extends StatelessWidget {
  const _Calculator({
    required this.controller,
    required this.quote,
    required this.outOfRange,
    required this.onChanged,
    required this.onPickSketch,
    required this.onOrder,
  });

  final TextEditingController controller;
  final CeilingQuote quote;

  /// Kiritilgan son hisobga kirmaydi.
  final bool outOfRange;
  final VoidCallback onChanged;
  final VoidCallback onPickSketch;
  final VoidCallback onOrder;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Narxni hisoblang',
      subtitle: 'Shift yuzasi xonaning pol yuzasiga teng',
      icon: Icons.calculate_outlined,
      child: Column(
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: MeasureField(
                  controller: controller,
                  label: 'Xona yuzasi',
                  hint: '20',
                  suffix: 'm²',
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: onPickSketch,
                  icon: const Icon(Icons.straighten, size: 17),
                  label: const Text('Chizmadan'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (outOfRange)
            NoteBanner(
              tone: NoteTone.warning,
              icon: Icons.warning_amber_outlined,
              text:
                  'Yuza 0 dan katta va ${CeilingPrice.maxArea.round()} m² '
                  'dan kichik bo‘lishi kerak.',
            )
          else
            QuoteBox(quote: quote),
          const SizedBox(height: 14),
          GoldButton(
            label: 'Bepul o‘lchovga yozilish',
            icon: Icons.event_available_outlined,
            onPressed: onOrder,
          ),
        ],
      ),
    );
  }
}

/// Yuborilmagan arizalar haqida ogohlantirish.
class _PendingBanner extends StatelessWidget {
  const _PendingBanner({required this.count, required this.onRetry});

  final int count;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.cloud_off, size: 17, color: AppColors.accent),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              '$count ta ariza hali yuborilmagan — internet ulanganda '
              'o‘zi jo‘naydi.',
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Yuborish')),
        ],
      ),
    );
  }
}

/// Aloqa raqamini kiritish oynasi.
///
/// Nazoratchi (controller) shu widgetning o'zida yashaydi — oyna yopilish
/// animatsiyasi tugamasdan turib yo'q qilinmaydi.
class PhoneDialog extends StatefulWidget {
  const PhoneDialog({super.key, this.initial});

  final String? initial;

  /// Saqlangan matnni qaytaradi. Bekor qilinsa `null`.
  static Future<String?> show(BuildContext context, String? initial) {
    return showDialog<String>(
      context: context,
      builder: (_) => PhoneDialog(initial: initial),
    );
  }

  @override
  State<PhoneDialog> createState() => _PhoneDialogState();
}

class _PhoneDialogState extends State<PhoneDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial ?? '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Telefon raqami'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text(
            'Bu raqam bo‘limdagi «Qo‘ng‘iroq» tugmalarida ishlatiladi.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.phone,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              hintText: '+998 90 123 45 67',
              prefixIcon: Icon(Icons.call_outlined, size: 20),
            ),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Bekor'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Saqlash'),
        ),
      ],
    );
  }
}

/// AI yordamchiga olib boradigan karta.
class _AssistantCard extends StatelessWidget {
  const _AssistantCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.30)),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.support_agent,
                  color: AppColors.gold,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'AI yordamchi',
                      style: TextStyle(
                        fontFamily: kSerif,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Narx, kafolat, turlari — savolingizga darrov javob',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        color: AppColors.textSecondary,
                      ),
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
