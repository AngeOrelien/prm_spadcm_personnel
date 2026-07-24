import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/coordonnateur_entities.dart';

// Les widgets génériques (StatCard, SectionTitle, StatusChip, InitialsAvatar,
// EmptyStateCard, ErreurChargement) ont été déplacés vers
// `shared/widgets/dashboard/dashboard_widgets.dart` pour être réutilisés par
// tous les rôles (AVS, Administrateur, Médecin), pas seulement Coordonnateur.
// On les ré-exporte ici pour ne rien casser dans les pages existantes qui
// importent ce fichier.
export '../../../../shared/widgets/dashboard/dashboard_widgets.dart';

extension StatutAvsX on StatutAvs {
  String get libelle => switch (this) {
    StatutAvs.disponible => 'Disponible',
    StatutAvs.enIntervention => 'En intervention',
    StatutAvs.absent => 'Absent',
  };

  Color get couleur => switch (this) {
    StatutAvs.disponible => AppColors.success,
    StatutAvs.enIntervention => AppColors.info,
    StatutAvs.absent => AppColors.textDisabled,
  };
}

extension StatutRapportX on StatutRapport {
  String get libelle => switch (this) {
    StatutRapport.enAttente => 'En attente',
    StatutRapport.valide => 'Validé',
    StatutRapport.rejete => 'Rejeté',
  };

  Color get couleur => switch (this) {
    StatutRapport.enAttente => AppColors.warning,
    StatutRapport.valide => AppColors.success,
    StatutRapport.rejete => AppColors.error,
  };
}
