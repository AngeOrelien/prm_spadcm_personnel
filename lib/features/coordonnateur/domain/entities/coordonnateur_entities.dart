/// Entités du feature Coordonnateur.
///
/// Alignées sur les vraies réponses du backend `prm-spad-backend`
/// (`/api/patients`, `/api/utilisateurs/avs/equipe`, `/api/assignations`,
/// `/api/rapports`) — voir `data/models/coordonnateur_models.dart` pour le
/// mapping JSON -> entité.

enum StatutAvs { disponible, enIntervention, absent }

StatutAvs statutAvsFromString(String? value) {
  switch (value) {
    case 'en_intervention':
      return StatutAvs.enIntervention;
    case 'absent':
      return StatutAvs.absent;
    case 'disponible':
    default:
      return StatutAvs.disponible;
  }
}

String statutAvsToApi(StatutAvs statut) {
  switch (statut) {
    case StatutAvs.enIntervention:
      return 'en_intervention';
    case StatutAvs.absent:
      return 'absent';
    case StatutAvs.disponible:
      return 'disponible';
  }
}

class ContactUrgence {
  final String? nom;
  final String? lien;
  final String? telephone;

  const ContactUrgence({this.nom, this.lien, this.telephone});

  bool get estVide => (nom == null || nom!.isEmpty) && (telephone == null || telephone!.isEmpty);
}

class Avs {
  final String id;
  final String nom;
  final String prenom;
  final String telephone;
  final String? email;
  final StatutAvs statut;
  final int patientsAssignes;

  const Avs({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.telephone,
    this.email,
    required this.statut,
    required this.patientsAssignes,
  });

  String get nomComplet => '$prenom $nom';
}

class Patient {
  final String id;
  final String nom;
  final String prenom;
  final int? age;
  final DateTime? dateNaissance;
  final String adresse;
  final String pathologie;
  final List<String> antecedents;
  final List<String> allergies;
  final ContactUrgence? contactUrgence;
  final String? telephone;
  final String? avsAssigneId;
  final String? avsAssigneNom;

  const Patient({
    required this.id,
    required this.nom,
    required this.prenom,
    this.age,
    this.dateNaissance,
    required this.adresse,
    required this.pathologie,
    this.antecedents = const [],
    this.allergies = const [],
    this.contactUrgence,
    this.telephone,
    this.avsAssigneId,
    this.avsAssigneNom,
  });

  String get nomComplet => '$prenom $nom';
}

class Affectation {
  final String id;
  final String patientId;
  final String avsId;
  final String? patientNom;
  final String? avsNom;
  final String frequence;
  final DateTime depuisLe;
  final DateTime? finLe;
  final bool active;

  const Affectation({
    required this.id,
    required this.patientId,
    required this.avsId,
    this.patientNom,
    this.avsNom,
    required this.frequence,
    required this.depuisLe,
    this.finLe,
    this.active = true,
  });
}

enum StatutRapport { enAttente, valide, rejete }

class RapportAvs {
  final String id;
  final String avsId;
  final String patientId;
  final DateTime date;
  final String resume;
  final StatutRapport statut;
  final String? motifRejet;

  const RapportAvs({
    required this.id,
    required this.avsId,
    required this.patientId,
    required this.date,
    required this.resume,
    this.statut = StatutRapport.enAttente,
    this.motifRejet,
  });

  RapportAvs copierAvec({StatutRapport? statut}) {
    return RapportAvs(
      id: id,
      avsId: avsId,
      patientId: patientId,
      date: date,
      resume: resume,
      statut: statut ?? this.statut,
      motifRejet: motifRejet,
    );
  }
}
