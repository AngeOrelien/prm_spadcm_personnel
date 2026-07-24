/// Entités du feature Administrateur : utilisateurs (tous rôles), paiements,
/// statistiques globales.

enum RoleUtilisateur { avs, medecin, coordonnateur, administrateur, patientFamille }

RoleUtilisateur roleUtilisateurFromString(String? value) {
  switch (value) {
    case 'avs':
      return RoleUtilisateur.avs;
    case 'medecin':
      return RoleUtilisateur.medecin;
    case 'coordonnateur':
      return RoleUtilisateur.coordonnateur;
    case 'administrateur':
      return RoleUtilisateur.administrateur;
    case 'patient_famille':
    default:
      return RoleUtilisateur.patientFamille;
  }
}

class Utilisateur {
  final String id;
  final String nom;
  final String prenom;
  final String email;
  final String? telephone;
  final RoleUtilisateur role;
  final bool actif;
  final DateTime? creeLe;

  const Utilisateur({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    this.telephone,
    required this.role,
    this.actif = true,
    this.creeLe,
  });

  String get nomComplet => '$prenom $nom';

  Utilisateur copierAvec({bool? actif}) => Utilisateur(
        id: id,
        nom: nom,
        prenom: prenom,
        email: email,
        telephone: telephone,
        role: role,
        actif: actif ?? this.actif,
        creeLe: creeLe,
      );
}

enum StatutPaiement { enAttente, confirme, echoue, rembourse }

StatutPaiement statutPaiementFromString(String? value) {
  switch (value) {
    case 'confirme':
      return StatutPaiement.confirme;
    case 'echoue':
      return StatutPaiement.echoue;
    case 'rembourse':
      return StatutPaiement.rembourse;
    case 'en_attente':
    default:
      return StatutPaiement.enAttente;
  }
}

class Paiement {
  final String id;
  final String patientNom;
  final String soinLibelle;
  final double montant;
  final DateTime date;
  final StatutPaiement statut;

  const Paiement({
    required this.id,
    required this.patientNom,
    required this.soinLibelle,
    required this.montant,
    required this.date,
    this.statut = StatutPaiement.enAttente,
  });
}

/// Statistiques globales affichées sur le tableau de bord de l'admin.
class StatistiquesGlobales {
  final int totalPatients;
  final int totalAvs;
  final int rapportsEnRetard;
  final int avsAbsentsAujourdhui;
  final double montantPaiementsDuJour;
  final int paiementsDuJour;

  const StatistiquesGlobales({
    this.totalPatients = 0,
    this.totalAvs = 0,
    this.rapportsEnRetard = 0,
    this.avsAbsentsAujourdhui = 0,
    this.montantPaiementsDuJour = 0,
    this.paiementsDuJour = 0,
  });
}
