/// Devordagi ochiq joy: eshik yoki deraza.
///
/// Bo'yoq, oboy va shpatlyovka hisobida ochiq joylar devor yuzasidan
/// ayriladi; eshiklar esa plintus uzunligini ham qisqartiradi.
enum OpeningKind {
  door('Eshik', 0.80, 2.05),
  window('Deraza', 1.40, 1.50),
  other('Boshqa', 1.00, 1.00);

  const OpeningKind(this.title, this.defaultWidth, this.defaultHeight);

  final String title;

  /// Yangi ochiq joy qo'shilganda taklif qilinadigan o'lcham, m.
  final double defaultWidth;
  final double defaultHeight;

  static OpeningKind fromName(String? name) {
    for (final kind in values) {
      if (kind.name == name) return kind;
    }
    return OpeningKind.other;
  }
}

/// Bitta eshik/deraza (yoki bir xil o'lchamdagi bir nechtasi).
class Opening {
  const Opening({
    required this.kind,
    required this.width,
    required this.height,
    this.count = 1,
  });

  final OpeningKind kind;

  /// Eni, m.
  final double width;

  /// Balandligi, m.
  final double height;

  /// Shu o'lchamdagi ochiq joylar soni.
  final int count;

  /// O'lchamlar ishlatishga yaroqlimi.
  bool get isValid =>
      width.isFinite &&
      height.isFinite &&
      width > 0 &&
      height > 0 &&
      width <= 20 &&
      height <= 20 &&
      count > 0;

  /// Barcha nusxalarining umumiy yuzasi, m².
  double get area => isValid ? width * height * count : 0;

  /// Barcha nusxalarining umumiy eni, m — plintus hisobi uchun.
  double get totalWidth => isValid ? width * count : 0;

  /// "0.80 × 2.05 m" ko'rinishidagi o'lcham.
  String get sizeText =>
      '${width.toStringAsFixed(2)} × ${height.toStringAsFixed(2)} m';

  Opening copyWith({
    OpeningKind? kind,
    double? width,
    double? height,
    int? count,
  }) {
    return Opening(
      kind: kind ?? this.kind,
      width: width ?? this.width,
      height: height ?? this.height,
      count: count ?? this.count,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'kind': kind.name,
    'width': width,
    'height': height,
    if (count != 1) 'count': count,
  };

  factory Opening.fromJson(Map<String, dynamic> json) => Opening(
    kind: OpeningKind.fromName(json['kind'] as String?),
    width: _toDouble(json['width']),
    height: _toDouble(json['height']),
    count: _toCount(json['count']),
  );

  static double _toDouble(Object? value) {
    if (value is num) {
      final result = value.toDouble();
      if (result.isFinite) return result;
    }
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null && parsed.isFinite) return parsed;
    }
    return 0;
  }

  static int _toCount(Object? value) {
    if (value is num && value.isFinite) {
      final result = value.toInt();
      return result > 0 ? result : 1;
    }
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null && parsed > 0) return parsed;
    }
    return 1;
  }

  @override
  bool operator ==(Object other) =>
      other is Opening &&
      other.kind == kind &&
      other.width == width &&
      other.height == height &&
      other.count == count;

  @override
  int get hashCode => Object.hash(kind, width, height, count);
}

/// Ochiq joylar ro'yxati bo'yicha jamlanma.
extension OpeningList on List<Opening> {
  /// Yaroqli o'lchamga ega bo'lganlari.
  Iterable<Opening> get usable => where((item) => item.isValid);

  /// Umumiy yuzasi, m².
  double get totalArea =>
      usable.fold<double>(0, (sum, item) => sum + item.area);

  /// Faqat eshiklarning umumiy eni, m.
  double get doorWidth => usable
      .where((item) => item.kind == OpeningKind.door)
      .fold<double>(0, (sum, item) => sum + item.totalWidth);

  /// Jami dona soni.
  int get pieces => usable.fold<int>(0, (sum, item) => sum + item.count);
}
