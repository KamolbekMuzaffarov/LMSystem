import '../core/estimate.dart';
import '../core/geometry.dart';
import 'geo_point.dart';
import 'opening.dart';
import 'wall.dart';

/// Xona shaklining turi — tahrirlash oynasidagi rejim.
enum RoomKind {
  rectangle("To‘rtburchak", "Uzunligi va kengligi bo‘yicha"),
  trapezoid('Trapetsiya', 'Ikki tomoni har xil xona'),
  polygon("Ko‘p burchakli", "Devor-devor bo‘yicha, burchaklari cheklanmagan");

  const RoomKind(this.title, this.subtitle);

  final String title;
  final String subtitle;

  static RoomKind fromName(String? name) {
    for (final kind in values) {
      if (kind.name == name) return kind;
    }
    return RoomKind.polygon;
  }
}

/// Saqlangan bitta xona chizmasi.
///
/// Obyekt o'zgarmas (immutable) — har qanday tahrir [copyWith] orqali yangi
/// nusxa yaratadi. Geometriya birinchi murojaatda hisoblanib, keyin keshlanadi.
class RoomSketch {
  RoomSketch({
    required this.id,
    required this.name,
    required this.walls,
    required this.createdAt,
    required this.updatedAt,
    this.description = '',
    this.kind = RoomKind.polygon,
    this.startHeading = 0,
    this.presetInputs = const <String, double>{},
    this.location,
    this.height,
    this.reservePercent = 0,
    this.openings = const <Opening>[],
  });

  final String id;
  final String name;
  final String description;
  final RoomKind kind;
  final List<Wall> walls;

  /// Birinchi devor yo'nalishi, gradusda.
  final double startHeading;

  /// Tayyor shakllar uchun kiritilgan asl o'lchamlar (qayta tahrirlash uchun).
  final Map<String, double> presetInputs;

  final GeoPoint? location;

  /// Xona balandligi, m — devorlar yuzasi va hajmi uchun.
  final double? height;

  /// Material zaxirasi, %.
  final double reservePercent;

  /// Devordagi eshik va derazalar.
  final List<Opening> openings;

  final DateTime createdAt;
  final DateTime updatedAt;

  RoomGeometry? _geometry;

  /// Hisoblangan geometriya (keshlanadi).
  RoomGeometry get geometry =>
      _geometry ??= RoomGeometry.fromWalls(walls, startHeading: startHeading);

  double get area => geometry.area;

  double get perimeter => geometry.perimeter;

  /// Material hisob-kitobi (pol, potolok, devorlar, hajm).
  RoomEstimate get estimate => RoomEstimate(
        floorArea: area,
        perimeter: perimeter,
        height: height,
        reservePercent: reservePercent,
        openings: openings,
      );

  /// Ro'yxatda ko'rsatiladigan nom.
  String get displayName => name.trim().isEmpty ? 'Nomsiz chizma' : name.trim();

  bool get hasLocation => location != null && location!.isValid;

  RoomSketch copyWith({
    String? name,
    String? description,
    RoomKind? kind,
    List<Wall>? walls,
    double? startHeading,
    Map<String, double>? presetInputs,
    GeoPoint? location,
    double? height,
    double? reservePercent,
    List<Opening>? openings,
    DateTime? updatedAt,
    bool clearLocation = false,
    bool clearHeight = false,
  }) {
    return RoomSketch(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      kind: kind ?? this.kind,
      walls: walls ?? this.walls,
      startHeading: startHeading ?? this.startHeading,
      presetInputs: presetInputs ?? this.presetInputs,
      location: clearLocation ? null : (location ?? this.location),
      height: clearHeight ? null : (height ?? this.height),
      reservePercent: reservePercent ?? this.reservePercent,
      openings: openings ?? this.openings,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Chizmadan nusxa: yangi identifikator va yangi sana bilan.
  RoomSketch duplicate({required String id, required String name}) {
    final now = DateTime.now();
    return RoomSketch(
      id: id,
      name: name,
      description: description,
      kind: kind,
      walls: walls,
      startHeading: startHeading,
      presetInputs: presetInputs,
      location: location,
      height: height,
      reservePercent: reservePercent,
      openings: openings,
      createdAt: now,
      updatedAt: now,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'description': description,
        'kind': kind.name,
        'startHeading': startHeading,
        'walls': walls.map((w) => w.toJson()).toList(growable: false),
        if (presetInputs.isNotEmpty) 'presetInputs': presetInputs,
        if (location != null) 'location': location!.toJson(),
        if (height != null) 'height': height,
        if (reservePercent != 0) 'reservePercent': reservePercent,
        if (openings.isNotEmpty)
          'openings': openings.map((o) => o.toJson()).toList(growable: false),
        'createdAt': createdAt.toUtc().toIso8601String(),
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };

  factory RoomSketch.fromJson(Map<String, dynamic> json) {
    final rawWalls = json['walls'];
    final walls = <Wall>[];
    if (rawWalls is List) {
      for (final item in rawWalls) {
        if (item is Map) {
          walls.add(Wall.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    final rawInputs = json['presetInputs'];
    final inputs = <String, double>{};
    if (rawInputs is Map) {
      rawInputs.forEach((key, value) {
        if (value is num && value.toDouble().isFinite) {
          inputs['$key'] = value.toDouble();
        }
      });
    }

    final rawOpenings = json['openings'];
    final openings = <Opening>[];
    if (rawOpenings is List) {
      for (final item in rawOpenings) {
        if (item is! Map) continue;
        final opening = Opening.fromJson(Map<String, dynamic>.from(item));
        if (opening.isValid) openings.add(opening);
      }
    }

    final rawLocation = json['location'];
    final createdAt =
        DateTime.tryParse('${json['createdAt']}')?.toLocal() ?? DateTime.now();

    return RoomSketch(
      id: '${json['id'] ?? ''}',
      name: '${json['name'] ?? ''}',
      description: '${json['description'] ?? ''}',
      kind: RoomKind.fromName(json['kind'] as String?),
      startHeading: json['startHeading'] is num
          ? (json['startHeading'] as num).toDouble()
          : 0,
      walls: List<Wall>.unmodifiable(walls),
      presetInputs: Map<String, double>.unmodifiable(inputs),
      location: rawLocation is Map
          ? GeoPoint.tryFromJson(Map<String, dynamic>.from(rawLocation))
          : null,
      height: json['height'] is num
          ? RoomEstimate.validHeight((json['height'] as num).toDouble())
          : null,
      reservePercent: json['reservePercent'] is num
          ? RoomEstimate.clampReserve((json['reservePercent'] as num).toDouble())
          : 0,
      openings: List<Opening>.unmodifiable(openings),
      createdAt: createdAt,
      updatedAt:
          DateTime.tryParse('${json['updatedAt']}')?.toLocal() ?? createdAt,
    );
  }
}
