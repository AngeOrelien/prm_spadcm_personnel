import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../dashboard/dashboard_widgets.dart';

/// Widgets communs à l'onglet "Messagerie" des 4 rôles de l'app Personnel
/// (Administrateur, Coordonnateur, Médecin, AVS).
///
/// Avant ce fichier, chaque rôle réimplémentait sa propre variante des
/// mêmes widgets (tuile de contact, section groupée par type
/// d'interlocuteur, fil épinglé de l'assistant IA) avec de très légères
/// différences de mise en page — ce qui donnait 4 onglets Messagerie visuellement
/// différents alors qu'ils répondent au même besoin. Regroupés ici pour que
/// toute évolution visuelle (couleurs, densité, etc.) se fasse à un seul
/// endroit et profite aux 4 rôles.

/// Tuile de contact générique : avatar (initiales ou photo), nom,
/// sous-titre (dernier message échangé, ou libellé du rôle par défaut) et
/// indicateur de chargement pendant l'ouverture de la conversation.
class TuileContactMessagerie extends StatelessWidget {
  final String nom;
  final String sousTitre;
  final String? photoUrl;
  final Color? couleur;
  final bool chargement;
  // Nullable : `null` désactive la tuile (ex: patient sans compte de
  // connexion associé, voir `Patient.compteUtilisateurId`) — grisée, sans
  // chevron, non tapable, plutôt que de fournir un callback vide.
  final VoidCallback? onTap;

  const TuileContactMessagerie({
    super.key,
    required this.nom,
    required this.sousTitre,
    this.photoUrl,
    this.couleur,
    this.chargement = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final desactivee = onTap == null && !chargement;
    return ListTile(
      leading: InitialsAvatar(nomComplet: nom, couleur: desactivee ? AppColors.textDisabled : couleur, photoUrl: photoUrl),
      title: Text(
        nom,
        style: TextStyle(fontWeight: FontWeight.w600, color: desactivee ? AppColors.textDisabled : null),
      ),
      subtitle: Text(sousTitre, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: chargement
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : desactivee
              ? null
              : const Icon(Icons.chevron_right, color: AppColors.textDisabled),
      onTap: chargement ? null : onTap,
    );
  }
}

/// Section groupée par type d'interlocuteur (ex: "AVS", "Médecins",
/// "Coordonnateurs", "Administrateurs", "Patients / Familles") : titre +
/// liste de tuiles, avec états chargement/erreur/vide gérés uniformément.
///
/// Générique en [T] pour servir aussi bien une liste de `PersonnelAnnuaire`
/// (annuaire par rôle) qu'une liste de `Patient`/`DossierMedicalPatient` —
/// chaque page fournit juste [tuileBuilder] pour transformer un élément en
/// [TuileContactMessagerie].
class SectionMessagerie<T> extends StatelessWidget {
  final String titre;
  final AsyncValue<List<T>> async;
  final Widget Function(T item) tuileBuilder;
  final String messageVide;
  final String messageErreur;

  const SectionMessagerie({
    super.key,
    required this.titre,
    required this.async,
    required this.tuileBuilder,
    this.messageVide = 'Aucun contact dans cette catégorie.',
    this.messageErreur = 'Non disponible pour le moment.',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(titre: titre),
        async.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: LinearProgressIndicator(),
          ),
          error: (e, st) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(messageErreur, style: Theme.of(context).textTheme.bodySmall),
          ),
          data: (liste) => liste.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Text(messageVide, style: Theme.of(context).textTheme.bodySmall),
                )
              : Column(children: [for (final item in liste) tuileBuilder(item)]),
        ),
      ],
    );
  }
}

/// Rangée de filtres ("Tous" + un par catégorie d'interlocuteur), en tête
/// de la liste des conversations de l'onglet Messagerie — permet de
/// n'afficher qu'une catégorie (ex: juste les Médecins) plutôt que de
/// scroller toutes les sections. Commun aux 4 rôles : chacun fournit sa
/// propre liste de [FiltreMessagerie] (celles qui ont du sens pour lui,
/// voir chaque page "Messagerie"), avec la même présentation partout.
class FiltreMessagerie {
  final String cle;
  final String libelle;

  const FiltreMessagerie(this.cle, this.libelle);
}

class FiltresRoleMessagerie extends StatelessWidget {
  final List<FiltreMessagerie> filtres;
  final String? selectionne; // null = "Tous"
  final ValueChanged<String?> onChanged;

  const FiltresRoleMessagerie({
    super.key,
    required this.filtres,
    required this.selectionne,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: filtres.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _PuceFiltre(libelle: 'Tous', selectionne: selectionne == null, onTap: () => onChanged(null));
          }
          final filtre = filtres[index - 1];
          return _PuceFiltre(
            libelle: filtre.libelle,
            selectionne: selectionne == filtre.cle,
            onTap: () => onChanged(filtre.cle),
          );
        },
      ),
    );
  }
}

class _PuceFiltre extends StatelessWidget {
  final String libelle;
  final bool selectionne;
  final VoidCallback onTap;

  const _PuceFiltre({required this.libelle, required this.selectionne, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selectionne ? AppColors.primarySurface : AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selectionne) ...[
                const Icon(Icons.check, size: 15, color: AppColors.primary),
                const SizedBox(width: 4),
              ],
              Text(
                libelle,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selectionne ? FontWeight.w700 : FontWeight.w500,
                  color: selectionne ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fil épinglé de l'assistant IA de SPAD, en tête de l'onglet Messagerie —
/// commun aux 4 rôles de l'app Personnel (Administrateur, AVS, Coordonnateur,
/// Médecin), pour un onglet Messagerie cohérent partout.
class TuileIaEpingleeMessagerie extends StatelessWidget {
  final String nomAssistant;
  final VoidCallback onTap;

  const TuileIaEpingleeMessagerie({super.key, required this.nomAssistant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Material(
        color: AppColors.accentSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.accent,
                  child: Icon(Icons.smart_toy_outlined, color: Colors.white),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(nomAssistant, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                          const SizedBox(width: 6),
                          const Icon(Icons.push_pin, size: 12, color: AppColors.accent),
                        ],
                      ),
                      const Text(
                        'Assistant IA · toujours disponible',
                        maxLines: 1,
                        style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textDisabled),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
