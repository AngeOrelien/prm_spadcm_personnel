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
      actif: json['actif'] ?? true,
      creeLe: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }

  static Map<String, dynamic> toCreateJson({
    required String nom,
    required String prenom,
    required String email,
    String? telephone,
    required RoleUtilisateur role,
  }) {
    const roles = {
      RoleUtilisateur.avs: 'avs',
      RoleUtilisateur.medecin: 'medecin',
      RoleUtilisateur.coordonnateur: 'coordonnateur',
      RoleUtilisateur.administrateur: 'administrateur',
      RoleUtilisateur.patientFamille: 'patient_famille',
    };
    return {
      'nom': nom,
      'prenom': prenom,
      'email': email,
      if (telephone != null && telephone.isNotEmpty) 'telephone': telephone,
      'role': roles[role],
    };
  }
}

class PaiementModel {
  static Paiement fromJson(Map<String, dynamic> json) {
    final patient = json['patient'] ?? json['souscription']?['patient'];
    final soin = json['soin'] ?? json['souscription']?['soin'];
    return Paiement(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      patientNom: patient is Map ? '${patient['prenom'] ?? ''} ${patient['nom'] ?? ''}'.trim() : (json['patientNom'] ?? 'Patient'),
      soinLibelle: soin is Map ? (soin['nom'] ?? '').toString() : (json['soinLibelle']?.toString() ?? 'Soin'),
      montant: (json['montant'] as num?)?.toDouble() ?? 0,
      date: DateTime.tryParse('${json['date'] ?? json['createdAt']}') ?? DateTime.now(),
      statut: statutPaiementFromString(json['statut']?.toString()),
    );
  }
}

class StatistiquesGlobalesModel {
  static StatistiquesGlobales fromJson(Map<String, dynamic> json) {
    return StatistiquesGlobales(
      totalPatients: json['totalPatients'] ?? 0,
      totalAvs: json['totalAvs'] ?? 0,
      rapportsEnRetard: json['rapportsEnRetard'] ?? 0,
      avsAbsentsAujourdhui: json['avsAbsentsAujourdhui'] ?? 0,
      montantPaiementsDuJour: (json['montantPaiementsDuJour'] as num?)?.toDouble() ?? 0,
      paiementsDuJour: json['paiementsDuJour'] ?? 0,
    );
  }
}
