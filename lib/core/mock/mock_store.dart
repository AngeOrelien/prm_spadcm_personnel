import '../../features/administrateur/domain/entities/administrateur_entities.dart' as admin_entities;
import '../../features/avs/domain/entities/avs_entities.dart';
import '../../features/coordonnateur/domain/entities/coordonnateur_entities.dart';
import '../../features/medecin/domain/entities/medecin_entities.dart';

/// Jeu de données quasi-statique et **partagé** entre les 4 datasources
/// personnel (`AVS`, `Coordonnateur`, `Administrateur`, `Médecin`) tant que
/// `AppConfig.useMockData` est actif.
///
/// "Quasi-statique" : les listes sont seedées une seule fois par lancement
/// d'app (pas régénérées à chaque appel), et les actions (check-in, création
/// de patient, validation de rapport...) mutent réellement ces listes — ça
/// se comporte comme un vrai backend en mémoire, juste sans persistance au
/// redémarrage. Les dates sont calculées par rapport à `DateTime.now()` pour
/// que la démo reste cohérente quel que soit le jour où elle tourne.
///
/// Contexte volontairement ancré à Yaoundé (quartiers réels) pour coller au
/// terrain décrit dans le README (SPAD Cameroun / MySPAD Pro).
class MockStore {
  MockStore._();

  static bool _seeded = false;

  // --- Référentiels ---------------------------------------------------

  static late List<_AvsSeed> avsSeeds;
  static late List<_PatientSeed> patientSeeds;
  static late List<Affectation> affectations;
  static late List<RapportAvs> rapports;
  static late List<Presence> presences; // toutes les présences, tous AVS confondus
  static late List<admin_entities.Utilisateur> utilisateurs;
  static late List<admin_entities.Paiement> paiements;
  static late List<Traitement> traitements;

