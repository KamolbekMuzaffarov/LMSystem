import 'dart:math' as math;
import 'dart:ui';

import '../models/wall.dart';

/// Chizmadagi bitta qirra — ikkita burchak orasidagi devor.
class RoomEdge {
  const RoomEdge({
    required this.index,
    required this.start,
    required this.end,
    required this.length,
    required this.implied,
    required this.showLength,
    required this.outwardNormal,
    this.label,
  });

  final int index;
  final Offset start;
  final Offset end;

  /// Uzunligi, metrda.
  final double length;

  /// Foydalanuvchi kiritmagan, xonani yopish uchun avtomatik qo'shilgan devor.
  final bool implied;

  final bool showLength;

  /// Xonadan tashqariga qaragan birlik vektor — yozuvlarni joylash uchun.
  final Offset outwardNormal;

  final String? label;

  Offset get mid => Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
}

/// Devorlar ro'yxatidan hisoblangan xona geometriyasi.
///
/// Koordinatalar ekran tartibida: `x` — o'ngga, `y` — pastga.
class RoomGeometry {
  const RoomGeometry({
    required this.vertices,
    required this.edges,
    required this.area,
    required this.perimeter,
    required this.closureGap,
    required this.bounds,
    required this.selfIntersecting,
  });

  /// Xona burchaklari (yopiq halqa — oxirgi nuqta birinchisiga ulanadi).
  final List<Offset> vertices;
  final List<RoomEdge> edges;

  /// Yuza, m².
  final double area;

  /// Perimetr, m.
  final double perimeter;

  /// Oxirgi devor bilan boshlanish nuqtasi orasidagi masofa, m.
  final double closureGap;

  final Rect bounds;

  /// Devorlar bir-birini kesib o'tganmi (o'lcham xato kiritilganda).
  final bool selfIntersecting;

  /// Devorlar aynan yopilganmi.
  bool get isClosed => closureGap <= closureEpsilon;

  bool get isEmpty => vertices.length < 2;

  /// Yuza ishonchli hisoblanadimi.
  bool get hasArea => vertices.length >= 3 && !selfIntersecting && area > 0;

  /// Avtomatik qo'shilgan yopuvchi devor (bo'lsa).
  RoomEdge? get impliedEdge {
    for (final edge in edges) {
      if (edge.implied) return edge;
    }
    return null;
  }

  /// `i`-burchakdagi ichki burchak, gradusda.
  double interiorAngleAt(int i) {
    final n = vertices.length;
    if (n < 3) return 0;
    final prev = vertices[(i - 1 + n) % n];
    final current = vertices[i];
    final next = vertices[(i + 1) % n];
    final u = current - prev;
    final w = next - current;
    final cross = u.dx * w.dy - u.dy * w.dx;
    final dot = u.dx * w.dx + u.dy * w.dy;
    final turn = radiansToDegrees(math.atan2(cross, dot));
    final interior = 180 - (_isClockwise ? turn : -turn);
    return interior;
  }

  bool get _isClockwise => _signedArea >= 0;

  double get _signedArea {
    var sum = 0.0;
    for (var i = 0; i < vertices.length; i++) {
      final a = vertices[i];
      final b = vertices[(i + 1) % vertices.length];
      sum += a.dx * b.dy - b.dx * a.dy;
    }
    return sum / 2;
  }

  static const double closureEpsilon = 0.005;

  static const RoomGeometry empty = RoomGeometry(
    vertices: <Offset>[],
    edges: <RoomEdge>[],
    area: 0,
    perimeter: 0,
    closureGap: 0,
    bounds: Rect.zero,
    selfIntersecting: false,
  );

  /// Devorlar bo'ylab yurib, xona burchaklarini hisoblaydi.
  ///
  /// [startHeading] — birinchi devor yo'nalishi, gradusda (0 — o'ngga).
  static RoomGeometry fromWalls(
    List<Wall> walls, {
    double startHeading = 0,
  }) {
    final usable = walls.where((w) => w.length.isFinite && w.length > 0).length;
    if (walls.isEmpty || usable == 0) return empty;

    final points = <Offset>[Offset.zero];
    var heading = degreesToRadians(startHeading);
    for (final wall in walls) {
      final last = points.last;
      final length = wall.length.isFinite && wall.length > 0 ? wall.length : 0.0;
      points.add(
        Offset(
          last.dx + length * math.cos(heading),
          last.dy + length * math.sin(heading),
        ),
      );
      heading += degreesToRadians(wall.turn);
    }

    final gap = (points.last - points.first).distance;
    final closed = gap <= closureEpsilon;
    final ring = closed ? points.sublist(0, points.length - 1) : points;

    if (ring.length < 2) return empty;

    var signedArea = 0.0;
    var perimeter = 0.0;
    var minX = ring.first.dx;
    var maxX = ring.first.dx;
    var minY = ring.first.dy;
    var maxY = ring.first.dy;

    for (var i = 0; i < ring.length; i++) {
      final a = ring[i];
      final b = ring[(i + 1) % ring.length];
      signedArea += a.dx * b.dy - b.dx * a.dy;
      perimeter += (b - a).distance;
      minX = math.min(minX, a.dx);
      maxX = math.max(maxX, a.dx);
      minY = math.min(minY, a.dy);
      maxY = math.max(maxY, a.dy);
    }
    signedArea /= 2;

    // Tashqi normal yo'nalishi halqa yo'nalishiga bog'liq.
    final orientation = signedArea >= 0 ? 1.0 : -1.0;

    final edges = <RoomEdge>[];
    for (var i = 0; i < ring.length; i++) {
      final a = ring[i];
      final b = ring[(i + 1) % ring.length];
      final delta = b - a;
      final length = delta.distance;
      final unit = length == 0 ? Offset.zero : delta / length;
      final implied = i >= walls.length;
      edges.add(
        RoomEdge(
          index: i,
          start: a,
          end: b,
          length: length,
          implied: implied,
          showLength: implied ? true : walls[i].showLength,
          label: implied ? null : walls[i].label,
          outwardNormal: Offset(unit.dy * orientation, -unit.dx * orientation),
        ),
      );
    }

    return RoomGeometry(
      vertices: ring,
      edges: edges,
      area: signedArea.abs(),
      perimeter: perimeter,
      closureGap: closed ? 0 : gap,
      bounds: Rect.fromLTRB(minX, minY, maxX, maxY),
      selfIntersecting: _hasSelfIntersection(ring),
    );
  }

