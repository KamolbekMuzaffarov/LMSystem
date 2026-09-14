import 'dart:math' as math;

/// Chizmalar uchun takrorlanmas identifikator.
abstract final class Ids {
  static final math.Random _random = math.Random.secure();
  static const String _alphabet = '0123456789abcdefghijklmnopqrstuvwxyz';

  static String generate() {
    final stamp = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final suffix = List<String>.generate(
      6,
      (_) => _alphabet[_random.nextInt(_alphabet.length)],
      growable: false,
    ).join();
    return '$stamp-$suffix';
  }
}
