/// Entités du feature AVS (Auxiliaire de Vie Sociale).
///
/// Réutilise volontairement `Patient`, `Affectation`, `Avs`, `RapportAvs`,
/// `StatutRapport`, `Conversation` et `MessageConversation` du feature
/// Coordonnateur (déjà alignés sur le backend) plutôt que de les dupliquer :
/// voir `coordonnateur/domain/entities/coordonnateur_entities.dart`.

enum StatutPresence { enAttente, aLheure, enRetard, absent }

/// ⚠️ Correctif : le backend renvoie `statut` avec les valeurs `'present'`,
/// `'retard'` ou `'absent'` (voir `presenceController.calculerStatutCheckIn`
/// et le modèle `Presence`), jamais `'a_l_heure'`/`'en_retard'`. L'ancien
/// mapping ne matchait donc jamais rien et retombait systématiquement sur
/// `enAttente`, y compris pour un check-in bien enregistré.
StatutPresence statutPresenceFromString(String? value) {
  switch (value) {
    case 'present':
      return StatutPresence.aLheure;
    case 'retard':
      return StatutPresence.enRetard;
    case 'absent':
      return StatutPresence.absent;
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

/// Statistiques personnelles de ponctualité affichées à l'AVS (résumé).
///
/// ⚠️ Pas de route backend dédiée pour ces stats côté AVS (voir
/// `BACKEND-TODO.md`) : elles sont calculées côté app à partir de
/// `GET /rapports` (champ `statutRemise`, auto-filtré sur l'AVS connecté) et
/// `GET /presences` (idem) — voir `AvsActions`/`mesStatistiquesProvider`.
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

/// Entrée d'annuaire (coordonnateur / médecin / administrateur), utilisée
/// par la messagerie AVS pour démarrer une conversation avec "tous les
/// coordonnateurs", "tous les médecins" ou "tous les admins" — voir
/// `GET /utilisateurs/role/:role` (`ApiConstants.utilisateursParRole`).
class PersonnelAnnuaire {
  final String id;
  final String nom;
  final String prenom;
  final String role;
  final String? photoUrl;

  const PersonnelAnnuaire({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.role,
    this.photoUrl,
  });

  String get nomComplet => '$prenom $nom';
}