  static void _seedIfNeeded() {
    if (_seeded) return;
    _seeded = true;

    final now = DateTime.now();
    DateTime jour(int offsetJours, [int h = 8, int m = 0]) =>
        DateTime(now.year, now.month, now.day - offsetJours, h, m);

    // --- AVS (personnel de terrain) ---
    avsSeeds = [
      _AvsSeed('avs-01', 'Mballa', 'Solange', '690 12 34 56', 'solange.mballa@myspad.cm', StatutAvs.enIntervention, 'Nkolbisson'),
      _AvsSeed('avs-02', 'Etoundi', 'Jean-Paul', '677 22 45 10', 'jp.etoundi@myspad.cm', StatutAvs.disponible, 'Bastos'),
      _AvsSeed('avs-03', 'Ngo Bilong', 'Chantal', '699 88 10 33', 'chantal.ngobilong@myspad.cm', StatutAvs.enIntervention, 'Mendong'),
      _AvsSeed('avs-04', 'Fouda', 'Bertrand', '655 40 19 82', 'bertrand.fouda@myspad.cm', StatutAvs.absent, 'Emana'),
      _AvsSeed('avs-05', 'Abena', 'Marceline', '691 77 05 21', 'marceline.abena@myspad.cm', StatutAvs.disponible, 'Ngousso'),
    ];

    // --- Patients (fiches SPAD) ---
    patientSeeds = [
      _PatientSeed('pat-01', 'Ondoa', 'Pierre', jour(365 * 78), 'Bastos, Yaoundé', 'Diabète type 2 + HTA',
          ['Diabète type 2', 'Hypertension artérielle'], ['Pénicilline'], ['Marche assistée'], '677 90 12 34', 'avs-01'),
      _PatientSeed('pat-02', 'Assam', 'Marthe', jour(365 * 82), 'Nkolbisson, Yaoundé', 'Maladie de Parkinson',
          ['Parkinson', 'Arthrose du genou'], [], ['Fauteuil roulant'], '699 45 67 89', 'avs-01'),
      _PatientSeed('pat-03', 'Biya', 'Andre', jour(365 * 74), 'Mendong, Yaoundé', 'HTA sévère',
          ['Hypertension artérielle', 'Insuffisance rénale légère'], ['Aspirine'], [], '655 12 90 44', 'avs-03'),
      _PatientSeed('pat-04', 'Ngo Mbarga', 'Beatrice', jour(365 * 69), 'Emana, Yaoundé', 'Diabète type 2',
          ['Diabète type 2'], [], ['Marche assistée'], '691 33 22 11', 'avs-04'),
      _PatientSeed('pat-05', 'Mvondo', 'Joseph', jour(365 * 85), 'Bastos, Yaoundé', 'Séquelles d\'AVC',
          ['AVC (2023)', 'Hypertension artérielle'], [], ['Hémiplégie droite', 'Fauteuil roulant'], '677 65 43 21', 'avs-02'),
      _PatientSeed('pat-06', 'Essomba', 'Colette', jour(365 * 71), 'Ngousso, Yaoundé', 'Arthrose diffuse',
          ['Arthrose', 'Ostéoporose'], ['Iode'], ['Marche assistée'], '699 11 22 33', 'avs-05'),
      _PatientSeed('pat-07', 'Nkolo', 'Emmanuel', jour(365 * 79), 'Mendong, Yaoundé', 'Diabète type 1',
          ['Diabète type 1'], [], [], '655 77 88 99', 'avs-03'),
      _PatientSeed('pat-08', 'Owona', 'Suzanne', jour(365 * 88), 'Nkolbisson, Yaoundé', 'Démence légère + HTA',
          ['Démence légère', 'Hypertension artérielle'], [], ['Surveillance rapprochée'], '691 44 55 66', null),
    ];

    // --- Affectations (planning AVS <-> patient) ---
    affectations = [
      _affectation('aff-01', 'pat-01', 'avs-01', 'quotidienne', jour(40)),
      _affectation('aff-02', 'pat-02', 'avs-01', '3x/semaine', jour(30)),
      _affectation('aff-03', 'pat-03', 'avs-03', 'quotidienne', jour(55)),
      _affectation('aff-04', 'pat-04', 'avs-04', '3x/semaine', jour(20)),
      _affectation('aff-05', 'pat-05', 'avs-02', 'quotidienne', jour(60)),
      _affectation('aff-06', 'pat-06', 'avs-05', '2x/semaine', jour(15)),
      _affectation('aff-07', 'pat-07', 'avs-03', 'quotidienne', jour(10)),
    ];

    // --- Rapports journaliers (mélange validés / en attente / rejetés) ---
    rapports = [
      _rapport('rap-01', 'avs-01', 'pat-01', jour(0), 'Constantes stables, patient de bonne humeur, a bien mangé.', StatutRapport.enAttente),
      _rapport('rap-02', 'avs-01', 'pat-02', jour(0), 'Séance de kiné faite, légère raideur matinale signalée.', StatutRapport.enAttente),
      _rapport('rap-03', 'avs-03', 'pat-03', jour(0), 'TA un peu élevée ce matin (15/9), à surveiller ce soir.', StatutRapport.enAttente),
      _rapport('rap-04', 'avs-01', 'pat-01', jour(1), 'RAS, traitement pris à l\'heure, bon appétit.', StatutRapport.valide),
      _rapport('rap-05', 'avs-02', 'pat-05', jour(1), 'Mobilisation passive faite, plaie talon en amélioration.', StatutRapport.valide),
      _rapport('rap-06', 'avs-04', 'pat-04', jour(1), 'Glycémie limite haute (1.8g/L) après le déjeuner.', StatutRapport.valide),
      _rapport('rap-07', 'avs-05', 'pat-06', jour(2), 'Patiente fatiguée, a sauté la promenade prévue.', StatutRapport.rejete,
          motifRejet: 'Merci de préciser les constantes du soir, incomplet.'),
      _rapport('rap-08', 'avs-03', 'pat-07', jour(2), 'Glycémie contrôlée 3x, tout est dans les normes.', StatutRapport.valide),
      _rapport('rap-09', 'avs-02', 'pat-05', jour(3), 'Visite de la fille du patient, bonne ambiance générale.', StatutRapport.valide),
      _rapport('rap-10', 'avs-01', 'pat-02', jour(4), 'Refus partiel du traitement du soir, à signaler au médecin.', StatutRapport.valide),
    ];

    // --- Présences (10 derniers jours, tous AVS) ---
    presences = [];
    for (final avs in avsSeeds) {
      for (var j = 6; j >= 0; j--) {
        final estAujourdhui = j == 0;
        if (avs.id == 'avs-04' && j <= 1) {
          // Bertrand Fouda : absent aujourd'hui et hier (cohérent avec son statut).
          presences.add(Presence(id: 'pres-${avs.id}-$j', date: jour(j), statut: StatutPresence.absent));
          continue;
        }
        final enRetard = (avs.id == 'avs-05' && j == 2) || (avs.id == 'avs-03' && j == 4);
        final heureCheckIn = jour(j, enRetard ? 8 : 7, enRetard ? 40 : 15);
        presences.add(Presence(
          id: 'pres-${avs.id}-$j',
          date: jour(j),
          heureCheckIn: estAujourdhui && avs.id == 'avs-02' ? null : heureCheckIn,
          heureCheckOut: estAujourdhui ? null : jour(j, 16, 30),
          latitude: 3.8480 + (avs.id.hashCode % 50) / 1000,
          longitude: 11.5021 + (avs.id.hashCode % 40) / 1000,
          statut: enRetard ? StatutPresence.enRetard : StatutPresence.aLheure,
        ));
      }
    }

    // --- Utilisateurs (vue Administrateur : tout le personnel) ---
    utilisateurs = [
      admin_entities.Utilisateur(id: 'coord-01', nom: 'Talla', prenom: 'Hortense', email: 'hortense.talla@myspad.cm', telephone: '677 00 11 22', role: admin_entities.RoleUtilisateur.coordonnateur, actif: true, creeLe: jour(200)),
      admin_entities.Utilisateur(id: 'admin-01', nom: 'Nguema', prenom: 'Serge', email: 'serge.nguema@myspad.cm', telephone: '699 00 22 33', role: admin_entities.RoleUtilisateur.administrateur, actif: true, creeLe: jour(300)),
      admin_entities.Utilisateur(id: 'med-01', nom: 'Kamdem', prenom: 'Dr. Alain', email: 'alain.kamdem@myspad.cm', telephone: '655 00 33 44', role: admin_entities.RoleUtilisateur.medecin, actif: true, creeLe: jour(150)),
      for (final a in avsSeeds)
        admin_entities.Utilisateur(
          id: a.id,
          nom: a.nom,
          prenom: a.prenom,
          email: a.email,
          telephone: a.telephone,
          role: admin_entities.RoleUtilisateur.avs,
          actif: true,
          creeLe: jour(90),
        ),
    ];

    // --- Paiements (souscriptions patients) ---
    paiements = [
      admin_entities.Paiement(id: 'pai-01', patientNom: 'Pierre Ondoa', soinLibelle: 'Suivi santé + nutrition quotidien', montant: 85000, date: jour(0), statut: admin_entities.StatutPaiement.confirme),
      admin_entities.Paiement(id: 'pai-02', patientNom: 'Marthe Assam', soinLibelle: 'Accompagnement Parkinson 3x/semaine', montant: 60000, date: jour(0), statut: admin_entities.StatutPaiement.confirme),
      admin_entities.Paiement(id: 'pai-03', patientNom: 'Andre Biya', soinLibelle: 'Suivi santé quotidien', montant: 85000, date: jour(1), statut: admin_entities.StatutPaiement.enAttente),
      admin_entities.Paiement(id: 'pai-04', patientNom: 'Beatrice Ngo Mbarga', soinLibelle: 'Suivi nutrition 3x/semaine', montant: 60000, date: jour(2), statut: admin_entities.StatutPaiement.confirme),
      admin_entities.Paiement(id: 'pai-05', patientNom: 'Joseph Mvondo', soinLibelle: 'Rééducation + soins quotidiens', montant: 95000, date: jour(3), statut: admin_entities.StatutPaiement.confirme),
      admin_entities.Paiement(id: 'pai-06', patientNom: 'Colette Essomba', soinLibelle: 'Accompagnement mobilité 2x/semaine', montant: 45000, date: jour(5), statut: admin_entities.StatutPaiement.echoue),
      admin_entities.Paiement(id: 'pai-07', patientNom: 'Emmanuel Nkolo', soinLibelle: 'Suivi diabète quotidien', montant: 70000, date: jour(6), statut: admin_entities.StatutPaiement.confirme),
    ];

    // --- Traitements (ordonnances, pour le rôle Médecin en étude) ---
    traitements = [
      Traitement(id: 'trt-01', patientNom: 'Pierre Ondoa', medicament: 'Metformine 850mg', posologie: '1-0-1', dateEmission: jour(35), statut: StatutTraitement.actif),
      Traitement(id: 'trt-02', patientNom: 'Marthe Assam', medicament: 'Modopar 250', posologie: '1-1-1', dateEmission: jour(80), statut: StatutTraitement.actif),
      Traitement(id: 'trt-03', patientNom: 'Andre Biya', medicament: 'Amlodipine 5mg', posologie: '1-0-0', dateEmission: jour(50), statut: StatutTraitement.actif),
      Traitement(id: 'trt-04', patientNom: 'Emmanuel Nkolo', medicament: 'Insuline lente', posologie: '0-0-1', dateEmission: jour(10), statut: StatutTraitement.actif),
      Traitement(id: 'trt-05', patientNom: 'Colette Essomba', medicament: 'Paracétamol 1g', posologie: '1-1-1', dateEmission: jour(120), statut: StatutTraitement.termine),
    ];
  }

