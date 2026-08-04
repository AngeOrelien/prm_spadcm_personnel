import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../domain/entities/ia_entities.dart';
import '../providers/ia_providers.dart';

/// Recherche sémantique dans les rapports/messages/dossiers
/// (`POST /api/ia/recherche-semantique`) — barre de saisie + résultats,
/// autonome (gère elle-même son [RechercheSemantiqueController]).
///
/// `patientId` optionnel : restreint la recherche à un seul dossier. Sans
/// lui, recherche transversale (réservée avs/medecin/coordonnateur/
/// administrateur côté backend, voir `iaRoutes.js` — jamais patient/famille).
class RechercheSemantiqueWidget extends ConsumerStatefulWidget {
  final String? patientId;

  const RechercheSemantiqueWidget({super.key, this.patientId});

  @override
  ConsumerState<RechercheSemantiqueWidget> createState() => _RechercheSemantiqueWidgetState();
}

class _RechercheSemantiqueWidgetState extends ConsumerState<RechercheSemantiqueWidget> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _rechercher() {
    ref.read(rechercheSemantiqueControllerProvider.notifier).rechercher(_controller.text, patientId: widget.patientId);
  }

  @override
  Widget build(BuildContext context) {
    final etat = ref.watch(rechercheSemantiqueControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _rechercher(),
          decoration: InputDecoration(
            hintText: 'Rechercher dans les rapports, messages…',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: etat.enCours
                ? const Padding(
                    padding: EdgeInsets.all(14),
                    child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : IconButton(icon: const Icon(Icons.arrow_forward), onPressed: _rechercher),
            filled: true,
            fillColor: AppColors.surfaceMuted,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (etat.erreur != null)
          Text(etat.erreur!, style: const TextStyle(color: AppColors.error, fontSize: 12.5))
        else if (etat.aDejaRecherche && etat.resultats.isEmpty && !etat.enCours)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Center(child: Text('Aucun résultat.', style: TextStyle(color: AppColors.textSecondary))),
          )
        else
          ...etat.resultats.map((r) => _CarteResultat(resultat: r)),
      ],
    );
  }
}

class _CarteResultat extends StatelessWidget {
  final ResultatRechercheSemantique resultat;

  const _CarteResultat({required this.resultat});

  IconData get _icone => switch (resultat.type) {
        'rapport_journalier' => Icons.description_outlined,
        'message' => Icons.chat_bubble_outline,
        'patient' => Icons.person_outline,
        _ => Icons.article_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icone, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(resultat.extrait, style: const TextStyle(fontSize: 13, height: 1.3)),
                const SizedBox(height: 2),
                Text(
                  [
                    if (resultat.date != null) '${resultat.date!.day}/${resultat.date!.month}/${resultat.date!.year}',
                    'pertinence ${(resultat.score * 100).toStringAsFixed(0)}%',
                  ].join(' · '),
                  style: const TextStyle(fontSize: 10.5, color: AppColors.textDisabled),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
