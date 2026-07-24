import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/administrateur_entities.dart';

extension RoleUtilisateurX on RoleUtilisateur {
  String get libelle => switch (this) {
    RoleUtilisateur.avs => 'AVS',
    RoleUtilisateur.medecin => 'Médecin',
    RoleUtilisateur.coordonnateur => 'Coordonnateur',
    RoleUtilisateur.administrateur => 'Administrateur',
    RoleUtilisateur.patientFamille => 'Patient/Famille',
  };

  Color get couleur => switch (this) {
    RoleUtilisateur.avs => AppColors.roleAvs,
    RoleUtilisateur.medecin => AppColors.roleMedecin,
    RoleUtilisateur.coordonnateur => AppColors.roleCoordonnateur,
    RoleUtilisateur.administrateur => AppColors.roleAdministrateur,
    RoleUtilisateur.patientFamille => AppColors.textSecondary,
  };
}

extension StatutPaiementX on StatutPaiement {
  String get libelle => switch (this) {
    StatutPaiement.enAttente => 'En attente',
    StatutPaiement.confirme => 'Confirmé',
    StatutPaiement.echoue => 'Échoué',
    StatutPaiement.rembourse => 'Remboursé',
  };

  Color get couleur => switch (this) {
    StatutPaiement.enAttente => AppColors.warning,
    StatutPaiement.confirme => AppColors.success,
    StatutPaiement.echoue => AppColors.error,
    StatutPaiement.rembourse => AppColors.info,
  };
}
