import 'package:flutter/material.dart';

import '../../core/brand.dart';
import '../../core/formatters.dart';
import '../../models/ceiling.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ceiling_preview.dart';
import '../../widgets/ui_bits.dart';

/// Bo'limning asosiy harakat tugmasi — oltin gradiyent.
///
/// Narx qanchalik jozibador bo'lmasin, aniq summa qo'ng'iroqda aytiladi:
/// shu sabab har bir ekranda shu tugma ko'zga tashlanib turadi.
class GoldButton extends StatelessWidget {
  const GoldButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.expand = true,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final button = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: <Color>[AppColors.goldSoft, AppColors.gold],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(icon, size: 19, color: AppColors.background),
                const SizedBox(width: 9),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.background,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Bo'lim boshi: nom, shior va asosiy dalillar.
class PotolokHero extends StatelessWidget {
  const PotolokHero({
    super.key,
    required this.onCall,
    required this.onTelegram,
  });

  final VoidCallback onCall;
  final VoidCallback onTelegram;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.30)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF1E2220), Color(0xFF141414)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            Brand.headline,
            style: TextStyle(
              fontFamily: kSerif,
              fontSize: 25,
              height: 1.1,
              letterSpacing: 0.6,
              fontWeight: FontWeight.w600,
              foreground: Paint()
                ..shader = const LinearGradient(
                  colors: <Color>[AppColors.goldSoft, AppColors.gold],
                ).createShader(const Rect.fromLTWH(0, 0, 320, 40)),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            Brand.slogan,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _Fact(icon: Icons.verified_outlined, text: '15 yil kafolat'),
              _Fact(
                icon: Icons.workspace_premium_outlined,
                text: '10+ yil tajriba',
              ),
              _Fact(icon: Icons.place_outlined, text: 'Buxoro · Navoiy'),
              _Fact(icon: Icons.bolt_outlined, text: '1 kunda o‘rnatish'),
            ],
          ),
          const SizedBox(height: 18),
          GoldButton(
            label: 'Qo‘ng‘iroq qilish',
            icon: Icons.call,
            onPressed: onCall,
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onTelegram,
            icon: const Icon(Icons.send, size: 18, color: Color(0xFF2AABEE)),
            label: const Text('Telegram kanal'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
            ),
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13, color: AppColors.gold),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Hisoblangan narx qatori.
///
/// Faqat «dan» narxi ko'rsatiladi — hammasi ichida bo'lgan eng past daraja.
class QuoteBox extends StatelessWidget {
  const QuoteBox({super.key, required this.quote});

  final CeilingQuote quote;

