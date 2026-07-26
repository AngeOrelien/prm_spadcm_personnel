import '../../domain/entities/avs_entities.dart';

class PresenceModel {
  static Presence fromJson(Map<String, dynamic> json) {
    final geo = json['geolocalisationCheckIn'] ?? json['geolocalisation'];
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

/// Mapping d'une entrée d'annuaire (`GET /utilisateurs/role/:role`), utilisée
/// par la messagerie AVS pour lister coordonnateurs/médecins/administrateurs.
class PersonnelAnnuaireModel {
  static PersonnelAnnuaire fromJson(Map<String, dynamic> json) {
    return PersonnelAnnuaire(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      role: json['role']?.toString() ?? '',
      photoUrl: json['photoUrl'],
    );
  }
}
