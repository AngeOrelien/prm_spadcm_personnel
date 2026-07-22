import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../router/app_routes.dart';
import '../../../../shared/widgets/misc/app_circle_icon_button.dart';
import '../../../../shared/widgets/pages/messagerie_stub_page.dart';
import '../../domain/entities/coordonnateur_entities.dart';
import '../providers/coordonnateur_providers.dart';
import '../widgets/coordonnateur_widgets.dart';

/// Fiche AVS plein écran : coordonnées, statut, ses affectations en cours
/// (patients suivis), et un bouton "Discuter" vers la messagerie (stub).
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

class _Contenu extends StatelessWidget {
  final Avs avs;
  final AsyncValue<List<Affectation>> affectationsAsync;
  final AsyncValue<List<RapportAvs>> rapportsAsync;

  const _Contenu({required this.avs, required this.affectationsAsync, required this.rapportsAsync});

  @override
  Widget build(BuildContext context) {
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
                const SizedBox(height: AppSpacing.md),
                SectionTitle(titre: 'Patients assignés (${avs.patientsAssignes})'),
              ],
            ),
          ),
        ),
        affectationsAsync.when(
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
            if (actives.isEmpty) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Text('Aucun patient assigné pour le moment.', style: Theme.of(context).textTheme.bodySmall),
                ),
              );
            }
            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
              sliver: SliverList.builder(
                itemCount: actives.length,
                itemBuilder: (context, index) => _AffectationLigne(affectation: actives[index]),
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
        rapportsAsync.when(
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
                  return Container(
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
                  );
                },
              ),
            );
          },
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MessagerieStubPage(
                      interlocuteurNom: avs.nomComplet,
                      interlocuteurSousTitre: avs.statut.libelle,
                    ),
                  ),
                ),
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Discuter avec cet AVS'),
              ),
            ),
          ),
        ),
      ],
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
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white.withOpacity(0.18),
                child: Text(
                  _initiales(avs.nomComplet),
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600),
                ),
              ),
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
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        avs.statut.libelle,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
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

class _AffectationLigne extends StatelessWidget {
  final Affectation affectation;

  const _AffectationLigne({required this.affectation});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
        leading: InitialsAvatar(nomComplet: affectation.patientNom ?? '?'),
        title: Text(affectation.patientNom ?? 'Patient', style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(affectation.frequence),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: () => context.push(AppRoutes.coordonnateurPatientDetail(affectation.patientId)),
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
