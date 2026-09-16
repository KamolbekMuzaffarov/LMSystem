import '../core/brand.dart';
import 'ceiling.dart';

/// Arizaning holati.
enum LeadStatus {
  /// Hali yuborilmagan — internet yo'q yoki server javob bermadi.
  pending('Navbatda'),

  /// Serverga yetib bordi.
  sent('Yuborildi'),

  /// Server rad etdi — qayta urinish foyda bermaydi.
  rejected('Rad etildi');

  const LeadStatus(this.title);

  final String title;

  static LeadStatus byName(String? name) {
    for (final status in values) {
      if (status.name == name) return status;
    }
    return LeadStatus.pending;
  }
}

/// Mijoz arizasi.
class Lead {
  const Lead({
    required this.id,
    required this.name,
    required this.phone,
    required this.createdAt,
    this.area,
    this.design,
    this.address,
    this.comment = '',
    this.status = LeadStatus.pending,
    this.sentAt,
    this.attempts = 0,
    this.error,
  });

  final String id;
  final String name;

  /// Xalqaro ko'rinishdagi raqam: `+998901234567`.
  final String phone;

  /// Shift yuzasi, m².
  final double? area;

  final CeilingDesign? design;

  /// Manzil yoki mo'ljal.
  final String? address;

  final String comment;
  final LeadStatus status;
  final DateTime createdAt;
  final DateTime? sentAt;

  /// Yuborishga necha marta urinilgan.
  final int attempts;

  /// Oxirgi xatolik sababi.
  final String? error;

  bool get isPending => status == LeadStatus.pending;

  CeilingQuote? get quote =>
      area == null ? null : CeilingQuote(area: area!);

  Lead copyWith({
    LeadStatus? status,
    DateTime? sentAt,
    int? attempts,
    String? error,
    bool clearError = false,
  }) {
    return Lead(
      id: id,
      name: name,
      phone: phone,
      area: area,
      design: design,
      address: address,
      comment: comment,
      createdAt: createdAt,
      status: status ?? this.status,
      sentAt: sentAt ?? this.sentAt,
      attempts: attempts ?? this.attempts,
      error: clearError ? null : (error ?? this.error),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'phone': phone,
        if (area != null) 'area': area,
        if (design != null) 'design': design!.name,
        if (address != null && address!.isNotEmpty) 'address': address,
        if (comment.isNotEmpty) 'comment': comment,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        if (sentAt != null) 'sentAt': sentAt!.toIso8601String(),
        'attempts': attempts,
        if (error != null) 'error': error,
      };

  static Lead fromJson(Map<String, dynamic> json) {
    return Lead(
      id: '${json['id'] ?? ''}',
      name: '${json['name'] ?? ''}',
      phone: '${json['phone'] ?? ''}',
      area: _toDouble(json['area']),
      design: CeilingDesign.byName(json['design'] as String?),
      address: json['address'] as String?,
      comment: '${json['comment'] ?? ''}',
      status: LeadStatus.byName(json['status'] as String?),
      createdAt: _toDate(json['createdAt']) ?? DateTime.now(),
      sentAt: _toDate(json['sentAt']),
      attempts: _toInt(json['attempts']),
      error: json['error'] as String?,
    );
  }

  /// Serverga yuboriladigan maydonlar.
  ///
  /// `website` — bo'sh qoladigan tuzoq maydon (honeypot): spam robotlar uni
  /// to'ldiradi, haqiqiy ilova esa hech qachon to'ldirmaydi.
  Map<String, dynamic> toPayload() => <String, dynamic>{
        'id': id,
        'name': name,
        'phone': phone,
        if (area != null) 'area': double.parse(area!.toStringAsFixed(2)),
        if (design != null) 'design': design!.title,
        if (address != null && address!.isNotEmpty) 'address': address,
        if (comment.isNotEmpty) 'comment': comment,
        'website': '',
        'source': Brand.source,
        'createdAt': createdAt.toUtc().toIso8601String(),
      };

  /// Telegram botga yuboriladigan matn — server ishlamay qolsa zaxira yo'l.
  String toMessage() {
    final buffer = StringBuffer('Yangi ariza\n')
      ..writeln('Ism: $name')
      ..writeln('Telefon: ${PhoneRules.pretty(phone)}');
    if (area != null) {
      buffer.writeln('Yuza: ${area!.toStringAsFixed(2)} m²');
    }
    if (design != null) buffer.writeln('Tur: ${design!.title}');
    if (address != null && address!.isNotEmpty) {
      buffer.writeln('Manzil: $address');
    }
    if (comment.isNotEmpty) buffer.writeln('Izoh: $comment');
    return buffer.toString().trimRight();
  }

  static double? _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(',', '.'));
    return null;
  }

  static int _toInt(Object? value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime? _toDate(Object? value) {
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

/// O'zbekiston mobil raqamlari uchun tekshiruv.
abstract final class PhoneRules {
  /// Amaldagi operator kodlari.
  static const Set<String> operatorCodes = <String>{
    '20', '33', '50', '55', '61', '62', '63', '65', '66', '67', '69',
    '70', '71', '72', '73', '74', '75', '76', '77', '78', '79',
    '88', '90', '91', '93', '94', '95', '97', '98', '99',
  };

  static const String countryCode = '998';

  /// Kiritilgan matnni `+998XXXXXXXXX` ko'rinishiga keltiradi.
  ///
  /// Raqam noto'g'ri bo'lsa `null` qaytadi. `+998 93 985 61 02`,
  /// `998939856102`, `93 985-61-02` va `8 93 985 61 02` — hammasi qabul
  /// qilinadi.
  static String? normalize(String raw) {
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 12 && digits.startsWith(countryCode)) {
      digits = digits.substring(3);
    } else if (digits.length == 10 && digits.startsWith('8')) {
      // Eski ichki format: 8 dan keyingi 9 raqam.
      digits = digits.substring(1);
    }
    if (digits.length != 9) return null;
    if (!operatorCodes.contains(digits.substring(0, 2))) return null;
    return '+$countryCode$digits';
  }

  static bool isValid(String raw) => normalize(raw) != null;

  /// `+998939856102` -> `+998 93 985 61 02`
  static String pretty(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 12 || !digits.startsWith(countryCode)) return phone;
    final national = digits.substring(3);
    return '+$countryCode ${national.substring(0, 2)} '
        '${national.substring(2, 5)} ${national.substring(5, 7)} '
        '${national.substring(7)}';
  }
}

/// Ism uchun eng qisqa tekshiruv.
abstract final class NameRules {
  static const int minLength = 2;
  static const int maxLength = 60;

  static String clean(String raw) => raw.trim().replaceAll(RegExp(r'\s+'), ' ');

  static bool isValid(String raw) {
    final value = clean(raw);
    return value.length >= minLength && value.length <= maxLength;
  }
}
