import '../../domain/entities/medecin_entities.dart';

class DossierMedicalPatientModel {
  static DossierMedicalPatient fromJson(Map<String, dynamic> json) {
    return DossierMedicalPatient(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      nomComplet: '${json['prenom'] ?? ''} ${json['nom'] ?? ''}'.trim(),
      age: json['age'] ?? 0,
      pathologiePrincipale: json['pathologiePrincipale']?.toString() ?? 'Non renseignée',
      derniereConsultation: json['derniereConsultation'] != null ? DateTime.tryParse(json['derniereConsultation'].toString()) : null,
    );
  }
}

class TraitementModel {
  static Traitement fromJson(Map<String, dynamic> json) {
    final patient = json['patient'];
    return Traitement(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      patientNom: patient is Map ? '${patient['prenom'] ?? ''} ${patient['nom'] ?? ''}'.trim() : (json['patientNom'] ?? 'Patient'),
      medicament: json['medicament']?.toString() ?? '',
      posologie: json['posologie']?.toString() ?? '',
      dateEmission: DateTime.tryParse('${json['dateEmission'] ?? json['createdAt']}') ?? DateTime.now(),
      statut: statutTraitementFromString(json['statut']?.toString()),
    );
  }
}
