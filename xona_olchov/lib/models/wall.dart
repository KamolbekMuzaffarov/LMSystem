import 'dart:math' as math;

/// Xonaning bitta devori.
///
/// [turn] — shu devordan keyin qilinadigan burilish, gradusda.
/// Musbat qiymat — o'ngga, manfiy — chapga burilish
/// (xona ichida yurgan odam nuqtai nazaridan).
class Wall {
  const Wall({
    required this.length,
    this.turn = 90,
    this.label,
    this.showLength = true,
  });

  /// Devor uzunligi, metrda.
  final double length;

  /// Devordan keyingi burilish burchagi, gradusda.
  final double turn;

  /// Ixtiyoriy nom, masalan "Deraza tomoni".
  final String? label;

  /// Chizmada uzunligi yozilsinmi.
  final bool showLength;

  Wall copyWith({
    double? length,
    double? turn,
    String? label,
    bool? showLength,
    bool clearLabel = false,
  }) {
    return Wall(
      length: length ?? this.length,
      turn: turn ?? this.turn,
      label: clearLabel ? null : (label ?? this.label),
      showLength: showLength ?? this.showLength,
    );
  }

  /// Burilishning o'qiladigan tavsifi.
  String get turnText {
    final rounded = (turn * 10).round() / 10;
    if (rounded == 0) return "To‘g‘ri";
    final side = rounded > 0 ? "o‘ngga" : 'chapga';
    final value = rounded.abs();
    final text = value == value.roundToDouble()
        ? value.round().toString()
        : value.toStringAsFixed(1);
    return '$text° $side';
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'length': length,
        'turn': turn,
        if (label != null) 'label': label,
        if (!showLength) 'showLength': false,
      };

  factory Wall.fromJson(Map<String, dynamic> json) => Wall(
        length: _toDouble(json['length']),
        turn: _toDouble(json['turn'], fallback: 90),
        label: json['label'] as String?,
        showLength: json['showLength'] as bool? ?? true,
      );

  static double _toDouble(Object? value, {double fallback = 0}) {
    if (value is num) {
      final result = value.toDouble();
      return result.isFinite ? result : fallback;
    }
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null && parsed.isFinite) return parsed;
    }
    return fallback;
  }

  @override
  bool operator ==(Object other) =>
      other is Wall &&
      other.length == length &&
      other.turn == turn &&
      other.label == label &&
      other.showLength == showLength;

  @override
  int get hashCode => Object.hash(length, turn, label, showLength);
}

/// Tez tanlanadigan burilish variantlari.
enum TurnPreset {
  rightAngleRight(90, "O‘ngga 90°"),
  rightAngleLeft(-90, 'Chapga 90°'),
  straight(0, "To‘g‘ri"),
  custom(double.nan, 'Boshqa burchak');

  const TurnPreset(this.degrees, this.title);

  final double degrees;
  final String title;

  static TurnPreset match(double turn) {
    for (final preset in values) {
      if (preset == TurnPreset.custom) continue;
      if ((preset.degrees - turn).abs() < 0.0001) return preset;
    }
    return TurnPreset.custom;
  }
}

double degreesToRadians(double degrees) => degrees * math.pi / 180;

double radiansToDegrees(double radians) => radians * 180 / math.pi;
