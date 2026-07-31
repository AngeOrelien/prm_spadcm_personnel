import '../../domain/entities/coordonnateur_entities.dart';

/// Mapping JSON (backend `prm-spad-backend`) -> entités du feature
/// Coordonnateur. Un seul fichier pour les 4 modèles car ils sont petits et
/// très liés entre eux (ex: `AssignationModel` référence patient + AVS).

String _idDe(dynamic valeur) {
  if (valeur == null) return '';
  if (valeur is Map) return (valeur['_id'] ?? '').toString();
  return valeur.toString();
}

String? _nomCompletDepuis(dynamic valeur) {
  if (valeur is Map) {
    final prenom = valeur['prenom'] ?? '';
    final nom = valeur['nom'] ?? '';
    final complet = '$prenom $nom'.trim();
    return complet.isEmpty ? null : complet;
  }
  return null;
}

class AvsModel {
  static Avs fromJson(Map<String, dynamic> json) {
    return Avs(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      telephone: json['telephone'] ?? '',
      email: json['email'],
      statut: statutAvsFromString(json['disponibilite']?.toString()),
      patientsAssignes: (json['patientsAssignes'] ?? 0) is int
          ? json['patientsAssignes'] ?? 0
          : int.tryParse('${json['patientsAssignes']}') ?? 0,
      // `photoUrl` n'existe pas encore sur le modèle backend `Utilisateur` —
      // lu quand même par anticipation (voir BACKEND_TODO.md).
      photoUrl: json['photoUrl'],
    );
  }
}

