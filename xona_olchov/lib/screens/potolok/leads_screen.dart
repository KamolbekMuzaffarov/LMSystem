import 'package:flutter/material.dart';

import '../../core/formatters.dart';
import '../../data/potolok_store.dart';
import '../../models/lead.dart';
import '../../services/contact_links.dart';
import '../../services/lead_sender.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui_bits.dart';

/// Yuborilgan va navbatdagi arizalar tarixi.
class LeadsScreen extends StatefulWidget {
  const LeadsScreen({super.key, required this.sender});

  final LeadSender sender;

  @override
  State<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends State<LeadsScreen> {
  bool _busy = false;

  /// Ariza matnini nusxalab, Telegram botni ochadi.
  Future<void> _toTelegram(Lead lead) async {
    final ok = await ContactLinks.sendViaTelegram(lead);
    if (!mounted) return;
    context.showSnack(
      ok
          ? 'Matn nusxalandi — Telegramda joylashtiring'
          : 'Telegram ochilmadi',
    );
  }

  Future<void> _retry() async {
    setState(() => _busy = true);
    final delivered = await widget.sender.flushPending();
    if (!mounted) return;
    setState(() => _busy = false);
    context.showSnack(
      delivered > 0
          ? '$delivered ta ariza yuborildi'
          : 'Hozircha yuborib bo‘lmadi — internetni tekshiring',
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = PotolokScope.of(context);
    final leads = store.leads;
    final pending = store.pendingCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Arizalarim'),
        actions: <Widget>[
          if (pending > 0)
            IconButton(
              tooltip: 'Qayta yuborish',
              onPressed: _busy ? null : _retry,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh, color: AppColors.textSecondary),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: leads.isEmpty
          ? const EmptyState(
              icon: Icons.inbox_outlined,
              title: 'Ariza yo‘q',
              message: 'Bo‘limdagi «Bepul o‘lchovga yozilish» tugmasi orqali '
                  'birinchi arizani yuboring.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: leads.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _LeadCard(
                lead: leads[index],
                onCall: () => ContactLinks.call(leads[index].phone),
                onTelegram: () => _toTelegram(leads[index]),
              ),
            ),
    );
  }
}

class _LeadCard extends StatelessWidget {
  const _LeadCard({
    required this.lead,
    required this.onCall,
    required this.onTelegram,
  });

  final Lead lead;
  final VoidCallback onCall;
  final VoidCallback onTelegram;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (lead.status) {
      LeadStatus.sent => (AppColors.shapeStroke, Icons.check_circle_outline),
      LeadStatus.pending => (AppColors.accent, Icons.schedule),
      LeadStatus.rejected => (AppColors.danger, Icons.error_outline),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  lead.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: kSerif,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                lead.status.title,
                style: TextStyle(fontSize: 12, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              MiniChip(
                icon: Icons.call_outlined,
                text: PhoneRules.pretty(lead.phone),
              ),
              if (lead.area != null)
                MiniChip(
                  icon: Icons.crop_square,
                  text: Fmt.area(lead.area!),
                  accent: true,
                ),
              if (lead.design != null)
                MiniChip(
                  icon: Icons.auto_awesome_outlined,
                  text: lead.design!.title,
                ),
              MiniChip(
                icon: Icons.schedule,
                text: Fmt.relative(lead.createdAt),
              ),
            ],
          ),
          if (lead.comment.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              lead.comment,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (lead.isPending && lead.error != null) ...<Widget>[
            const SizedBox(height: 10),
            NoteBanner(
              tone: NoteTone.warning,
              icon: Icons.cloud_off,
              text: lead.error!,
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCall,
                  icon: const Icon(Icons.call, size: 16),
                  label: const Text('Qo‘ng‘iroq'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onTelegram,
                  icon: const Icon(Icons.send, size: 16),
                  label: const Text('Telegram'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
