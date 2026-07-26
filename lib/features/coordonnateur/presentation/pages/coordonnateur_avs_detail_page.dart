import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../router/app_routes.dart';
import '../../../../shared/widgets/misc/app_circle_icon_button.dart';
import '../../domain/entities/coordonnateur_entities.dart';
import '../providers/coordonnateur_providers.dart';
import '../widgets/coordonnateur_widgets.dart';

/// Fiche AVS plein écran : coordonnées, photo de profil, statut de
/// disponibilité bien visible, ses affectations en cours, ses derniers
/// rapports, et un bouton "Discuter" vers une vraie conversation.
///
/// Selon la disponibilité de l'AVS :
/// - libre (aucune affectation active) → bouton "Affecter à un patient",
///   qui envoie vers la page des affectations avec cet AVS présélectionné ;
/// - déjà en soins → une carte "Affectation actuelle" résume chez quel
///   patient il intervient, sans repasser par un formulaire.
class CoordonnateurAvsDetailPage extends ConsumerWidget {
  final String avsId;

  const CoordonnateurAvsDetailPage({super.key, required this.avsId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avsListeAsync = ref.watch(avsListProvider);
    final affectationsAsync = ref.watch(affectationsDeLavsProvider(avsId));
    final rapportsAsync = ref.watch(rapportsDeLavsProvider(avsId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: avsListeAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, st) => _ErreurChargement(onReessayer: () => ref.invalidate(avsListProvider)),
          data: (liste) {
            Avs? avs;
            for (final a in liste) {
              if (a.id == avsId) {
                avs = a;
                break;
              }
            }
            if (avs == null) {
              return const Center(child: Text('AVS introuvable.'));
            }
            return _Contenu(avs: avs, affectationsAsync: affectationsAsync, rapportsAsync: rapportsAsync);
          },
        ),
      ),
    );
  }
}

class _Contenu extends ConsumerStatefulWidget {
  final Avs avs;
  final AsyncValue<List<Affectation>> affectationsAsync;
  final AsyncValue<List<RapportAvs>> rapportsAsync;

  const _Contenu({required this.avs, required this.affectationsAsync, required this.rapportsAsync});

  @override
  ConsumerState<_Contenu> createState() => _ContenuState();
}

class _ContenuState extends ConsumerState<_Contenu> {
  bool _ouvertureConversationEnCours = false;

