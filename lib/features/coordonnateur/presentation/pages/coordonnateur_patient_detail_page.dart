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

/// Fiche patient plein écran : identité, antécédents/allergies, contact
/// d'urgence, AVS actuellement assigné, derniers rapports d'intervention,
/// et un bouton "Discuter" vers la messagerie (stub pour l'instant).
class CoordonnateurPatientDetailPage extends ConsumerWidget {
  final String patientId;

  const CoordonnateurPatientDetailPage({super.key, required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientAsync = ref.watch(patientDetailProvider(patientId));
    final rapportsAsync = ref.watch(rapportsDuPatientProvider(patientId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: patientAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, st) => _ErreurChargement(
            message: '$err',
            onReessayer: () => ref.invalidate(patientDetailProvider(patientId)),
          ),
          data: (patient) => _Contenu(patient: patient, rapportsAsync: rapportsAsync),
        ),
      ),
    );
  }
}

class _Contenu extends StatelessWidget {
  final Patient patient;
  final AsyncValue<List<RapportAvs>> rapportsAsync;

  const _Contenu({required this.patient, required this.rapportsAsync});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _EnTete(patient: patient)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CarteAvsAssigne(patient: patient),
                const SizedBox(height: AppSpacing.lg),
                _SectionAntecedents(titre: 'Antécédents médicaux', items: patient.antecedents, icon: Icons.history),
                _SectionAntecedents(titre: 'Allergies', items: patient.allergies, icon: Icons.warning_amber_outlined),
                _SectionAntecedents(titre: 'Difficultés de mobilité', items: patient.difficultesMobilite, icon: Icons.accessible_outlined),
                if (patient.contactUrgence != null && !patient.contactUrgence!.estVide)
                  _CarteContactUrgence(contact: patient.contactUrgence!),
                const SizedBox(height: AppSpacing.lg),
                SectionTitle(titre: 'Derniers rapports'),
              ],
            ),
          ),
        ),
        rapportsAsync.when(
          loading: () => const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (err, st) => SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text('Impossible de charger les rapports.', style: Theme.of(context).textTheme.bodySmall),
            ),
          ),
          data: (rapports) {
            if (rapports.isEmpty) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Text('Aucun rapport pour ce patient pour le moment.', style: Theme.of(context).textTheme.bodySmall),
                ),
              );
            }
            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
              sliver: SliverList.builder(
                itemCount: rapports.length > 5 ? 5 : rapports.length,
                itemBuilder: (context, index) => _RapportLigne(rapport: rapports[index]),
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
                      interlocuteurNom: patient.nomComplet,
                      interlocuteurSousTitre: patient.pathologie,
                    ),
                  ),
                ),
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Discuter avec ce patient'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EnTete extends StatelessWidget {
  final Patient patient;

  const _EnTete({required this.patient});

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
          AppCircleIconButton(
            icon: Icons.arrow_back,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white.withOpacity(0.18),
                child: Text(
                  _initiales(patient.nomComplet),
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.nomComplet,
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (patient.age != null) '${patient.age} ans',
                        patient.pathologie,
                      ].where((s) => s.isNotEmpty).join(' · '),
                      style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  patient.adresse,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
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

class _CarteAvsAssigne extends StatelessWidget {
  final Patient patient;

  const _CarteAvsAssigne({required this.patient});

  @override
  Widget build(BuildContext context) {
    final assigne = patient.avsAssigneId != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          InitialsAvatar(nomComplet: patient.avsAssigneNom ?? '?', couleur: assigne ? AppColors.primary : AppColors.textDisabled),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AVS en charge', style: Theme.of(context).textTheme.bodySmall),
                Text(
                  patient.avsAssigneNom ?? 'Aucun AVS assigné',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          if (assigne)
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
              onPressed: () => context.push(AppRoutes.coordonnateurAvsDetail(patient.avsAssigneId!)),
            )
          else
            TextButton.icon(
              onPressed: () => context.push(AppRoutes.coordonnateurAffectations),
              icon: const Icon(Icons.assignment_ind_outlined, size: 18),
              label: const Text('Assigner'),
            ),
        ],
      ),
    );
  }
}

class _SectionAntecedents extends StatelessWidget {
  final String titre;
  final List<String> items;
  final IconData icon;

  const _SectionAntecedents({required this.titre, required this.items, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titre, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 15)),
          const SizedBox(height: AppSpacing.sm),
          if (items.isEmpty)
            Text('Aucun renseigné.', style: Theme.of(context).textTheme.bodySmall)
          else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final item in items)
                  Chip(
                    avatar: Icon(icon, size: 16, color: AppColors.primary),
                    label: Text(item),
                    backgroundColor: AppColors.surfaceMuted,
                    side: BorderSide.none,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _CarteContactUrgence extends StatelessWidget {
  final ContactUrgence contact;

  const _CarteContactUrgence({required this.contact});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.secondarySurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          const Icon(Icons.emergency_outlined, color: AppColors.secondaryDark),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Contact d\'urgence', style: Theme.of(context).textTheme.bodySmall),
                Text(
                  [contact.nom, contact.lien].where((s) => s != null && s.isNotEmpty).join(' · '),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (contact.telephone != null) Text(contact.telephone!),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RapportLigne extends StatelessWidget {
  final RapportAvs rapport;

  const _RapportLigne({required this.rapport});

  @override
  Widget build(BuildContext context) {
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rapport.resume, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(_formaterDate(rapport.date), style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          StatusChip(label: rapport.statut.libelle, couleur: rapport.statut.couleur),
        ],
      ),
    );
  }

  String _formaterDate(DateTime date) {
    const mois = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];
    return '${date.day} ${mois[date.month - 1]} ${date.year}';
  }
}

class _ErreurChargement extends StatelessWidget {
  final String message;
  final VoidCallback onReessayer;

  const _ErreurChargement({required this.message, required this.onReessayer});

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
            Text('Impossible de charger la fiche patient.', textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            FilledButton(onPressed: onReessayer, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}
