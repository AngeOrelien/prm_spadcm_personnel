/// Rôles possibles pour un compte de l'app Personnel.
/// (Le rôle "patient" existe côté backend mais concerne l'autre app.)
enum RolePersonnel { avs, medecin, coordonnateur, administrateur }

RolePersonnel roleFromString(String value) {
  switch (value) {
    case 'avs':
      return RolePersonnel.avs;
    case 'medecin':
      return RolePersonnel.medecin;
    case 'coordonnateur':
      return RolePersonnel.coordonnateur;
    case 'administrateur':
      return RolePersonnel.administrateur;
    default:
      throw ArgumentError('Rôle personnel inconnu: $value');
  }
}

class Personnel {
  final String id;
  final String nom;
  final String prenom;
  final String email;
  final RolePersonnel role;

  const Personnel({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.role,
  });

  String get nomComplet => '$prenom $nom';
}