  @override
  Widget build(BuildContext context) {
    if (!quote.isValid) {
      return const NoteBanner(
        text:
            'Xona yuzasini kiriting yoki saqlangan chizmadan tanlang — '
            'narx shu zahoti chiqadi.',
        icon: Icons.calculate_outlined,
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
        color: AppColors.gold.withValues(alpha: 0.08),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '${Fmt.area(quote.area)} · ${quote.usdPerSquare.toStringAsFixed(0)}\$/m²',
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${quote.roundedUsd}\$ ${CeilingQuote.fromWord}',
            style: const TextStyle(
              fontFamily: kSerif,
              fontSize: 30,
              height: 1.05,
              color: AppColors.goldSoft,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '≈ ${Fmt.money(quote.roundedSom)} so‘m',
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Narxga material, profil, o‘rnatish va kafolat kiradi. '
            'Aniq summa o‘lchovdan keyin aytiladi.',
            style: TextStyle(
              fontSize: 12,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shift turlari ko'rgazmasi.
class DesignGallery extends StatelessWidget {
  const DesignGallery({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final CeilingDesign? selected;
  final ValueChanged<CeilingDesign> onSelect;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Shift turlari',
      subtitle: 'Birini tanlang — ariza bilan birga yuboriladi',
      icon: Icons.auto_awesome_outlined,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 520 ? 3 : 2;
          const gap = 10.0;
          final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: <Widget>[
              for (final design in CeilingDesign.values)
                SizedBox(
                  width: width,
                  child: _DesignCard(
                    design: design,
                    selected: design == selected,
                    onTap: () => onSelect(design),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _DesignCard extends StatelessWidget {
  const _DesignCard({
    required this.design,
    required this.selected,
    required this.onTap,
  });

  final CeilingDesign design;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceHigh,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.gold : Colors.transparent,
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AspectRatio(
                aspectRatio: 16 / 10,
                child: CeilingPreview(design: design),
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      design.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: kSerif,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (selected)
                    const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: AppColors.gold,
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                design.description,
                style: const TextStyle(
                  fontSize: 11.5,
                  height: 1.35,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// «Nega biz» ro'yxati.
class WhyUsCard extends StatelessWidget {
  const WhyUsCard({super.key});

  static const List<(IconData, String, String)>
  points = <(IconData, String, String)>[
    (
      Icons.verified_outlined,
      '15 yillik yozma kafolat',
      'Polotno ham, profil ham, ish ham kafolat ostida.',
    ),
    (
      Icons.schedule,
      'Bir kunda tayyor',
      'Ertalab o‘lchov — kechqurun shift joyida. Chang va buzish yo‘q.',
    ),
    (
      Icons.payments_outlined,
      'Hammasi narx ichida',
      'Material, profil, burchaklar, yoritgich teshiklari va o‘rnatish.',
    ),
    (
      Icons.water_drop_outlined,
      'Suvdan himoya',
      'Yuqoridan suv kelsa, polotno uni ushlab qoladi — mebel omon qoladi.',
    ),
    (
      Icons.straighten,
      'Aniq o‘lchov',
      'Xona shu ilovada chiziladi, yuzasi hisoblanadi — narx taxminiy emas.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Nega biz',
      icon: Icons.thumb_up_outlined,
      child: Column(
        children: <Widget>[
          for (final (icon, title, text) in points)
            Padding(
              padding: EdgeInsets.only(
                bottom: title == points.last.$2 ? 0 : 14,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 17, color: AppColors.gold),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          text,
                          style: const TextStyle(
                            fontSize: 12.5,
                            height: 1.4,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Ko'p so'raladigan savollar.
class FaqCard extends StatelessWidget {
  const FaqCard({super.key});

  static const List<(String, String)> items = <(String, String)>[
    (
      'Narx nimaga bog‘liq?',
      'Yuza, xona shakli, burchaklar soni, yoritgichlar va polotno turiga. '
          'Eng past narx — 6\$/m², hammasi ichida. Aniq summani o‘lchovchi '
          'usta joyida aytadi.',
    ),
    (
      'O‘lchov pulli emasmi?',
      'O‘lchov va maslahat bepul. Kelishuvdan keyin ish boshlanadi.',
    ),
    (
      'Qancha vaqt oladi?',
      'Oddiy xona 3–5 soatda tayyor. Kvartira bir kunda tugaydi.',
    ),
    (
      'Chang chiqadimi, remont buziladimi?',
      'Yo‘q. Profil devorga mahkamlanadi, chang deyarli chiqmaydi va '
          'jihozlarni chiqarish shart emas.',
    ),
    (
      'Yoritgichni o‘zim tanlashim mumkinmi?',
      'Ha. Nuqtali, lyustra, yashirin lenta — hammasi o‘rnatiladi. '
          'Teshiklar narx ichida.',
    ),
    (
      'Kafolat qanday ishlaydi?',
      '15 yil — yozma. Polotno cho‘kmasa, rangini yo‘qotmasa ham, '
          'muammo chiqsa bepul tuzatamiz.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Savol-javob',
      icon: Icons.help_outline,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: Column(
          children: <Widget>[
            for (final (question, answer) in items)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 12),
                iconColor: AppColors.gold,
                collapsedIconColor: AppColors.textSecondary,
                title: Text(
                  question,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                children: <Widget>[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      answer,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Aloqa kartasi: telefon, Telegram va sayt.
class ContactCard extends StatelessWidget {
  const ContactCard({
    super.key,
    required this.phone,
    required this.onCall,
    required this.onEditPhone,
    required this.onChannel,
    required this.onBot,
    required this.onSite,
  });

  /// `+998…` ko'rinishidagi raqam yoki `null`.
  final String? phone;
  final VoidCallback onCall;
  final VoidCallback onEditPhone;
  final VoidCallback onChannel;
  final VoidCallback onBot;
  final VoidCallback onSite;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Aloqa',
      icon: Icons.contact_phone_outlined,
      trailing: IconButton(
        tooltip: 'Telefon raqamini o‘zgartirish',
        icon: const Icon(Icons.edit_outlined, size: 18),
        color: AppColors.textSecondary,
        onPressed: onEditPhone,
      ),
      child: Column(
        children: <Widget>[
          _LinkRow(
            icon: Icons.call,
            color: AppColors.gold,
            title: phone ?? 'Telefon raqami kiritilmagan',
            subtitle: phone == null
                ? 'Bosing va o‘z raqamingizni qo‘shing'
                : 'Qo‘ng‘iroq qilish',
            onTap: phone == null ? onEditPhone : onCall,
          ),
          const SizedBox(height: 10),
          _LinkRow(
            icon: Icons.send,
            color: const Color(0xFF2AABEE),
            title: '@${Brand.telegramChannel}',
            subtitle: 'Telegram kanal — ishlarimiz',
            onTap: onChannel,
          ),
          const SizedBox(height: 10),
          _LinkRow(
            icon: Icons.smart_toy_outlined,
            color: const Color(0xFF2AABEE),
            title: '@${Brand.telegramBot}',
            subtitle: 'Ariza boti',
            onTap: onBot,
          ),
          const SizedBox(height: 10),
          _LinkRow(
            icon: Icons.language,
            color: AppColors.shapeStroke,
            title: 'premium-potolok.vercel.app',
            subtitle: 'Sayt — batafsil ma‘lumot',
            onTap: onSite,
          ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceHigh,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 19, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
