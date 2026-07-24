/// Entités du feature AVS (Auxiliaire de Vie Sociale).
///
/// Réutilise volontairement `Patient`, `Avs`, `RapportAvs` et `StatutRapport`
/// du feature Coordonnateur (déjà alignés sur le backend) plutôt que de les
/// dupliquer : voir `coordonnateur/domain/entities/coordonnateur_entities.dart`.

/// Une visite planifiée chez un patient (dérivée d'une `Affectation` côté
/// backend, resituée sur un jour précis pour l'affichage planning).
class VisitePlanifiee {
  final String id;
  final String patientId;
  final String patientNom;
  final String adressePatient;
  final DateTime date;
  final String creneauLibelle;
  final bool terminee;

  const VisitePlanifiee({
    required this.id,
    required this.patientId,
    required this.patientNom,
    required this.adressePatient,
    required this.date,
    required this.creneauLibelle,
    this.terminee = false,
  });
}

enum StatutPresence { enAttente, aLheure, enRetard, absent }

StatutPresence statutPresenceFromString(String? value) {
  switch (value) {
    case 'a_l_heure':
      return StatutPresence.aLheure;
    case 'en_retard':
      return StatutPresence.enRetard;
    case 'absent':
      return StatutPresence.absent;
    case 'en_attente':
    default:
      return StatutPresence.enAttente;
  }
}

/// Check-in/check-out présentiel journalier d'un AVS, avec géolocalisation.
class Presence {
  final String id;
  final DateTime date;
  final DateTime? heureCheckIn;
  final DateTime? heureCheckOut;
  final double? latitude;
  final double? longitude;
  final StatutPresence statut;

  const Presence({
    required this.id,
    required this.date,
    this.heureCheckIn,
    this.heureCheckOut,
    this.latitude,
    this.longitude,
    this.statut = StatutPresence.enAttente,
  });

  bool get aFaitCheckIn => heureCheckIn != null;
  bool get aFaitCheckOut => heureCheckOut != null;
}

/// Statistiques personnelles de ponctualité affichées à l'AVS (résumé) —
/// alimente aussi les statistiques agrégées vues par l'administrateur.
class StatistiquesPonctualiteAvs {
  final int rapportsATemps;
  final int rapportsEnRetard;
  final int checkinsATemps;
  final int checkinsEnRetard;
  final int absences;

  const StatistiquesPonctualiteAvs({
    this.rapportsATemps = 0,
    this.rapportsEnRetard = 0,
    this.checkinsATemps = 0,
    this.checkinsEnRetard = 0,
    this.absences = 0,
  });

  int get totalRapports => rapportsATemps + rapportsEnRetard;
  double get tauxPonctualite => totalRapports == 0 ? 1 : rapportsATemps / totalRapports;
}
