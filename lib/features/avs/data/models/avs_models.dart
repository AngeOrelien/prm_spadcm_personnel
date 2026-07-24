import '../../domain/entities/avs_entities.dart';

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

class VisitePlanifieeModel {
  static VisitePlanifiee fromJson(Map<String, dynamic> json) {
    final patient = json['patient'];
    return VisitePlanifiee(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      patientId: _idDe(json['patientId'] ?? patient),
      patientNom: _nomCompletDepuis(patient) ?? json['patientNom'] ?? 'Patient',
      adressePatient: (patient is Map ? patient['adresse'] : json['adresse'])?.toString() ?? '',
      date: DateTime.tryParse('${json['date']}') ?? DateTime.now(),
      creneauLibelle: json['creneauLibelle']?.toString() ?? json['frequence']?.toString() ?? '',
      terminee: json['terminee'] == true,
    );
  }
}

class PresenceModel {
  static Presence fromJson(Map<String, dynamic> json) {
    final geo = json['geolocalisation'];
    return Presence(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      date: DateTime.tryParse('${json['date']}') ?? DateTime.now(),
      heureCheckIn: json['heureCheckIn'] != null ? DateTime.tryParse('${json['heureCheckIn']}') : null,
      heureCheckOut: json['heureCheckOut'] != null ? DateTime.tryParse('${json['heureCheckOut']}') : null,
      latitude: geo is Map ? (geo['latitude'] as num?)?.toDouble() : null,
      longitude: geo is Map ? (geo['longitude'] as num?)?.toDouble() : null,
      statut: statutPresenceFromString(json['statut']?.toString()),
    );
  }
}
