import '../../domain/entities/ia_entities.dart';

/// Conversion JSON <-> entités du feature IA.
///
/// Les endpoints `/api/ia/*` renvoient `{ success: true, donnees: {...} }`,
/// où `donnees` est exactement la réponse Pydantic du service `prm-spadcm-ia`
/// (mêmes noms de champs en snake_case, voir `app/schemas/*.py`) — ces
/// modèles parsent directement ce sous-objet `donnees`. `/api/assistant/chat`
/// fait exception et renvoie `{ success: true, reponse: "..." }` à plat (pas
/// de `donnees`), voir `assistantController.js`.

double? _double(dynamic v) => v == null ? null : (v as num).toDouble();
int _int(dynamic v) => (v as num).toInt();

class ReponseChatIaModel extends ReponseChatIa {
  const ReponseChatIaModel({required super.reponse, super.sources});

  factory ReponseChatIaModel.fromJson(Map<String, dynamic> json) {
    return ReponseChatIaModel(
      reponse: json['reponse'] as String? ?? '',
      sources: (json['sources'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }
}

class ResumeRapportsModel extends ResumeRapports {
  const ResumeRapportsModel({
    required super.patientId,
    required super.periode,
    required super.resume,
    required super.nombreRapportsAnalyses,
  });

  factory ResumeRapportsModel.fromJson(Map<String, dynamic> json) {
    return ResumeRapportsModel(
      patientId: json['patient_id'] as String,
      periode: json['periode'] as String? ?? '',
      resume: json['resume'] as String? ?? '',
      nombreRapportsAnalyses: _int(json['nombre_rapports_analyses'] ?? 0),
    );
  }
}

class PointEvolutionSanteModel extends PointEvolutionSante {
  const PointEvolutionSanteModel({required super.date, super.poulsMoyen, super.temperatureMoyenne, super.spo2Moyen});

  factory PointEvolutionSanteModel.fromJson(Map<String, dynamic> json) {
    return PointEvolutionSanteModel(
      date: DateTime.parse(json['date'] as String),
      poulsMoyen: _double(json['pouls_moyen']),
      temperatureMoyenne: _double(json['temperature_moyenne']),
      spo2Moyen: _double(json['spo2_moyen']),
    );
  }
}

class EvolutionSanteModel extends EvolutionSante {
  const EvolutionSanteModel({
    required super.patientId,
    required super.points,
    required super.tendance,
    required super.analyse,
  });

  factory EvolutionSanteModel.fromJson(Map<String, dynamic> json) {
    final points = (json['points'] as List? ?? [])
        .map((e) => PointEvolutionSanteModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return EvolutionSanteModel(
      patientId: json['patient_id'] as String,
      points: points,
      tendance: tendanceDepuisTexte(json['tendance'] as String? ?? ''),
      analyse: json['analyse'] as String? ?? '',
    );
  }
}

class ScoreAvsModel extends ScoreAvs {
  const ScoreAvsModel({
    required super.avsId,
    super.nomComplet,
    required super.scoreGlobal,
    required super.tauxPonctualiteRapports,
    required super.tauxPresenceATemps,
    super.noteMoyenneAppreciations,
    required super.nombreRapports,
    required super.nombrePresences,
    required super.nombreAppreciations,
    super.scoreModele,
  });

  factory ScoreAvsModel.fromJson(Map<String, dynamic> json) {
    return ScoreAvsModel(
      avsId: json['avs_id'] as String,
      nomComplet: json['nom_complet'] as String?,
      scoreGlobal: _double(json['score_global']) ?? 0,
      tauxPonctualiteRapports: _double(json['taux_ponctualite_rapports']) ?? 0,
      tauxPresenceATemps: _double(json['taux_presence_a_temps']) ?? 0,
      noteMoyenneAppreciations: _double(json['note_moyenne_appreciations']),
      nombreRapports: _int(json['nombre_rapports'] ?? 0),
      nombrePresences: _int(json['nombre_presences'] ?? 0),
      nombreAppreciations: _int(json['nombre_appreciations'] ?? 0),
      scoreModele: _double(json['score_modele']),
    );
  }
}

class PerformanceAvsModel extends PerformanceAvs {
  const PerformanceAvsModel({required super.periodeJours, required super.resultats});

  factory PerformanceAvsModel.fromJson(Map<String, dynamic> json) {
    final resultats = (json['resultats'] as List? ?? [])
        .map((e) => ScoreAvsModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return PerformanceAvsModel(periodeJours: _int(json['periode_jours'] ?? 30), resultats: resultats);
  }
}

class ResultatRechercheSemantiqueModel extends ResultatRechercheSemantique {
  const ResultatRechercheSemantiqueModel({
    required super.type,
    required super.id,
    required super.extrait,
    required super.score,
    super.date,
  });

  factory ResultatRechercheSemantiqueModel.fromJson(Map<String, dynamic> json) {
    final dateStr = json['date'] as String?;
    return ResultatRechercheSemantiqueModel(
      type: json['type'] as String? ?? '',
      id: json['id'] as String? ?? '',
      extrait: json['extrait'] as String? ?? '',
      score: _double(json['score']) ?? 0,
      date: dateStr != null ? DateTime.tryParse(dateStr) : null,
    );
  }
}

class AnomalieDetecteeModel extends AnomalieDetectee {
  const AnomalieDetecteeModel({
    required super.champ,
    required super.valeur,
    required super.seuilReference,
    required super.gravite,
    required super.explication,
    super.source,
  });

  factory AnomalieDetecteeModel.fromJson(Map<String, dynamic> json) {
    return AnomalieDetecteeModel(
      champ: json['champ'] as String? ?? '',
      valeur: json['valeur'] as String? ?? '',
      seuilReference: json['seuil_reference'] as String? ?? '',
      gravite: graviteDepuisTexte(json['gravite'] as String? ?? 'info'),
      explication: json['explication'] as String? ?? '',
      source: json['source'] as String? ?? 'regle',
    );
  }
}

class AlertesIntelligentesModel extends AlertesIntelligentes {
  const AlertesIntelligentesModel({
    required super.patientId,
    required super.anomalies,
    required super.propositionAlerte,
    super.typeAlerteProposee,
  });

  factory AlertesIntelligentesModel.fromJson(Map<String, dynamic> json) {
    final anomalies = (json['anomalies'] as List? ?? [])
        .map((e) => AnomalieDetecteeModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return AlertesIntelligentesModel(
      patientId: json['patient_id'] as String,
      anomalies: anomalies,
      propositionAlerte: json['proposition_alerte'] as bool? ?? false,
      typeAlerteProposee: json['type_alerte_propose'] as String?,
    );
  }
}
