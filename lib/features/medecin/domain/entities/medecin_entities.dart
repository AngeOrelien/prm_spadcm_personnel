/// Entités du feature Médecin (rôle en étude — voir README §7.2 : accès
/// limité aux dossiers médicaux des patients qui lui sont liés et aux
/// prescriptions/traitements).

class DossierMedicalPatient {
  final String id;
  final String nomComplet;
  final int age;
  final String pathologiePrincipale;
  final DateTime? derniereConsultation;
  // Id du compte de connexion (`Utilisateur`, rôle `patient`) lié à cette
  // fiche — voir le commentaire équivalent sur `Patient.compteUtilisateurId`
  // (`coordonnateur_entities.dart`) : nécessaire pour ouvrir une vraie
  // conversation avec ce patient, `null` si aucun compte n'y est encore lié.
  final String? compteUtilisateurId;

  const DossierMedicalPatient({
    required this.id,
    required this.nomComplet,
    required this.age,
    required this.pathologiePrincipale,
    this.derniereConsultation,
    this.compteUtilisateurId,
  });
}

enum StatutTraitement { actif, termine, suspendu }

StatutTraitement statutTraitementFromString(String? value) {
  switch (value) {
    case 'termine':
      return StatutTraitement.termine;
    case 'suspendu':
      return StatutTraitement.suspendu;
    case 'actif':
    default:
      return StatutTraitement.actif;
  }
}

class Traitement {
  final String id;
  final String patientNom;
  final String medicament;
  final String posologie;
  final DateTime dateEmission;
  final StatutTraitement statut;

  const Traitement({
    required this.id,
    required this.patientNom,
    required this.medicament,
    required this.posologie,
    required this.dateEmission,
    this.statut = StatutTraitement.actif,
  });
}