  Future<void> _discuter() async {
    if (_ouvertureConversationEnCours) return;
    setState(() => _ouvertureConversationEnCours = true);
    try {
      final conversation = await ref.read(coordonnateurActionsProvider).ouvrirConversationAvec(widget.avs.id);
      if (!mounted) return;
      context.push(
        AppRoutes.coordonnateurMessagerieConversation(conversation.id),
        extra: {
          'conversationId': conversation.id,
          'nom': widget.avs.nomComplet,
          'sousTitre': widget.avs.statut.libelle,
        },
      );
    } catch (e) {
      if (!mounted) return;
      context.showError('$e');
    } finally {
      if (mounted) setState(() => _ouvertureConversationEnCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final avs = widget.avs;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _EnTete(avs: avs)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LigneCoordonnee(icon: Icons.phone_outlined, label: 'Téléphone', valeur: avs.telephone),
                if (avs.email != null) _LigneCoordonnee(icon: Icons.email_outlined, label: 'Email', valeur: avs.email!),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
            child: SectionTitle(titre: 'Patients assignés (${avs.patientsAssignes})'),
          ),
        ),
        widget.affectationsAsync.when(
          loading: () => const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (err, st) => SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text('Impossible de charger les affectations.', style: Theme.of(context).textTheme.bodySmall),
            ),
          ),
          data: (affectations) {
            final actives = affectations.where((a) => a.active).toList();

            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
              sliver: SliverToBoxAdapter(
                child: actives.isEmpty
                    ? _CarteAucuneAffectation(avs: avs)
                    : Column(
                        children: [
                          for (final affectation in actives) _AffectationLigne(affectation: affectation),
                        ],
                      ),
              ),
            );
          },
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, 0),
            child: SectionTitle(titre: 'Derniers rapports'),
          ),
        ),
        widget.rapportsAsync.when(
          loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
          error: (err, st) => const SliverToBoxAdapter(child: SizedBox.shrink()),
          data: (rapports) {
            if (rapports.isEmpty) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Text('Aucun rapport rédigé pour le moment.', style: Theme.of(context).textTheme.bodySmall),
                ),
              );
            }
            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
              sliver: SliverList.builder(
                itemCount: rapports.length > 5 ? 5 : rapports.length,
                itemBuilder: (context, index) {
                  final rapport = rapports[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    onTap: () => context.push(AppRoutes.coordonnateurRapportDetail(rapport.id)),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Expanded(child: Text(rapport.resume, maxLines: 2, overflow: TextOverflow.ellipsis)),
                          const SizedBox(width: AppSpacing.sm),
                          StatusChip(label: rapport.statut.libelle, couleur: rapport.statut.couleur),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push(AppRoutes.coordonnateurCheckinDetail(avs.id)),
                    icon: const Icon(Icons.event_available_outlined),
                    label: const Text('Check-in'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _ouvertureConversationEnCours ? null : _discuter,
                    icon: _ouvertureConversationEnCours
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.chat_bubble_outline),
                    label: const Text('Discuter'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Bandeau affiché quand l'AVS n'est rattaché à aucun patient : met en avant
/// sa disponibilité et propose directement de l'affecter, sans passer par
/// une navigation supplémentaire pour choisir l'agent dans le formulaire.
class _CarteAucuneAffectation extends StatelessWidget {
  final Avs avs;

  const _CarteAucuneAffectation({required this.avs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: avs.statut.couleur.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: avs.statut.couleur.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: avs.statut.couleur, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  avs.statut == StatutAvs.absent
                      ? 'Cet AVS est actuellement absent et n\'a aucun patient assigné.'
                      : 'Cet AVS est disponible et n\'a aucun patient assigné pour le moment.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => context.push(AppRoutes.coordonnateurAffectations, extra: {'avsId': avs.id}),
              icon: const Icon(Icons.assignment_ind_outlined),
              label: const Text('Affecter à un patient'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EnTete extends StatelessWidget {
  final Avs avs;

  const _EnTete({required this.avs});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCircleIconButton(icon: Icons.arrow_back, onPressed: () => Navigator.of(context).maybePop()),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _AvatarPhoto(avs: avs),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      avs.nomComplet,
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            avs.statut.libelle,
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Photo de profil de l'AVS si disponible (bandeau d'en-tête), avec un
/// contour blanc translucide et repli élégant sur les initiales.
class _AvatarPhoto extends StatelessWidget {
  final Avs avs;

  const _AvatarPhoto({required this.avs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5)),
      child: avs.photoUrl != null && avs.photoUrl!.isNotEmpty
          ? CircleAvatar(radius: 30, backgroundColor: Colors.white.withOpacity(0.18), backgroundImage: NetworkImage(avs.photoUrl!))
          : CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white.withOpacity(0.18),
              child: Text(
                _initiales(avs.nomComplet),
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600),
              ),
            ),
    );
  }

  String _initiales(String nomComplet) {
    final mots = nomComplet.trim().split(RegExp(r'\s+')).where((m) => m.isNotEmpty);
    if (mots.isEmpty) return '?';
    if (mots.length == 1) return mots.first.substring(0, 1).toUpperCase();
    return (mots.first.substring(0, 1) + mots.last.substring(0, 1)).toUpperCase();
  }
}

class _LigneCoordonnee extends StatelessWidget {
  final IconData icon;
  final String label;
  final String valeur;

  const _LigneCoordonnee({required this.icon, required this.label, required this.valeur});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Text('$label : ', style: Theme.of(context).textTheme.bodySmall),
          Text(valeur, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// Une affectation active du côté fiche AVS = une carte "Affectation
/// actuelle" (au lieu d'une simple ligne cliquable) : le coordonnateur voit
/// immédiatement chez quel patient l'AVS intervient et à quelle fréquence.
class _AffectationLigne extends StatelessWidget {
  final Affectation affectation;

  const _AffectationLigne({required this.affectation});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.06),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.success.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          InitialsAvatar(nomComplet: affectation.patientNom ?? '?'),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('En soins chez ${affectation.patientNom ?? 'un patient'}', style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('Passages : ${affectation.frequence}', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Voir la fiche patient',
            icon: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            onPressed: () => context.push(AppRoutes.coordonnateurPatientDetail(affectation.patientId)),
          ),
        ],
      ),
    );
  }
}

class _ErreurChargement extends StatelessWidget {
  final VoidCallback onReessayer;

  const _ErreurChargement({required this.onReessayer});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 40),
            const SizedBox(height: AppSpacing.sm),
            const Text('Impossible de charger la fiche AVS.', textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            FilledButton(onPressed: onReessayer, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}