class PatientModel {
  static Patient fromJson(Map<String, dynamic> json) {
    final avsAssigne = json['avsAssigne'];
    DateTime? dateNaissance;
    if (json['dateNaissance'] != null) {
      dateNaissance = DateTime.tryParse(json['dateNaissance'].toString());
    }

    final contact = json['contactUrgence'];
    ContactUrgence? contactUrgence;
    if (contact is Map) {
      contactUrgence = ContactUrgence(
        nom: contact['nom'],
        lien: contact['lien'],
        telephone: contact['telephone'],
      );
    }

    return Patient(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      age: json['age'] is int ? json['age'] as int : int.tryParse('${json['age']}'),
      dateNaissance: dateNaissance,
      adresse: json['adresse'] ?? '',
      pathologie: json['pathologie'] ?? '',
      antecedents: (json['antecedents'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      allergies: (json['allergies'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      difficultesMobilite: (json['difficultesMobilite'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      contactUrgence: contactUrgence,
      telephone: json['telephone'],
      avsAssigneId: avsAssigne != null ? _idDe(avsAssigne) : null,
      avsAssigneNom: avsAssigne != null ? _nomCompletDepuis(avsAssigne) : null,
      photoUrl: json['photoUrl'],
      email: json['email'],
      compteUtilisateurId: json['compteUtilisateurId'] != null ? _idDe(json['compteUtilisateurId']) : null,
    );
  }

  /// Corps de requête pour `POST /api/patients`.
  ///
  /// [email] / [motDePasse] : champs saisis dans le formulaire de création
  /// pour donner tout de suite un accès de connexion au patient/à la
  /// famille. ⚠️ Le backend actuel (`creerPatient`) ne fait que
  /// `Patient.create(req.body)` : il ignore ces deux champs et ne crée pas
  /// de compte `Utilisateur` lié. Il faudra étendre la route pour créer ce
  /// compte (rôle `patient`, `compteUtilisateurId` renseigné) — voir
  /// `BACKEND_TODO.md`. On les envoie déjà pour ne rien avoir à changer côté
  /// app le jour où le backend les prendra en charge.
  static Map<String, dynamic> toCreateJson({
    required String nom,
    required String prenom,
    DateTime? dateNaissance,
    required String adresse,
    required String pathologie,
    List<String> antecedents = const [],
    List<String> allergies = const [],
    List<String> difficultesMobilite = const [],
    String? telephone,
    String? email,
    String? motDePasse,
  }) {
    return {
      'nom': nom,
      'prenom': prenom,
      if (dateNaissance != null) 'dateNaissance': dateNaissance.toIso8601String(),
      'adresse': adresse,
      'pathologie': pathologie,
      'antecedents': antecedents,
      'allergies': allergies,
      'difficultesMobilite': difficultesMobilite,
      if (telephone != null && telephone.isNotEmpty) 'telephone': telephone,
      if (email != null && email.isNotEmpty) 'email': email,
      if (motDePasse != null && motDePasse.isNotEmpty) 'motDePasse': motDePasse,
    };
  }
}

class AffectationModel {
  static Affectation fromJson(Map<String, dynamic> json) {
    final patient = json['patientId'];
    final avs = json['avsId'];

    return Affectation(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      patientId: _idDe(patient),
      avsId: _idDe(avs),
      patientNom: _nomCompletDepuis(patient),
      avsNom: _nomCompletDepuis(avs),
      frequence: json['frequence'] ?? '',
      depuisLe: DateTime.tryParse('${json['dateDebut']}') ?? DateTime.now(),
      finLe: json['dateFin'] != null ? DateTime.tryParse(json['dateFin'].toString()) : null,
      active: (json['statut'] ?? 'active') == 'active',
    );
  }
}

class RapportModel {
  static StatutRapport _statutDepuis(Map<String, dynamic> json) {
    if (json['valide'] == true) return StatutRapport.valide;
    if (json['motifRejet'] != null && '${json['motifRejet']}'.isNotEmpty) return StatutRapport.rejete;
    return StatutRapport.enAttente;
  }

  static String _resumeDepuis(Map<String, dynamic> json) {
    final parties = [json['plainte'], json['observations'], json['conclusion']]
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty);
    if (parties.isEmpty) return 'Aucun résumé fourni.';
    return parties.first;
  }

  static RapportAvs fromJson(Map<String, dynamic> json) {
    return RapportAvs(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      avsId: _idDe(json['avsId']),
      patientId: _idDe(json['patientId']),
      date: DateTime.tryParse('${json['date']}') ?? DateTime.now(),
      resume: _resumeDepuis(json),
      statut: _statutDepuis(json),
      motifRejet: json['motifRejet'],
      statutRemise: statutRemiseFromString(json['statutRemise']?.toString()),
    );
  }
}

/// Mapping `Conversation` (voir `messagerieController.js`). [currentUserId]
/// sert à déterminer qui est "l'autre" participant (celui à afficher comme
/// interlocuteur dans la liste des fils de discussion).
class ConversationModel {
  static Conversation fromJson(Map<String, dynamic> json, String currentUserId) {
    final participants = (json['participantsIds'] as List?) ?? const [];
    Map? autre;
    for (final p in participants) {
      if (p is Map && _idDe(p) != currentUserId) {
        autre = p;
        break;
      }
    }
    final patientContexte = json['patientContexteId'];

    return Conversation(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      nom: json['nom'],
      interlocuteurId: autre != null ? _idDe(autre) : null,
      interlocuteurNom: autre != null ? _nomCompletDepuis(autre) : null,
      interlocuteurSousTitre: autre != null ? (autre['role']?.toString()) : null,
      dernierMessage: json['dernierMessage'],
      dernierMessageAt: json['dernierMessageAt'] != null ? DateTime.tryParse(json['dernierMessageAt'].toString()) : null,
      nonLue: patientContexte == null ? false : false,
    );
  }
}

/// Mapping `Message` (voir `messagerieController.js`). [currentUserId] sert
/// à déterminer si le message vient de moi (bulle à droite) ou non.
class MessageModel {
  static MessageConversation fromJson(Map<String, dynamic> json, String currentUserId) {
    final expediteur = json['expediteurId'];
    final expediteurId = _idDe(expediteur);
    return MessageConversation(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      conversationId: _idDe(json['conversationId']),
      expediteurId: expediteurId,
      expediteurNom: _nomCompletDepuis(expediteur),
      contenu: json['contenu'] ?? '',
      creeLe: DateTime.tryParse('${json['createdAt']}') ?? DateTime.now(),
      deMoi: expediteurId == currentUserId,
    );
  }
}

/// Mapping `Presence` (check-in/check-out, voir `presenceController.js`).
class PresenceCoordonnateurModel {
  static PresenceAvs fromJson(Map<String, dynamic> json) {
    final avs = json['avsId'];
    return PresenceAvs(
      id: (json['_id'] ?? json['id'])?.toString(),
      avsId: _idDe(avs),
      avsNom: _nomCompletDepuis(avs),
      date: DateTime.tryParse('${json['date']}') ?? DateTime.now(),
      heureCheckIn: json['heureCheckIn'] != null ? DateTime.tryParse(json['heureCheckIn'].toString()) : null,
      heureCheckOut: json['heureCheckOut'] != null ? DateTime.tryParse(json['heureCheckOut'].toString()) : null,
      statut: statutPresenceCoordonnateurFromString(json['statut']?.toString()),
    );
  }

  /// Mapping de la "vue d'ensemble du jour" (`/api/presences/aujourdhui/vue-ensemble`),
  /// dont la forme est légèrement différente (`{avs, statut, heureCheckIn, heureCheckOut}`
  /// au lieu d'un vrai document `Presence`).
  static PresenceAvs fromVueEnsembleJson(Map<String, dynamic> json, DateTime date) {
    final avs = json['avs'];
    return PresenceAvs(
      avsId: _idDe(avs),
      avsNom: _nomCompletDepuis(avs),
      date: date,
      heureCheckIn: json['heureCheckIn'] != null ? DateTime.tryParse(json['heureCheckIn'].toString()) : null,
      heureCheckOut: json['heureCheckOut'] != null ? DateTime.tryParse(json['heureCheckOut'].toString()) : null,
      statut: statutPresenceCoordonnateurFromString(json['statut']?.toString()),
    );
  }
}
