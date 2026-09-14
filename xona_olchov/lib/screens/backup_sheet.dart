import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/sketch_store.dart';
import '../services/backup_service.dart';
import '../theme/app_theme.dart';
import '../widgets/ui_bits.dart';

/// Zaxira nusxadan chizmalarni tiklash oynasi.
///
/// Tiklash faqat qo'shadi: mavjud chizma o'chirilmaydi, faqat kelgan nusxa
/// yangiroq bo'lsa yangilanadi.
class BackupSheet extends StatefulWidget {
  const BackupSheet({super.key});

  static Future<void> showRestore(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (_) => const BackupSheet(),
    );
  }

  @override
  State<BackupSheet> createState() => _BackupSheetState();
}

class _BackupSheetState extends State<BackupSheet> {
  final TextEditingController _controller = TextEditingController();
  String? _message;
  NoteTone _tone = NoteTone.info;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text ?? '';
    if (!mounted) return;
    if (text.isEmpty) {
      setState(() {
        _tone = NoteTone.warning;
        _message = 'Klipbordda matn yo‘q';
      });
      return;
    }
    setState(() {
      _controller.text = text;
      _message = null;
    });
  }

  Future<void> _restore() async {
    final store = SketchScope.read(context);
    setState(() => _busy = true);
    final parsed = BackupService.decode(_controller.text);
    if (parsed.sketches.isEmpty) {
      setState(() {
        _busy = false;
        _tone = NoteTone.danger;
        _message = parsed.error ?? 'Chizma topilmadi';
      });
      return;
    }

    final result = await store.importAll(parsed.sketches);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _tone = NoteTone.info;
      _message = '${result.added} ta yangi, ${result.updated} ta yangilandi, '
          '${result.skipped} ta o‘zgarmadi.'
          '${parsed.error == null ? '' : ' (${parsed.error})'}';
    });
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
                'Zaxiradan tiklash',
                style: TextStyle(
                  fontFamily: kSerif,
                  fontSize: 20,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Zaxira fayl matnini shu yerga joylashtiring. Mavjud chizmalar '
                'o‘chirilmaydi — faqat yangilari qo‘shiladi.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                maxLines: 6,
                minLines: 3,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  labelText: 'Zaxira matni (JSON)',
                  hintText: '{"app":"hisob-backup", …}',
                  alignLabelWithHint: true,
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
              if (_message != null) ...<Widget>[
                const SizedBox(height: 12),
                NoteBanner(text: _message!, tone: _tone),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _busy ? null : _restore,
                  icon: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.restore),
                  label: Text(_busy ? 'Tiklanmoqda…' : 'Tiklash'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
