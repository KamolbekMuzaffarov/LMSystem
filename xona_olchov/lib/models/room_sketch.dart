import '../core/geometry.dart';
import 'geo_point.dart';
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
  final DateTime createdAt;
  final DateTime updatedAt;

  RoomGeometry? _geometry;

  /// Hisoblangan geometriya (keshlanadi).
  RoomGeometry get geometry =>
      _geometry ??= RoomGeometry.fromWalls(walls, startHeading: startHeading);

  double get area => geometry.area;

  double get perimeter => geometry.perimeter;

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
    DateTime? updatedAt,
    bool clearLocation = false,
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
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
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
          ? GeoPoint.fromJson(Map<String, dynamic>.from(rawLocation))
          : null,
      createdAt: createdAt,
      updatedAt:
          DateTime.tryParse('${json['updatedAt']}')?.toLocal() ?? createdAt,
    );
  }
}