  /// Yopiq burchaklar halqasidan devorlar ro'yxatini tiklaydi.
  static ({List<Wall> walls, double startHeading}) wallsFromRing(
    List<Offset> ring,
  ) {
    final n = ring.length;
    if (n < 2) return (walls: const <Wall>[], startHeading: 0.0);

    final walls = <Wall>[];
    for (var i = 0; i < n; i++) {
      final a = ring[i];
      final b = ring[(i + 1) % n];
      final c = ring[(i + 2) % n];
      final u = b - a;
      final w = c - b;
      final turn = radiansToDegrees(
        math.atan2(u.dx * w.dy - u.dy * w.dx, u.dx * w.dx + u.dy * w.dy),
      );
      walls.add(Wall(length: u.distance, turn: turn));
    }
    final first = ring[1] - ring[0];
    return (
      walls: walls,
      startHeading: radiansToDegrees(math.atan2(first.dy, first.dx)),
    );
  }

  static bool _hasSelfIntersection(List<Offset> ring) {
    final n = ring.length;
    if (n < 3) return false;

    // Ketma-ket ikki devor to'liq orqaga qaytsa — ular ustma-ust tushadi.
    for (var i = 0; i < n; i++) {
      final u = ring[(i + 1) % n] - ring[i];
      final v = ring[(i + 2) % n] - ring[(i + 1) % n];
      final lengthU = u.distance;
      final lengthV = v.distance;
      if (lengthU < 1e-9 || lengthV < 1e-9) continue;
      final cosine = (u.dx * v.dx + u.dy * v.dy) / (lengthU * lengthV);
      if (cosine < -0.9999) return true;
    }

    if (n < 4) return false;
    for (var i = 0; i < n; i++) {
      final a1 = ring[i];
      final a2 = ring[(i + 1) % n];
      for (var j = i + 1; j < n; j++) {
        // Qo'shni qirralar umumiy burchakka ega — ular tekshirilmaydi.
        if ((j + 1) % n == i || (i + 1) % n == j) continue;
        final b1 = ring[j];
        final b2 = ring[(j + 1) % n];
        if (_segmentsIntersect(a1, a2, b1, b2)) return true;
      }
    }
    return false;
  }

  static bool _segmentsIntersect(Offset p1, Offset p2, Offset p3, Offset p4) {
    double cross(Offset a, Offset b) => a.dx * b.dy - a.dy * b.dx;
    double dot(Offset a, Offset b) => a.dx * b.dx + a.dy * b.dy;

    final r = p2 - p1;
    final s = p4 - p3;
    final qp = p3 - p1;
    final denominator = cross(r, s);
    const eps = 1e-9;

    if (denominator.abs() < 1e-12) {
      // Parallel. Bir chiziqda yotib, ustma-ust tushsa — bu ham xato.
      if (cross(qp, r).abs() > 1e-9) return false;
      final rr = dot(r, r);
      if (rr < 1e-12) return false;
      final t0 = dot(qp, r) / rr;
      final t1 = t0 + dot(s, r) / rr;
      final low = math.min(t0, t1);
      final high = math.max(t0, t1);
      return math.min(high, 1.0) - math.max(low, 0.0) > eps;
    }

    final t = cross(qp, s) / denominator;
    final u = cross(qp, r) / denominator;
    return t > eps && t < 1 - eps && u > eps && u < 1 - eps;
  }
}

/// Tayyor shakllar uchun devor generatorlari.
abstract final class ShapePresets {
  /// To'rtburchak xona.
  static ({List<Wall> walls, double startHeading}) rectangle({
    required double length,
    required double width,
  }) {
    return (
      walls: <Wall>[
        Wall(length: length, turn: 90),
        Wall(length: width, turn: 90),
        Wall(length: length, turn: 90),
        Wall(length: width, turn: 90),
      ],
      startHeading: 0.0,
    );
  }

  /// Trapetsiya: ikki qarama-qarshi tomon parallel, orasidagi masofa [span].
  ///
  /// Yuza = (sideA + sideB) / 2 × span.
  static ({List<Wall> walls, double startHeading}) trapezoid({
    required double span,
    required double sideA,
    required double sideB,
  }) {
    final offset = (sideB - sideA) / 2;
    final ring = <Offset>[
      Offset(0, offset), // yuqori chap
      Offset(span, 0), // yuqori o'ng
      Offset(span, sideB), // pastki o'ng
      Offset(0, sideB - offset), // pastki chap
    ];
    final built = RoomGeometry.wallsFromRing(ring);
    final walls = built.walls;
    if (walls.length != 4) return built;
    return (
      walls: <Wall>[
        walls[0].copyWith(showLength: false),
        walls[1].copyWith(label: "O‘ng tomon"),
        walls[2].copyWith(showLength: false),
        walls[3].copyWith(label: 'Chap tomon'),
      ],
      startHeading: built.startHeading,
    );
  }
}
