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
    // Le backend utilise `role: 'patient'` (voir `models/Utilisateur.js`),
    // pas `patient_famille`.
    case 'patient':
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

/// Le backend (`models/Paiement.js`) utilise l'enum `initie | reussi | echoue
/// | rembourse` — `en_attente`/`confirme` n'existent pas côté API, seuls les
/// libellés d'affichage (`StatutPaiement.libelle`) restent en français.
StatutPaiement statutPaiementFromString(String? value) {
  switch (value) {
    case 'reussi':
      return StatutPaiement.confirme;
    case 'echoue':
      return StatutPaiement.echoue;
    case 'rembourse':
      return StatutPaiement.rembourse;
    case 'initie':
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

/// Une offre du catalogue de soins SPAD (`soins_catalogue` côté backend) —
/// ce que voient les patients/familles dans l'app, et que l'administrateur
/// gère depuis l'onglet "Ressources" > "Soins" (CRUD + médias).
class Soin {
  final String id;
  final String nom;
  final String? description;
  final double prix;
  final String devise;
  final String? frequenceVisites;
  final int visitesParSemaine;
  final List<String> prestationsIncluses;
  final int dureeEngagementJours;
  final String? imageCouverture;
  final List<String> images;
  final List<String> videos;
  final bool actif;
  final DateTime? creeLe;

  const Soin({
    required this.id,
    required this.nom,
    this.description,
    required this.prix,
    this.devise = 'XAF',
    this.frequenceVisites,
    this.visitesParSemaine = 7,
    this.prestationsIncluses = const [],
    this.dureeEngagementJours = 30,
    this.imageCouverture,
    this.images = const [],
    this.videos = const [],
    this.actif = true,
    this.creeLe,
  });
}

enum StatutSouscription { enAttentePaiement, active, expiree, annulee, resiliee }

StatutSouscription statutSouscriptionFromString(String? value) {
  switch (value) {
    case 'active':
      return StatutSouscription.active;
    case 'expiree':
      return StatutSouscription.expiree;
    case 'annulee':
      return StatutSouscription.annulee;
    case 'resiliee':
      return StatutSouscription.resiliee;
    case 'en_attente_paiement':
    default:
      return StatutSouscription.enAttentePaiement;
  }
}

String statutSouscriptionToApi(StatutSouscription statut) => switch (statut) {
      StatutSouscription.enAttentePaiement => 'en_attente_paiement',
      StatutSouscription.active => 'active',
      StatutSouscription.expiree => 'expiree',
      StatutSouscription.annulee => 'annulee',
      StatutSouscription.resiliee => 'resiliee',
    };

/// Une souscription réelle (`souscriptions` côté backend), distincte du
/// [Paiement] qui lui est éventuellement rattaché — un patient souscrit à un
/// [Soin] du catalogue, avec des dates de début/fin et un statut de cycle de
/// vie (voir `models/Souscription.js`).
class Souscription {
  final String id;
  final String patientNom;
  final String soinId;
  final String soinNom;
  final double? montant;
  final String souscripteurNom;
  final DateTime? dateDebut;
  final DateTime? dateFin;
  final StatutSouscription statut;
  final bool renouvellementAuto;
  final DateTime? creeLe;

  const Souscription({
    required this.id,
    required this.patientNom,
    required this.soinId,
    required this.soinNom,
    this.montant,
    required this.souscripteurNom,
    this.dateDebut,
    this.dateFin,
    this.statut = StatutSouscription.enAttentePaiement,
    this.renouvellementAuto = false,
    this.creeLe,
  });
}

/// Répartition, sur une période, du nombre de souscriptions par statut ou de
/// paiements par statut — brique commune à `statsPaiements` côté backend
/// (`GET /stats/paiements`), qui renvoie les deux répartitions dans le même
/// format `[{ _id: statut, total: n }]`.
class RepartitionParStatut {
  final String statut;
  final int total;

  const RepartitionParStatut({required this.statut, required this.total});
}

/// Rapport "Souscriptions & paiements" affiché dans l'onglet Statistiques —
/// alimente la nouvelle section demandée en plus des chiffres du jour déjà
/// présents dans [StatistiquesGlobales].
class StatistiquesPaiementsDetail {
  final double totalEncaisse;
  final List<RepartitionParStatut> souscriptionsParStatut;
  final List<RepartitionParStatut> paiementsParStatut;
  final DateTime periodeDebut;
  final DateTime periodeFin;

  const StatistiquesPaiementsDetail({
    this.totalEncaisse = 0,
    this.souscriptionsParStatut = const [],
    this.paiementsParStatut = const [],
    required this.periodeDebut,
    required this.periodeFin,
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
