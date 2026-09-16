import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../models/geo_point.dart';

/// Lokatsiya olishdagi natija.
enum LocationStatus {
  ok,
  noInternet,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  failed,
}

class LocationResult {
  const LocationResult(this.status, {this.point, this.message});

  final LocationStatus status;
  final GeoPoint? point;
  final String? message;

  bool get isSuccess => status == LocationStatus.ok && point != null;

  String get userMessage {
    if (message != null) return message!;
    return switch (status) {
      LocationStatus.ok => 'Lokatsiya olindi',
      LocationStatus.noInternet =>
        "Internet o‘chiq — lokatsiyani qo‘lda kiriting yoki internetni yoqing",
      LocationStatus.serviceDisabled =>
        "Qurilmada joylashuv (GPS) o‘chiq — uni yoqing",
      LocationStatus.permissionDenied => 'Lokatsiyaga ruxsat berilmadi',
      LocationStatus.permissionDeniedForever =>
        'Lokatsiyaga ruxsat butunlay yopilgan — sozlamalardan yoqing',
      LocationStatus.timeout =>
        "Signal topilmadi. Ochiq joyda qayta urining yoki qo‘lda kiriting",
      LocationStatus.failed => "Lokatsiyani olib bo‘lmadi",
    };
  }
}

/// GPS va teskari geokodlash bilan ishlaydigan xizmat.
class LocationService {
  const LocationService();

  /// Internet ulanishi bormi (Wi-Fi, mobil yoki ethernet).
  Future<bool> hasConnection() async {
    try {
      final results = await Connectivity().checkConnectivity();
      return results.any(
        (result) =>
            result == ConnectivityResult.mobile ||
            result == ConnectivityResult.wifi ||
            result == ConnectivityResult.ethernet ||
            result == ConnectivityResult.vpn,
      );
    } catch (error) {
      debugPrint('Internet holatini tekshirishda xato: $error');
      return true; // Aniqlanmasa — urinib ko'ramiz.
    }
  }

  /// Joriy joylashuvni aniqlaydi.
  ///
  /// [requireInternet] yoqilganda internet o'chiq bo'lsa, ruxsat so'ralmaydi.
  Future<LocationResult> current({
    bool requireInternet = true,
    bool resolveAddress = true,
    Duration timeout = const Duration(seconds: 25),
  }) async {
    final online = await hasConnection();
    if (requireInternet && !online) {
      return const LocationResult(LocationStatus.noInternet);
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationResult(LocationStatus.serviceDisabled);
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        return const LocationResult(LocationStatus.permissionDeniedForever);
      }
      if (permission == LocationPermission.denied) {
        return const LocationResult(LocationStatus.permissionDenied);
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: timeout,
        ),
      );

      var point = GeoPoint(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        source: LocationSource.gps,
        capturedAt: DateTime.now(),
      );

      if (resolveAddress && online) {
        final address = await describe(point);
        if (address != null) point = point.copyWith(address: address);
      }

      return LocationResult(LocationStatus.ok, point: point);
    } on LocationServiceDisabledException {
      return const LocationResult(LocationStatus.serviceDisabled);
    } on PermissionDeniedException {
      return const LocationResult(LocationStatus.permissionDenied);
    } catch (error) {
      final text = '$error'.toLowerCase();
      if (text.contains('timeout') || text.contains('timelimit')) {
        return const LocationResult(LocationStatus.timeout);
      }
      debugPrint('Lokatsiya xatosi: $error');
      return LocationResult(LocationStatus.failed, message: null);
    }
  }

  /// Koordinatalardan manzil nomini topadi (internet talab qiladi).
  Future<String?> describe(GeoPoint point) async {
    try {
      final places = await Geocoding().placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );
      if (places.isEmpty) return null;
      final place = places.first;
      final parts = <String>[
        if ((place.street ?? '').isNotEmpty) place.street!,
        if ((place.subLocality ?? '').isNotEmpty) place.subLocality!,
        if ((place.locality ?? '').isNotEmpty) place.locality!,
        if ((place.administrativeArea ?? '').isNotEmpty)
          place.administrativeArea!,
        if ((place.country ?? '').isNotEmpty) place.country!,
      ];
      final unique = <String>[];
      for (final part in parts) {
        if (!unique.contains(part)) unique.add(part);
      }
      if (unique.isEmpty) return null;
      return unique.take(3).join(', ');
    } catch (error) {
      debugPrint('Manzilni aniqlashda xato: $error');
      return null;
    }
  }
}
