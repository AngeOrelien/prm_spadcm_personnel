/// Entités du feature Coordonnateur.
///
/// Alignées sur les vraies réponses du backend `prm-spad-backend`
/// (`/api/patients`, `/api/utilisateurs/avs/equipe`, `/api/assignations`,
/// `/api/rapports`) — voir `data/models/coordonnateur_models.dart` pour le
/// mapping JSON -> entité.

enum StatutAvs { disponible, enIntervention, absent }

StatutAvs statutAvsFromString(String? value) {
  switch (value) {
    case 'en_intervention':
      return StatutAvs.enIntervention;
    case 'absent':
      return StatutAvs.absent;
    case 'disponible':
    default:
      return StatutAvs.disponible;
  }
}

String statutAvsToApi(StatutAvs statut) {
  switch (statut) {
    case StatutAvs.enIntervention:
      return 'en_intervention';
    case StatutAvs.absent:
      return 'absent';
    case StatutAvs.disponible:
      return 'disponible';
  }
}

class ContactUrgence {
  final String? nom;
  final String? lien;
  final String? telephone;

  const ContactUrgence({this.nom, this.lien, this.telephone});

  bool get estVide => (nom == null || nom!.isEmpty) && (telephone == null || telephone!.isEmpty);
}

class Avs {
  final String id;
  final String nom;
  final String prenom;
  final String telephone;
  final String? email;
  final StatutAvs statut;
  final int patientsAssignes;
  // Pas encore renvoyé par le backend (le modèle `Utilisateur` n'a pas de
  // champ `photoUrl` pour l'instant) — voir `BACKEND_TODO.md`. Le champ est
  // déjà câblé côté app pour afficher la vraie photo dès qu'elle existera.
  final String? photoUrl;

  const Avs({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.telephone,
    this.email,
    required this.statut,
    required this.patientsAssignes,
    this.photoUrl,
  });

  String get nomComplet => '$prenom $nom';
}

class Patient {
  final String id;
  final String nom;
  final String prenom;
  final int? age;
  final DateTime? dateNaissance;
  final String adresse;
  final String pathologie;
  final List<String> antecedents;
  final List<String> allergies;
  final List<String> difficultesMobilite;
  final ContactUrgence? contactUrgence;
  final String? telephone;
  final String? avsAssigneId;
  final String? avsAssigneNom;
  final String? photoUrl;
  final String? email;

  const Patient({
    required this.id,
    required this.nom,
    required this.prenom,
    this.age,
    this.dateNaissance,
    required this.adresse,
    required this.pathologie,
    this.antecedents = const [],
    this.allergies = const [],
    this.difficultesMobilite = const [],
    this.contactUrgence,
    this.telephone,
    this.avsAssigneId,
    this.avsAssigneNom,
    this.photoUrl,
    this.email,
  });

  String get nomComplet => '$prenom $nom';
}

class Affectation {
  final String id;
  final String patientId;
  final String avsId;
  final String? patientNom;
  final String? avsNom;
  final String frequence;
  final DateTime depuisLe;
  final DateTime? finLe;
  final bool active;

  const Affectation({
    required this.id,
    required this.patientId,
    required this.avsId,
    this.patientNom,
    this.avsNom,
    required this.frequence,
    required this.depuisLe,
    this.finLe,
    this.active = true,
  });
}

enum StatutRapport { enAttente, valide, rejete }

/// Ponctualité de la SAISIE du rapport (heure de remise vs heure limite de
/// l'affectation) — distincte de [StatutRapport], qui est le statut de
/// VALIDATION médicale. Alimente les stats personnelles de ponctualité de
/// l'AVS (voir `avs/presentation/providers/avs_providers.dart`). Correspond
/// au champ `statutRemise` du backend (`'a_temps' | 'en_retard'`, voir
/// `utils/statutRemise.js`).
enum StatutRemiseRapport { aTemps, enRetard }

StatutRemiseRapport? statutRemiseFromString(String? value) {
  switch (value) {
    case 'a_temps':
      return StatutRemiseRapport.aTemps;
    case 'en_retard':
      return StatutRemiseRapport.enRetard;
    default:
      return null;
  }
}

class RapportAvs {
  final String id;
  final String avsId;
  final String patientId;
  final DateTime date;
  final String resume;
  final StatutRapport statut;
  final String? motifRejet;
  final StatutRemiseRapport? statutRemise;

  const RapportAvs({
    required this.id,
    required this.avsId,
    required this.patientId,
    required this.date,
    required this.resume,
    this.statut = StatutRapport.enAttente,
    this.motifRejet,
    this.statutRemise,
  });

  RapportAvs copierAvec({StatutRapport? statut}) {
    return RapportAvs(
      id: id,
      avsId: avsId,
      patientId: patientId,
      date: date,
      resume: resume,
      statut: statut ?? this.statut,
      motifRejet: motifRejet,
      statutRemise: statutRemise,
    );
  }
}

// ---------------------------------------------------------------------------
// Messagerie — alignées sur `POST/GET /api/conversations` et
// `/api/conversations/:id/messages` (voir `messagerieController.js`).
// ---------------------------------------------------------------------------

class Conversation {
  final String id;
  final String? nom;
  final String? interlocuteurId;
  final String? interlocuteurNom;
  final String? interlocuteurSousTitre;
  final String? dernierMessage;
  final DateTime? dernierMessageAt;
  final bool nonLue;

  const Conversation({
    required this.id,
    this.nom,
    this.interlocuteurId,
    this.interlocuteurNom,
    this.interlocuteurSousTitre,
    this.dernierMessage,
    this.dernierMessageAt,
    this.nonLue = false,
  });
}

class MessageConversation {
  final String id;
  final String conversationId;
  final String expediteurId;
  final String? expediteurNom;
  final String contenu;
  final DateTime creeLe;
  final bool deMoi;

  const MessageConversation({
    required this.id,
    required this.conversationId,
    required this.expediteurId,
    this.expediteurNom,
    required this.contenu,
    required this.creeLe,
    required this.deMoi,
  });
}

// ---------------------------------------------------------------------------
// Présences / check-in — alignées sur `/api/presences` (voir
// `presenceController.js`). Sert à l'onglet "Check-in" du coordonnateur.
// ---------------------------------------------------------------------------

enum StatutPresenceCoordonnateur { present, retard, absent }

StatutPresenceCoordonnateur statutPresenceCoordonnateurFromString(String? value) {
  switch (value) {
    case 'retard':
      return StatutPresenceCoordonnateur.retard;
    case 'absent':
      return StatutPresenceCoordonnateur.absent;
    case 'present':
    default:
      return StatutPresenceCoordonnateur.present;
  }
}

class PresenceAvs {
  final String? id;
  final String avsId;
  final String? avsNom;
  final DateTime date;
  final DateTime? heureCheckIn;
  final DateTime? heureCheckOut;
  final StatutPresenceCoordonnateur statut;

  const PresenceAvs({
    this.id,
    required this.avsId,
    this.avsNom,
    required this.date,
    this.heureCheckIn,
    this.heureCheckOut,
    required this.statut,
  });
}
