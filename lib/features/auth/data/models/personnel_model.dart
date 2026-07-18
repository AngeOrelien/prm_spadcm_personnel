import '../../domain/entities/personnel.dart';

/// Reflète exactement l'objet `utilisateur` renvoyé par le backend
/// (routes /verify-login-otp et /me). Garder ce mapping ici évite que le
/// reste de l'app dépende du format JSON du backend.
class PersonnelModel extends Personnel {
  const PersonnelModel({
    required super.id,
    required super.nom,
    required super.prenom,
    required super.email,
    required super.role,
  });

  factory PersonnelModel.fromJson(Map<String, dynamic> json) {
    return PersonnelModel(
      id: json['id'] as String? ?? json['_id'] as String,
      nom: json['nom'] as String,
      prenom: json['prenom'] as String,
      email: json['email'] as String,
      role: roleFromString(json['role'] as String),
    );
  }
}
