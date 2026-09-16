import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/formatters.dart';
import '../../models/ceiling.dart';
import '../../models/lead.dart';
import '../../services/contact_links.dart';
import '../../services/lead_sender.dart';
import '../../services/lead_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui_bits.dart';
import 'potolok_parts.dart';

/// Ariza oynasi — ism, telefon va (ixtiyoriy) qo'shimcha ma'lumot.
class LeadFormSheet extends StatefulWidget {
  const LeadFormSheet({
    super.key,
    required this.sender,
    this.area,
    this.design,
    this.address,
  });

  final LeadSender sender;
  final double? area;
  final CeilingDesign? design;
  final String? address;

  /// Oynani ochadi. Bekor qilinsa `null`, aks holda yuborish natijasi.
  static Future<SendResult?> show(
    BuildContext context, {
    required LeadSender sender,
    double? area,
    CeilingDesign? design,
    String? address,
  }) {
    return showModalBottomSheet<SendResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => LeadFormSheet(
        sender: sender,
        area: area,
        design: design,
        address: address,
      ),
    );
  }

  @override
  State<LeadFormSheet> createState() => _LeadFormSheetState();
}

class _LeadFormSheetState extends State<LeadFormSheet> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _comment = TextEditingController();

  bool _busy = false;
  bool _showErrors = false;

  @override
  void initState() {
    super.initState();
    _address.text = widget.address ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _comment.dispose();
    super.dispose();
  }

  bool get _nameOk => NameRules.isValid(_name.text);
  bool get _phoneOk => PhoneRules.isValid(_phone.text);

  Future<void> _submit() async {
    if (!_nameOk || !_phoneOk) {
      setState(() => _showErrors = true);
      return;
    }
    setState(() => _busy = true);
    final result = await widget.sender.submit(
      name: _name.text,
      phone: _phone.text,
      area: widget.area,
      design: widget.design,
      address: _address.text,
      comment: _comment.text,
    );
    if (!mounted) return;
    setState(() => _busy = false);

    if (result.outcome == SendOutcome.rejected) {
      setState(() => _showErrors = true);
      context.showSnack(result.userMessage);
      return;
    }
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.outline,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const Text(
              'Bepul o‘lchov uchun ariza',
              style: TextStyle(
                fontFamily: kSerif,
                fontSize: 21,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Usta o‘zi qo‘ng‘iroq qiladi va aniq narxni aytadi.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            if (widget.area != null || widget.design != null) ...<Widget>[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  if (widget.area != null)
                    MiniChip(
                      icon: Icons.crop_square,
                      text: Fmt.area(widget.area!),
                      accent: true,
                    ),
                  if (widget.design != null)
                    MiniChip(
                      icon: Icons.auto_awesome_outlined,
                      text: widget.design!.title,
                    ),
                ],
              ),
            ],
            const SizedBox(height: 18),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              maxLength: NameRules.maxLength,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Ismingiz',
                counterText: '',
                prefixIcon: const Icon(
                  Icons.person_outline,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                errorText: _showErrors && !_nameOk ? 'Ismni kiriting' : null,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s()-]')),
                LengthLimitingTextInputFormatter(20),
              ],
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Telefon raqamingiz',
                hintText: '+998 90 123 45 67',
                prefixIcon: const Icon(
                  Icons.call_outlined,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                errorText: _showErrors && !_phoneOk
                    ? 'Raqamni to‘liq kiriting'
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _address,
              textInputAction: TextInputAction.next,
              maxLength: 120,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Manzil yoki mo‘ljal (ixtiyoriy)',
                counterText: '',
                prefixIcon: Icon(
                  Icons.place_outlined,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _comment,
              maxLines: 3,
              maxLength: 400,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Izoh (ixtiyoriy)',
                counterText: '',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            if (_busy)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: CircularProgressIndicator(color: AppColors.gold),
                ),
              )
            else
              GoldButton(
                label: 'Arizani yuborish',
                icon: Icons.send,
                onPressed: _submit,
              ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: _busy
                  ? null
                  : () async {
                      final ok = await ContactLinks.telegram();
                      if (!ok && context.mounted) {
                        context.showSnack('Telegram ochilmadi');
                      }
                    },
              icon: const Icon(Icons.send, size: 17),
              label: const Text('Telegram orqali yozish'),
            ),
            const SizedBox(height: 4),
            const Text(
              'Raqamingiz faqat qo‘ng‘iroq uchun ishlatiladi.',
              style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
