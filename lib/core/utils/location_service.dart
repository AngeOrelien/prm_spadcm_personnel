import 'package:geolocator/geolocator.dart';

/// Exception dédiée pour distinguer, côté UI, un refus/blocage de
/// permission d'une simple erreur réseau — permet d'afficher un message
/// clair ("active ta localisation") plutôt qu'un message d'échec générique.
class LocationServiceException implements Exception {
  final String message;
  const LocationServiceException(this.message);

  @override
  String toString() => message;
}

/// Récupère la position GPS réelle de l'appareil, utilisée par le check-in
/// AVS géolocalisé (voir `avs_checkin_page.dart`). Le backend s'en sert pour
/// vérifier que l'AVS est bien au domicile du patient qui lui est affecté
/// (voir `presenceController.checkIn` côté backend) — remplace les valeurs
/// factices utilisées avant l'intégration de `geolocator`.
class LocationService {
  LocationService._();

  /// Retourne la position actuelle, ou lève une [LocationServiceException]
  /// avec un message prêt à afficher si la localisation est indisponible
  /// (service désactivé, permission refusée/bloquée).
  static Future<Position> obtenirPositionActuelle() async {
    final serviceActif = await Geolocator.isLocationServiceEnabled();
    if (!serviceActif) {
      throw const LocationServiceException(
        'La localisation est désactivée sur ton appareil. Active-la pour faire ton check-in.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationServiceException(
          'Autorisation de localisation refusée. Elle est nécessaire pour faire ton check-in.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationServiceException(
        'Autorisation de localisation bloquée. Active-la dans les réglages de l\'appareil pour faire ton check-in.',
      );
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (_) {
      // Position fraîche indisponible (ex: intérieur d'un bâtiment, GPS
      // froid) : on retombe sur la dernière position connue plutôt que de
      // bloquer complètement le check-in.
      final derniere = await Geolocator.getLastKnownPosition();
      if (derniere != null) return derniere;
      throw const LocationServiceException(
        'Impossible d\'obtenir ta position. Vérifie ton signal GPS et réessaie.',
      );
    }
  }
}
