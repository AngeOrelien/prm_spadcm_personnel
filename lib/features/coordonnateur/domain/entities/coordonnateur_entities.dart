/// Entités du feature Coordonnateur.
///
/// NOTE : tant que les endpoints backend correspondants n'existent pas côté
/// app Personnel, ces entités sont alimentées par des données factices dans
/// `coordonnateur_providers.dart` (clairement marquées TODO). La UI, elle,
/// est déjà branchée sur ces types : brancher le vrai repository plus tard
/// ne demandera de changer que le provider, pas les pages.

enum StatutAvs { disponible, enIntervention, absent }

class Avs {
  final String id;
  final String nom;
  final String prenom;
  final String telephone;
  final StatutAvs statut;
  final int patientsAssignes;

  const Avs({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.telephone,
    required this.statut,
    required this.patientsAssignes,
  });

  String get nomComplet => '$prenom $nom';
}

class Patient {
  final String id;
  final String nom;
  final String prenom;
  final int age;
  final String adresse;
  final String pathologie;
  final String? avsAssigneId;

  const Patient({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.age,
    required this.adresse,
    required this.pathologie,
    this.avsAssigneId,
  });

  String get nomComplet => '$prenom $nom';
}

class Affectation {
  final String id;
  final String patientId;
  final String avsId;
  final String frequence;
  final DateTime depuisLe;

  const Affectation({
    required this.id,
    required this.patientId,
    required this.avsId,
    required this.frequence,
    required this.depuisLe,
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

  const RapportAvs({
    required this.id,
    required this.avsId,
    required this.patientId,
    required this.date,
    required this.resume,
    this.statut = StatutRapport.enAttente,
  });

  RapportAvs copierAvec({StatutRapport? statut}) {
    return RapportAvs(
      id: id,
      avsId: avsId,
      patientId: patientId,
      date: date,
      resume: resume,
      statut: statut ?? this.statut,
    );
  }
}