  // --- Helpers de construction ------------------------------------------

  static Affectation _affectation(String id, String patientId, String avsId, String frequence, DateTime depuisLe) {
    final patient = _findPatient(patientId);
    final avs = _findAvs(avsId);
    return Affectation(
      id: id,
      patientId: patientId,
      avsId: avsId,
      patientNom: '${patient.prenom} ${patient.nom}',
      avsNom: '${avs.prenom} ${avs.nom}',
      frequence: frequence,
      depuisLe: depuisLe,
      active: true,
    );
  }

  static RapportAvs _rapport(String id, String avsId, String patientId, DateTime date, String resume, StatutRapport statut, {String? motifRejet}) {
    return RapportAvs(id: id, avsId: avsId, patientId: patientId, date: date, resume: resume, statut: statut, motifRejet: motifRejet);
  }

  static _PatientSeed _findPatient(String id) => patientSeeds.firstWhere((p) => p.id == id);
  static _AvsSeed _findAvs(String id) => avsSeeds.firstWhere((a) => a.id == id);

  /// Le compte réellement connecté vient du vrai backend d'auth (seul module
  /// déjà développé) : son id ne correspond donc à aucun `avs-0X` seedé ici.
  /// On retombe sur le premier AVS de la maquette plutôt que de renvoyer des
  /// listes vides, pour que la démo reste toujours peuplée quel que soit le
  /// compte utilisé pour se connecter.
  static String _normaliserAvsId(String avsId) {
    _seedIfNeeded();
    return avsSeeds.any((a) => a.id == avsId) ? avsId : avsSeeds.first.id;
  }

