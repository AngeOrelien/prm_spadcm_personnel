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
      contactUrgence: contactUrgence,
      telephone: json['telephone'],
      avsAssigneId: avsAssigne != null ? _idDe(avsAssigne) : null,
      avsAssigneNom: avsAssigne != null ? _nomCompletDepuis(avsAssigne) : null,
    );
  }

  /// Corps de requête pour `POST /api/patients`.
  static Map<String, dynamic> toCreateJson({
    required String nom,
    required String prenom,
    DateTime? dateNaissance,
    required String adresse,
    required String pathologie,
    List<String> antecedents = const [],
    List<String> allergies = const [],
    String? telephone,
  }) {
    return {
      'nom': nom,
      'prenom': prenom,
      if (dateNaissance != null) 'dateNaissance': dateNaissance.toIso8601String(),
      'adresse': adresse,
      'pathologie': pathologie,
      'antecedents': antecedents,
      'allergies': allergies,
      if (telephone != null && telephone.isNotEmpty) 'telephone': telephone,
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
    );
  }
}
