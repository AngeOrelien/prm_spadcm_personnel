import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../domain/entities/coordonnateur_entities.dart';

// ---------------------------------------------------------------------------
// TODO(backend): ces providers exposent pour l'instant des données factices
// en mémoire, le temps que les endpoints "patients / avs / affectations /
// rapports" existent côté API. Le jour venu, remplacer le contenu des
// StateNotifier ci-dessous par de vrais appels repository (même pattern que
// `auth_providers.dart`) — les pages n'ont pas à changer.
// ---------------------------------------------------------------------------

final _avsInitiaux = <Avs>[
  const Avs(id: 'avs1', nom: 'Kamga', prenom: 'Solange', telephone: '+237 690 11 22 33', statut: StatutAvs.disponible, patientsAssignes: 2),
  const Avs(id: 'avs2', nom: 'Mballa', prenom: 'Eric', telephone: '+237 677 22 33 44', statut: StatutAvs.enIntervention, patientsAssignes: 3),
  const Avs(id: 'avs3', nom: 'Ngo Bell', prenom: 'Chantal', telephone: '+237 655 33 44 55', statut: StatutAvs.disponible, patientsAssignes: 1),
  const Avs(id: 'avs4', nom: 'Fotso', prenom: 'Paul', telephone: '+237 699 44 55 66', statut: StatutAvs.absent, patientsAssignes: 0),
];

final _patientsInitiaux = <Patient>[
  const Patient(id: 'pat1', nom: 'Etoundi', prenom: 'Marie', age: 78, adresse: 'Bastos, Yaoundé', pathologie: 'Diabète type 2', avsAssigneId: 'avs1'),
  const Patient(id: 'pat2', nom: 'Owona', prenom: 'Jean', age: 84, adresse: 'Mvan, Yaoundé', pathologie: 'Alzheimer débutant', avsAssigneId: 'avs2'),
  const Patient(id: 'pat3', nom: 'Biya', prenom: 'Angèle', age: 69, adresse: 'Nlongkak, Yaoundé', pathologie: 'Hypertension', avsAssigneId: 'avs1'),
  const Patient(id: 'pat4', nom: 'Talla', prenom: 'Bernard', age: 91, adresse: 'Essos, Yaoundé', pathologie: 'Mobilité réduite', avsAssigneId: null),
  const Patient(id: 'pat5', nom: 'Ndzana', prenom: 'Sylvie', age: 73, adresse: 'Emombo, Yaoundé', pathologie: 'Post-AVC', avsAssigneId: 'avs2'),
];

final _affectationsInitiales = <Affectation>[
  Affectation(id: 'aff1', patientId: 'pat1', avsId: 'avs1', frequence: '3x / semaine', depuisLe: DateTime(2026, 3, 2)),
  Affectation(id: 'aff2', patientId: 'pat2', avsId: 'avs2', frequence: 'Quotidien', depuisLe: DateTime(2026, 1, 15)),
  Affectation(id: 'aff3', patientId: 'pat3', avsId: 'avs1', frequence: '2x / semaine', depuisLe: DateTime(2026, 5, 20)),
  Affectation(id: 'aff4', patientId: 'pat5', avsId: 'avs2', frequence: 'Quotidien', depuisLe: DateTime(2026, 4, 8)),
];

final _rapportsInitiaux = <RapportAvs>[
  RapportAvs(id: 'rap1', avsId: 'avs1', patientId: 'pat1', date: DateTime(2026, 7, 18), resume: 'Prise des constantes normale, glycémie stable, patient de bonne humeur.'),
  RapportAvs(id: 'rap2', avsId: 'avs2', patientId: 'pat2', date: DateTime(2026, 7, 18), resume: 'Légère confusion en soirée, aide au repas nécessaire, à surveiller.'),
  RapportAvs(id: 'rap3', avsId: 'avs1', patientId: 'pat3', date: DateTime(2026, 7, 17), resume: 'Tension artérielle un peu élevée (15/9), reste du suivi RAS.'),
  RapportAvs(id: 'rap4', avsId: 'avs2', patientId: 'pat5', date: DateTime(2026, 7, 17), resume: 'Séance de rééducation bien suivie, progrès sur la mobilité du bras droit.', statut: StatutRapport.valide),
  RapportAvs(id: 'rap5', avsId: 'avs1', patientId: 'pat1', date: DateTime(2026, 7, 16), resume: 'Refus de prise de traitement le matin, accepté après discussion.', statut: StatutRapport.rejete),
];

class AvsListNotifier extends StateNotifier<List<Avs>> {
  AvsListNotifier() : super(_avsInitiaux);

  void ajouter(Avs avs) => state = [...state, avs];
}

final avsListProvider = StateNotifierProvider<AvsListNotifier, List<Avs>>((ref) {
  return AvsListNotifier();
});

class PatientsListNotifier extends StateNotifier<List<Patient>> {
  PatientsListNotifier() : super(_patientsInitiaux);

  void ajouter(Patient patient) => state = [...state, patient];

  void assignerAvs(String patientId, String avsId) {
    state = [
      for (final p in state)
        if (p.id == patientId)
          Patient(
            id: p.id,
            nom: p.nom,
            prenom: p.prenom,
            age: p.age,
            adresse: p.adresse,
            pathologie: p.pathologie,
            avsAssigneId: avsId,
          )
        else
          p,
    ];
  }
}

final patientsListProvider = StateNotifierProvider<PatientsListNotifier, List<Patient>>((ref) {
  return PatientsListNotifier();
});

class AffectationsListNotifier extends StateNotifier<List<Affectation>> {
  AffectationsListNotifier() : super(_affectationsInitiales);

  void ajouter(Affectation affectation) => state = [...state, affectation];
}

final affectationsListProvider = StateNotifierProvider<AffectationsListNotifier, List<Affectation>>((ref) {
  return AffectationsListNotifier();
});

class RapportsListNotifier extends StateNotifier<List<RapportAvs>> {
  RapportsListNotifier() : super(_rapportsInitiaux);

  void mettreAJourStatut(String rapportId, StatutRapport statut) {
    state = [
      for (final r in state)
        if (r.id == rapportId) r.copierAvec(statut: statut) else r,
    ];
  }
}

final rapportsListProvider = StateNotifierProvider<RapportsListNotifier, List<RapportAvs>>((ref) {
  return RapportsListNotifier();
});

/// Quelques compteurs dérivés, pratiques pour l'accueil et les headers.
final rapportsEnAttenteProvider = Provider<int>((ref) {
  return ref.watch(rapportsListProvider).where((r) => r.statut == StatutRapport.enAttente).length;
});

final patientsNonAssignesProvider = Provider<int>((ref) {
  return ref.watch(patientsListProvider).where((p) => p.avsAssigneId == null).length;
});
