/// Entités du feature IA — un seul module partagé entre les 4 rôles de
/// l'app Personnel (voir README.md, section 3.6 : le fil IA est épinglé
/// dans la messagerie de tous les rôles, l'AVS a en plus un bouton
/// flottant). Miroir des schémas Pydantic du service `prm-spadcm-ia`
/// (voir `app/schemas/chat.py`, `app/schemas/rapports.py`,
/// `app/schemas/performance.py`), tels qu'exposés par le backend Node
/// via `POST /api/assistant/chat` et `POST /api/ia/*`.

// --- Chat ---

enum RoleMessageChat { utilisateur, assistant }

class MessageChatIa {
  final String contenu;
  final RoleMessageChat role;
  final DateTime heure;

  const MessageChatIa({required this.contenu, required this.role, required this.heure});

  bool get deMoi => role == RoleMessageChat.utilisateur;
}

class ReponseChatIa {
  final String reponse;
  final List<String> sources;

  const ReponseChatIa({required this.reponse, this.sources = const []});
}

// --- Résumé automatique des rapports journaliers ---

class ResumeRapports {
  final String patientId;
  final String periode;
  final String resume;
  final int nombreRapportsAnalyses;

  const ResumeRapports({
    required this.patientId,
    required this.periode,
    required this.resume,
    required this.nombreRapportsAnalyses,
  });
}

// --- Évolution de l'état de santé ---

class PointEvolutionSante {
  final DateTime date;
  final double? poulsMoyen;
  final double? temperatureMoyenne;
  final double? spo2Moyen;

  const PointEvolutionSante({required this.date, this.poulsMoyen, this.temperatureMoyenne, this.spo2Moyen});
}

enum TendanceSante { stable, amelioration, degradation, inconnue }

TendanceSante tendanceDepuisTexte(String valeur) {
  final v = valeur.toLowerCase();
  if (v.contains('amélioration') || v.contains('amelioration')) return TendanceSante.amelioration;
  if (v.contains('dégrad') || v.contains('degrad')) return TendanceSante.degradation;
  if (v.contains('stable')) return TendanceSante.stable;
  return TendanceSante.inconnue;
}

class EvolutionSante {
  final String patientId;
  final List<PointEvolutionSante> points;
  final TendanceSante tendance;
  final String analyse;

  const EvolutionSante({
    required this.patientId,
    required this.points,
    required this.tendance,
    required this.analyse,
  });
}

// --- Performance des AVS ---

class ScoreAvs {
  final String avsId;
  final String? nomComplet;
  final double scoreGlobal;
  final double tauxPonctualiteRapports;
  final double tauxPresenceATemps;
  final double? noteMoyenneAppreciations;
  final int nombreRapports;
  final int nombrePresences;
  final int nombreAppreciations;
  final double? scoreModele;

  const ScoreAvs({
    required this.avsId,
    this.nomComplet,
    required this.scoreGlobal,
    required this.tauxPonctualiteRapports,
    required this.tauxPresenceATemps,
    this.noteMoyenneAppreciations,
    required this.nombreRapports,
    required this.nombrePresences,
    required this.nombreAppreciations,
    this.scoreModele,
  });
}

class PerformanceAvs {
  final int periodeJours;
  final List<ScoreAvs> resultats;

  const PerformanceAvs({required this.periodeJours, required this.resultats});
}

// --- Recherche sémantique ---

class ResultatRechercheSemantique {
  final String type; // "rapport_journalier" | "message" | "patient"
  final String id;
  final String extrait;
  final double score;
  final DateTime? date;

  const ResultatRechercheSemantique({
    required this.type,
    required this.id,
    required this.extrait,
    required this.score,
    this.date,
  });
}

// --- Alertes intelligentes ---

enum GraviteAnomalie { info, attention, urgent }

GraviteAnomalie graviteDepuisTexte(String valeur) {
  switch (valeur) {
    case 'urgent':
      return GraviteAnomalie.urgent;
    case 'attention':
      return GraviteAnomalie.attention;
    default:
      return GraviteAnomalie.info;
  }
}

class AnomalieDetectee {
  final String champ;
  final String valeur;
  final String seuilReference;
  final GraviteAnomalie gravite;
  final String explication;
  final String source; // "regle" | "modele" — voir prm-spadcm-ia/app/training/

  const AnomalieDetectee({
    required this.champ,
    required this.valeur,
    required this.seuilReference,
    required this.gravite,
    required this.explication,
    this.source = 'regle',
  });
}

class AlertesIntelligentes {
  final String patientId;
  final List<AnomalieDetectee> anomalies;
  final bool propositionAlerte;
  final String? typeAlerteProposee;

  const AlertesIntelligentes({
    required this.patientId,
    required this.anomalies,
    required this.propositionAlerte,
    this.typeAlerteProposee,
  });
}