  // --- Accès haut niveau utilisés par les datasources --------------------

  static List<VisitePlanifiee> planningPour(String avsId) {
    _seedIfNeeded();
    avsId = _normaliserAvsId(avsId);
    final now = DateTime.now();
    final mesAffectations = affectations.where((a) => a.avsId == avsId && a.active);
    final visites = <VisitePlanifiee>[];
    var i = 0;
    for (final aff in mesAffectations) {
      final patient = _findPatient(aff.patientId);
      // Une visite "aujourd'hui" + une visite "demain" par affectation active,
      // suffisant pour peupler l'onglet Planning de façon crédible.
      visites.add(VisitePlanifiee(
        id: '${aff.id}-v0',
        patientId: patient.id,
        patientNom: '${patient.prenom} ${patient.nom}',
        adressePatient: patient.adresse,
        date: DateTime(now.year, now.month, now.day, 8 + i),
        creneauLibelle: 'Matinée',
        terminee: i.isEven,
      ));
      visites.add(VisitePlanifiee(
        id: '${aff.id}-v1',
        patientId: patient.id,
        patientNom: '${patient.prenom} ${patient.nom}',
        adressePatient: patient.adresse,
        date: DateTime(now.year, now.month, now.day + 1, 8 + i),
        creneauLibelle: 'Matinée',
        terminee: false,
      ));
      i++;
    }
    return visites;
  }

  static List<RapportAvs> rapportsDe(String avsId) {
    _seedIfNeeded();
    avsId = _normaliserAvsId(avsId);
    return rapports.where((r) => r.avsId == avsId).toList();
  }

  static Presence? presenceDuJourPour(String avsId) {
    _seedIfNeeded();
    avsId = _normaliserAvsId(avsId);
    final aujourdhui = DateTime.now();
    try {
      return presences.firstWhere((p) =>
          p.id.startsWith('pres-$avsId-') &&
          p.date.year == aujourdhui.year &&
          p.date.month == aujourdhui.month &&
          p.date.day == aujourdhui.day);
    } catch (_) {
      return null;
    }
  }

