import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/medecin_entities.dart';

extension StatutTraitementX on StatutTraitement {
  String get libelle => switch (this) {
    StatutTraitement.actif => 'Actif',
    StatutTraitement.termine => 'Terminé',
    StatutTraitement.suspendu => 'Suspendu',
  };

  Color get couleur => switch (this) {
    StatutTraitement.actif => AppColors.success,
    StatutTraitement.termine => AppColors.textDisabled,
    StatutTraitement.suspendu => AppColors.warning,
  };
}
