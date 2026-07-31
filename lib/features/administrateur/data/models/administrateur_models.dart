import '../../domain/entities/administrateur_entities.dart';

class UtilisateurModel {
  static Utilisateur fromJson(Map<String, dynamic> json) {
    return Utilisateur(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      email: json['email'] ?? '',
      telephone: json['telephone'],
      role: roleUtilisateurFromString(json['role']?.toString()),
      // Le backend expose `estActif` (voir `models/Utilisateur.js`) ;
      // `actif` n'existe pas côté API.
      actif: json['estActif'] ?? true,
      creeLe: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }

  static Map<String, dynamic> toCreateJson({
    required String nom,
    required String prenom,
    required String email,
    required String telephone,
    required String motDePasse,
    required RoleUtilisateur role,
  }) {
    const roles = {
      RoleUtilisateur.avs: 'avs',
      RoleUtilisateur.medecin: 'medecin',
      RoleUtilisateur.coordonnateur: 'coordonnateur',
      RoleUtilisateur.administrateur: 'administrateur',
    };
    return {
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'telephone': telephone,
      'motDePasse': motDePasse,
      'role': roles[role],
    };
  }

  /// Corps pour `PATCH /api/utilisateurs/:id` (édition) — pas de champ
  /// `role` : le backend ne prévoit pas de changement de rôle a posteriori
  /// (voir `utilisateurController.modifierUtilisateur`, qui accepte
  /// simplement les champs modifiables du modèle sans validation de rôle
  /// spécifique ; on reste volontairement conservateur côté app).
  static Map<String, dynamic> toUpdateJson({
    required String nom,
    required String prenom,
    required String email,
    required String telephone,
  }) {
    return {'nom': nom, 'prenom': prenom, 'email': email, 'telephone': telephone};
  }
}

class PaiementModel {
  static Paiement fromJson(Map<String, dynamic> json) {
    // `listerPaiements` (côté backend) peuple `payeurId` (nom/prenom/téléphone
    // du patient/famille qui a payé) et `souscriptionId`, mais ne peuple pas
    // le soin souscrit derrière la souscription (pas de `.populate` imbriqué)
    // — on retombe donc sur la référence externe de la transaction, toujours
    // disponible, plutôt que sur un libellé de soin qu'on ne peut pas obtenir
    // sans modifier le backend.
    final payeur = json['payeurId'];
    final reference = json['referenceExterne']?.toString();
    return Paiement(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      patientNom: payeur is Map ? '${payeur['prenom'] ?? ''} ${payeur['nom'] ?? ''}'.trim() : 'Patient',
      soinLibelle: (reference != null && reference.isNotEmpty) ? 'Réf. $reference' : 'Souscription',
      montant: (json['montant'] as num?)?.toDouble() ?? 0,
      date: DateTime.tryParse('${json['dateTransaction'] ?? json['createdAt']}') ?? DateTime.now(),
      statut: statutPaiementFromString(json['statut']?.toString()),
    );
  }
}

class SoinModel {
  static Soin fromJson(Map<String, dynamic> json) {
    return Soin(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      nom: json['nom'] ?? '',
      description: json['description'],
      prix: (json['prix'] as num?)?.toDouble() ?? 0,
      devise: json['devise'] ?? 'XAF',
      frequenceVisites: json['frequenceVisites'],
      visitesParSemaine: json['visitesParSemaine'] ?? 7,
      prestationsIncluses: (json['prestationsIncluses'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      dureeEngagementJours: json['dureeEngagementJours'] ?? 30,
      imageCouverture: json['imageCouverture'],
      images: (json['images'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      videos: (json['videos'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      actif: json['actif'] ?? true,
      creeLe: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }

  /// Corps pour `POST /api/soins` et `PATCH /api/soins/:id` — mêmes champs
  /// dans les deux cas (le backend accepte un `PATCH` partiel).
  static Map<String, dynamic> toJson({
    required String nom,
    String? description,
    required double prix,
    String? frequenceVisites,
    int visitesParSemaine = 7,
    List<String> prestationsIncluses = const [],
    int dureeEngagementJours = 30,
  }) {
    return {
      'nom': nom,
      if (description != null && description.isNotEmpty) 'description': description,
      'prix': prix,
      if (frequenceVisites != null && frequenceVisites.isNotEmpty) 'frequenceVisites': frequenceVisites,
      'visitesParSemaine': visitesParSemaine,
      'prestationsIncluses': prestationsIncluses,
      'dureeEngagementJours': dureeEngagementJours,
    };
  }
}

class SouscriptionModel {
  static Souscription fromJson(Map<String, dynamic> json) {
    final soin = json['soinId'];
    final patient = json['patientId'];
    final souscripteur = json['souscripteurId'];
    final paiement = json['paiementId'];
    final patientInfo = json['patientInfo'];

    String nomPatient = 'Patient';
    if (patient is Map && (patient['nom'] != null || patient['prenom'] != null)) {
      nomPatient = '${patient['prenom'] ?? ''} ${patient['nom'] ?? ''}'.trim();
    } else if (patientInfo is Map && (patientInfo['nom'] != null || patientInfo['prenom'] != null)) {
      nomPatient = '${patientInfo['prenom'] ?? ''} ${patientInfo['nom'] ?? ''}'.trim();
    }

    return Souscription(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      patientNom: nomPatient.isEmpty ? 'Patient' : nomPatient,
      soinId: soin is Map ? (soin['_id'] ?? '').toString() : (soin ?? '').toString(),
      soinNom: soin is Map ? (soin['nom'] ?? 'Soin') : 'Soin',
      montant: paiement is Map ? (paiement['montant'] as num?)?.toDouble() : null,
      souscripteurNom: souscripteur is Map ? '${souscripteur['prenom'] ?? ''} ${souscripteur['nom'] ?? ''}'.trim() : '—',
      dateDebut: json['dateDebut'] != null ? DateTime.tryParse(json['dateDebut'].toString()) : null,
      dateFin: json['dateFin'] != null ? DateTime.tryParse(json['dateFin'].toString()) : null,
      statut: statutSouscriptionFromString(json['statut']?.toString()),
      renouvellementAuto: json['renouvellementAuto'] ?? false,
      creeLe: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }

  /// Corps pour `PATCH /api/souscriptions/:id` (édition back-office) —
  /// whitelist alignée sur `souscriptionController.modifierSouscription`.
  static Map<String, dynamic> toUpdateJson({
    DateTime? dateDebut,
    DateTime? dateFin,
    bool? renouvellementAuto,
    StatutSouscription? statut,
  }) {
    return {
      if (dateDebut != null) 'dateDebut': dateDebut.toIso8601String(),
      if (dateFin != null) 'dateFin': dateFin.toIso8601String(),
      if (renouvellementAuto != null) 'renouvellementAuto': renouvellementAuto,
      if (statut != null) 'statut': statutSouscriptionToApi(statut),
    };
  }
}

class StatistiquesPaiementsDetailModel {
  static StatistiquesPaiementsDetail fromJson(Map<String, dynamic> json) {
    List<RepartitionParStatut> parseRepartition(dynamic liste) {
      if (liste is! List) return const [];
      return liste
          .map((e) => RepartitionParStatut(statut: (e['_id'] ?? '—').toString(), total: (e['total'] as num?)?.toInt() ?? 0))
          .toList();
    }

    final periode = json['periode'] as Map<String, dynamic>?;
    return StatistiquesPaiementsDetail(
      totalEncaisse: (json['totalEncaisse'] as num?)?.toDouble() ?? 0,
      souscriptionsParStatut: parseRepartition(json['souscriptionsParStatut']),
      paiementsParStatut: parseRepartition(json['paiementsParStatut']),
      periodeDebut: DateTime.tryParse('${periode?['dateDebut']}') ?? DateTime.now().subtract(const Duration(days: 30)),
      periodeFin: DateTime.tryParse('${periode?['dateFin']}') ?? DateTime.now(),
    );
  }
}

class StatistiquesGlobalesModel {
  static StatistiquesGlobales fromJson(Map<String, dynamic> json) {
    return StatistiquesGlobales(
      totalPatients: json['totalPatients'] ?? 0,
      totalAvs: json['totalAvs'] ?? 0,
      // `/stats/operationnel` renvoie `rapportsEnRetardAujourdhui`.
      rapportsEnRetard: json['rapportsEnRetardAujourdhui'] ?? 0,
      avsAbsentsAujourdhui: json['avsAbsentsAujourdhui'] ?? 0,
      // Montant réellement encaissé aujourd'hui : vient de `/stats/paiements`
      // (`totalEncaisse`), combiné côté datasource — `/operationnel` ne
      // fournit qu'un compteur (`paiementsAujourdhui`), pas de montant.
      montantPaiementsDuJour: (json['totalEncaisse'] as num?)?.toDouble() ?? 0,
      paiementsDuJour: json['paiementsAujourdhui'] ?? 0,
    );
  }
}