  static Presence checkIn(String avsId, double lat, double lng) {
    _seedIfNeeded();
    avsId = _normaliserAvsId(avsId);
    final now = DateTime.now();
    final marge = DateTime(now.year, now.month, now.day, 8, 0);
    final statut = now.isAfter(marge) ? StatutPresence.enRetard : StatutPresence.aLheure;
    final nouvelle = Presence(
      id: 'pres-$avsId-0',
      date: DateTime(now.year, now.month, now.day),
      heureCheckIn: now,
      latitude: lat,
      longitude: lng,
      statut: statut,
    );
    presences.removeWhere((p) => p.id == 'pres-$avsId-0');
    presences.add(nouvelle);
    return nouvelle;
  }

  static Presence checkOut(String avsId) {
    _seedIfNeeded();
    avsId = _normaliserAvsId(avsId);
    final actuelle = presenceDuJourPour(avsId);
    final now = DateTime.now();
    final maj = Presence(
      id: actuelle?.id ?? 'pres-$avsId-0',
      date: actuelle?.date ?? DateTime(now.year, now.month, now.day),
      heureCheckIn: actuelle?.heureCheckIn ?? now,
      heureCheckOut: now,
      latitude: actuelle?.latitude,
      longitude: actuelle?.longitude,
      statut: actuelle?.statut ?? StatutPresence.aLheure,
    );
    presences.removeWhere((p) => p.id == maj.id);
    presences.add(maj);
    return maj;
  }

  static RapportAvs creerRapport(String avsId, Map<String, dynamic> corps) {
    _seedIfNeeded();
    avsId = _normaliserAvsId(avsId);
    final patientId = corps['patientId']?.toString() ?? patientSeeds.first.id;
    final resume = (corps['conclusion'] ?? corps['observations'] ?? corps['plainte'] ?? 'Rapport transmis.').toString();
    final nouveau = RapportAvs(
      id: 'rap-${DateTime.now().millisecondsSinceEpoch}',
      avsId: avsId,
      patientId: patientId,
      date: DateTime.now(),
      resume: resume,
      statut: StatutRapport.enAttente,
    );
    rapports.insert(0, nouveau);
    return nouveau;
  }

  static StatistiquesPonctualiteAvs statistiquesPour(String avsId) {
    _seedIfNeeded();
    avsId = _normaliserAvsId(avsId);
    final mesRapports = rapportsDe(avsId);
    final aTemps = mesRapports.where((r) => r.statut != StatutRapport.rejete).length;
    final enRetard = mesRapports.where((r) => r.statut == StatutRapport.rejete).length;
    final mesPresences = presences.where((p) => p.id.startsWith('pres-$avsId-'));
    final checkinsATemps = mesPresences.where((p) => p.statut == StatutPresence.aLheure).length;
    final checkinsEnRetard = mesPresences.where((p) => p.statut == StatutPresence.enRetard).length;
    final absences = mesPresences.where((p) => p.statut == StatutPresence.absent).length;
    return StatistiquesPonctualiteAvs(
      rapportsATemps: aTemps,
      rapportsEnRetard: enRetard,
      checkinsATemps: checkinsATemps,
      checkinsEnRetard: checkinsEnRetard,
      absences: absences,
    );
  }

  static List<Patient> patients({String? search}) {
    _seedIfNeeded();
    Iterable<_PatientSeed> seeds = patientSeeds;
    if (search != null && search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      seeds = seeds.where((p) => ('${p.prenom} ${p.nom}').toLowerCase().contains(q));
    }
    return seeds.map(_toPatient).toList();
  }

  static Patient patient(String id) {
    _seedIfNeeded();
    return _toPatient(_findPatient(id));
  }

  static Patient _toPatient(_PatientSeed p) {
    final avs = p.avsAssigneId != null ? _findAvs(p.avsAssigneId!) : null;
    return Patient(
      id: p.id,
      nom: p.nom,
      prenom: p.prenom,
      dateNaissance: p.dateNaissance,
      age: DateTime.now().year - p.dateNaissance.year,
      adresse: p.adresse,
      pathologie: p.pathologie,
      antecedents: p.antecedents,
      allergies: p.allergies,
      difficultesMobilite: p.difficultesMobilite,
      telephone: p.telephone,
      avsAssigneId: p.avsAssigneId,
      avsAssigneNom: avs != null ? '${avs.prenom} ${avs.nom}' : null,
    );
  }

