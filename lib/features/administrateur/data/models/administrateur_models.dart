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