  static Patient ajouterPatient(Map<String, dynamic> corps) {
    _seedIfNeeded();
    final id = 'pat-${patientSeeds.length + 1}-${DateTime.now().millisecondsSinceEpoch % 10000}';
    final seed = _PatientSeed(
      id,
      corps['nom']?.toString() ?? '',
      corps['prenom']?.toString() ?? '',
      corps['dateNaissance'] != null ? DateTime.tryParse(corps['dateNaissance'].toString()) ?? DateTime.now() : DateTime.now(),
      corps['adresse']?.toString() ?? '',
      corps['pathologie']?.toString() ?? '',
      (corps['antecedents'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      (corps['allergies'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      (corps['difficultesMobilite'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      corps['telephone']?.toString(),
      null,
    );
    patientSeeds.add(seed);
    return _toPatient(seed);
  }

  static List<Avs> equipeAvs() {
    _seedIfNeeded();
    return avsSeeds.map((a) {
      final charge = affectations.where((aff) => aff.avsId == a.id && aff.active).length;
      return Avs(id: a.id, nom: a.nom, prenom: a.prenom, telephone: a.telephone, email: a.email, statut: a.statut, patientsAssignes: charge);
    }).toList();
  }

  static List<Affectation> affectationsFiltrees({String? patientId, String? avsId}) {
    _seedIfNeeded();
    return affectations.where((a) {
      if (patientId != null && a.patientId != patientId) return false;
      if (avsId != null && a.avsId != avsId) return false;
      return true;
    }).toList();
  }

  static Affectation creerAffectation({required String patientId, required String avsId, required String frequence, required DateTime dateDebut, String? notes}) {
    _seedIfNeeded();
    final nouvelle = _affectation('aff-${DateTime.now().millisecondsSinceEpoch}', patientId, avsId, frequence, dateDebut);
    affectations.add(nouvelle);
    final index = patientSeeds.indexWhere((p) => p.id == patientId);
    if (index != -1) {
      patientSeeds[index] = patientSeeds[index].avecAvs(avsId);
    }
    return nouvelle;
  }

  static void terminerAffectation(String id) {
    _seedIfNeeded();
    final index = affectations.indexWhere((a) => a.id == id);
    if (index == -1) return;
    final a = affectations[index];
    affectations[index] = Affectation(
      id: a.id, patientId: a.patientId, avsId: a.avsId, patientNom: a.patientNom, avsNom: a.avsNom,
      frequence: a.frequence, depuisLe: a.depuisLe, finLe: DateTime.now(), active: false,
    );
  }

  static List<RapportAvs> tousLesRapports({String? patientId, String? avsId}) {
    _seedIfNeeded();
    return rapports.where((r) {
      if (patientId != null && r.patientId != patientId) return false;
      if (avsId != null && r.avsId != avsId) return false;
      return true;
    }).toList();
  }

  static List<RapportAvs> rapportsEnAttente() {
    _seedIfNeeded();
    return rapports.where((r) => r.statut == StatutRapport.enAttente).toList();
  }

  static void validerRapport(String id) {
    _seedIfNeeded();
    final i = rapports.indexWhere((r) => r.id == id);
    if (i != -1) rapports[i] = rapports[i].copierAvec(statut: StatutRapport.valide);
  }

  static void rejeterRapport(String id, {String? motif}) {
    _seedIfNeeded();
    final i = rapports.indexWhere((r) => r.id == id);
    if (i != -1) {
      final r = rapports[i];
      rapports[i] = RapportAvs(id: r.id, avsId: r.avsId, patientId: r.patientId, date: r.date, resume: r.resume, statut: StatutRapport.rejete, motifRejet: motif ?? r.motifRejet);
    }
  }

  static List<admin_entities.Utilisateur> listerUtilisateurs({String? role, String? search}) {
    _seedIfNeeded();
    return utilisateurs.where((u) {
      if (role != null && u.role.name != role) return false;
      if (search != null && search.trim().isNotEmpty && !u.nomComplet.toLowerCase().contains(search.trim().toLowerCase())) return false;
      return true;
    }).toList();
  }

  static admin_entities.Utilisateur creerUtilisateur(Map<String, dynamic> corps) {
    _seedIfNeeded();
    final nouveau = admin_entities.Utilisateur(
      id: 'user-${DateTime.now().millisecondsSinceEpoch}',
      nom: corps['nom']?.toString() ?? '',
      prenom: corps['prenom']?.toString() ?? '',
      email: corps['email']?.toString() ?? '',
      telephone: corps['telephone']?.toString(),
      role: admin_entities.roleUtilisateurFromString(corps['role']?.toString()),
      actif: true,
      creeLe: DateTime.now(),
    );
    utilisateurs.add(nouveau);
    return nouveau;
  }

  static void basculerActivation(String id, bool actif) {
    _seedIfNeeded();
    final i = utilisateurs.indexWhere((u) => u.id == id);
    if (i != -1) utilisateurs[i] = utilisateurs[i].copierAvec(actif: actif);
  }

  static List<admin_entities.Paiement> listerPaiements() {
    _seedIfNeeded();
    return paiements;
  }

  static admin_entities.StatistiquesGlobales statistiquesGlobales() {
    _seedIfNeeded();
    final aujourdhui = DateTime.now();
    final paiementsDuJour = paiements.where((p) =>
        p.date.year == aujourdhui.year && p.date.month == aujourdhui.month && p.date.day == aujourdhui.day && p.statut == admin_entities.StatutPaiement.confirme);
    return admin_entities.StatistiquesGlobales(
      totalPatients: patientSeeds.length,
      totalAvs: avsSeeds.length,
      rapportsEnRetard: rapports.where((r) => r.statut == StatutRapport.rejete).length,
      avsAbsentsAujourdhui: avsSeeds.where((a) => a.statut == StatutAvs.absent).length,
      montantPaiementsDuJour: paiementsDuJour.fold(0.0, (s, p) => s + p.montant),
      paiementsDuJour: paiementsDuJour.length,
    );
  }

  static List<DossierMedicalPatient> dossiersMedicaux() {
    _seedIfNeeded();
    return patientSeeds.map((p) => DossierMedicalPatient(
          id: p.id,
          nomComplet: '${p.prenom} ${p.nom}',
          age: DateTime.now().year - p.dateNaissance.year,
          pathologiePrincipale: p.pathologie,
          derniereConsultation: DateTime.now().subtract(Duration(days: 3 + (p.id.hashCode % 20).abs())),
        )).toList();
  }

  static List<Traitement> listerTraitements() {
    _seedIfNeeded();
    return traitements;
  }

  static Traitement prescrire(Map<String, dynamic> corps) {
    _seedIfNeeded();
    final nouveau = Traitement(
      id: 'trt-${DateTime.now().millisecondsSinceEpoch}',
      patientNom: corps['patientNom']?.toString() ?? 'Patient',
      medicament: corps['medicament']?.toString() ?? '',
      posologie: corps['posologie']?.toString() ?? '',
      dateEmission: DateTime.now(),
      statut: StatutTraitement.actif,
    );
    traitements.insert(0, nouveau);
    return nouveau;
  }
}

/// Petite structure interne (non exposée) pour porter les données brutes des
/// AVS avant projection vers l'entité `Avs` du feature Coordonnateur.
class _AvsSeed {
  final String id;
  final String nom;
  final String prenom;
  final String telephone;
  final String email;
  final StatutAvs statut;
  final String zone;

  const _AvsSeed(this.id, this.nom, this.prenom, this.telephone, this.email, this.statut, this.zone);
}

/// Idem côté patients : porte aussi `avsAssigneId`, mutable via `avecAvs`
/// pour refléter une nouvelle affectation créée en mock.
class _PatientSeed {
  final String id;
  final String nom;
  final String prenom;
  final DateTime dateNaissance;
  final String adresse;
  final String pathologie;
  final List<String> antecedents;
  final List<String> allergies;
  final List<String> difficultesMobilite;
  final String? telephone;
  final String? avsAssigneId;

  const _PatientSeed(
    this.id,
    this.nom,
    this.prenom,
    this.dateNaissance,
    this.adresse,
    this.pathologie,
    this.antecedents,
    this.allergies,
    this.difficultesMobilite,
    this.telephone,
    this.avsAssigneId,
  );

  _PatientSeed avecAvs(String avsId) => _PatientSeed(
        id, nom, prenom, dateNaissance, adresse, pathologie, antecedents, allergies, difficultesMobilite, telephone, avsId,
      );
}
