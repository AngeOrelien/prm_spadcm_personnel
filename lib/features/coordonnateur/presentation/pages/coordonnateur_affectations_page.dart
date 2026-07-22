import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../shared/widgets/misc/app_circle_icon_button.dart';
import '../../domain/entities/coordonnateur_entities.dart';
import '../providers/coordonnateur_providers.dart';
import '../widgets/coordonnateur_widgets.dart';

/// Page plein écran (ouverte via le menu d'actions rapides ou depuis une
/// fiche patient/AVS) : créer une nouvelle affectation AVS ↔ patient à
/// partir d'un calendrier (au lieu d'une simple saisie manuelle de date), et
/// consulter les affectations déjà en place.
class CoordonnateurAffectationsPage extends ConsumerStatefulWidget {
  const CoordonnateurAffectationsPage({super.key});

  @override
  ConsumerState<CoordonnateurAffectationsPage> createState() => _CoordonnateurAffectationsPageState();
}

class _CoordonnateurAffectationsPageState extends ConsumerState<CoordonnateurAffectationsPage> {
  String? _patientId;
  String? _avsId;
  final _frequenceCtrl = TextEditingController(text: '3x / semaine');

  DateTime _moisAffiche = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _dateDebut = DateTime.now();
  bool _enregistrement = false;

  @override
  void dispose() {
    _frequenceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patientsAsync = ref.watch(patientsListProvider);
    final avsAsync = ref.watch(avsListProvider);
    final affectationsAsync = ref.watch(affectationsListProvider);

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.md),
          child: AppCircleIconButton(icon: Icons.arrow_back, onPressed: () => Navigator.of(context).maybePop()),
        ),
        title: const Text('Affectations'),
      ),
      body: affectationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => _ErreurChargement(onReessayer: () => ref.invalidate(affectationsListProvider)),
        data: (affectations) => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text('Choisir la date de début', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16)),
            const SizedBox(height: AppSpacing.sm),
            _CalendrierAffectations(
              moisAffiche: _moisAffiche,
              dateSelectionnee: _dateDebut,
              affectations: affectations,
              onMoisChange: (m) => setState(() => _moisAffiche = m),
              onJourSelectionne: (d) => setState(() => _dateDebut = d),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            Text('Nouvelle affectation', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16)),
            const SizedBox(height: 4),
            Text(
              'Débute le ${_formaterDateLongue(_dateDebut)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.sm),
            patientsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (err, st) => const Text('Impossible de charger les patients.'),
              data: (patients) => DropdownButtonFormField<String>(
                value: _patientId,
                decoration: const InputDecoration(labelText: 'Patient'),
                items: [
                  for (final p in patients) DropdownMenuItem(value: p.id, child: Text(p.nomComplet)),
                ],
                onChanged: (v) => setState(() => _patientId = v),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            avsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (err, st) => const Text('Impossible de charger l\'équipe AVS.'),
              data: (avsListe) => DropdownButtonFormField<String>(
                value: _avsId,
                decoration: const InputDecoration(labelText: 'AVS'),
                items: [
                  for (final a in avsListe)
                    DropdownMenuItem(value: a.id, child: Text('${a.nomComplet} (${a.statut.libelle})')),
                ],
                onChanged: (v) => setState(() => _avsId = v),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _frequenceCtrl,
              decoration: const InputDecoration(labelText: 'Fréquence des visites'),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: (_patientId == null || _avsId == null || _enregistrement) ? null : _creerAffectation,
                icon: _enregistrement
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check),
                label: Text(_enregistrement ? 'Création…' : 'Créer l\'affectation'),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            Text('Affectations en cours', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16)),
            const SizedBox(height: AppSpacing.sm),
            if (affectations.where((a) => a.active).isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Text('Aucune affectation active pour le moment.', style: Theme.of(context).textTheme.bodySmall),
              )
            else
              for (final affectation in affectations.where((a) => a.active))
                _AffectationTile(
                  affectation: affectation,
                  onTerminer: () => _terminerAffectation(affectation),
                ),
          ],
        ),
      ),
    );
  }

  Future<void> _creerAffectation() async {
    setState(() => _enregistrement = true);
    try {
      await ref.read(coordonnateurActionsProvider).creerAffectation(
            patientId: _patientId!,
            avsId: _avsId!,
            frequence: _frequenceCtrl.text.trim().isEmpty ? 'À définir' : _frequenceCtrl.text.trim(),
            dateDebut: _dateDebut,
          );
      if (!mounted) return;
      context.showInfo('Affectation créée avec succès.');
      setState(() {
        _patientId = null;
        _avsId = null;
      });
    } catch (e) {
      if (!mounted) return;
      context.showError('$e');
    } finally {
      if (mounted) setState(() => _enregistrement = false);
    }
  }

  Future<void> _terminerAffectation(Affectation affectation) async {
    try {
      await ref.read(coordonnateurActionsProvider).terminerAffectation(affectation.id, patientId: affectation.patientId);
      if (!mounted) return;
      context.showInfo('Affectation terminée.');
    } catch (e) {
      if (!mounted) return;
      context.showError('$e');
    }
  }

  String _formaterDateLongue(DateTime date) {
    const mois = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
    ];
    return '${date.day} ${mois[date.month - 1]} ${date.year}';
  }
}

/// Calendrier mensuel maison (aucune dépendance externe) : navigation
/// mois précédent/suivant, sélection d'un jour (date de début de la
/// nouvelle affectation), et un petit point sous les jours où au moins une
/// affectation existante a démarré, pour donner un vrai contexte visuel.
class _CalendrierAffectations extends StatelessWidget {
  final DateTime moisAffiche;
  final DateTime dateSelectionnee;
  final List<Affectation> affectations;
  final ValueChanged<DateTime> onMoisChange;
  final ValueChanged<DateTime> onJourSelectionne;

  const _CalendrierAffectations({
    required this.moisAffiche,
    required this.dateSelectionnee,
    required this.affectations,
    required this.onMoisChange,
    required this.onJourSelectionne,
  });

  static const _nomsMois = [
    'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
  ];
  static const _nomsJours = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  bool _memeJour(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final premierJourDuMois = DateTime(moisAffiche.year, moisAffiche.month, 1);
    final decalage = premierJourDuMois.weekday - 1; // Lundi = 0
    final joursDansLeMois = DateTime(moisAffiche.year, moisAffiche.month + 1, 0).day;
    final aujourdHui = DateTime.now();

    final joursMarques = affectations.map((a) => a.depuisLe).toList();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => onMoisChange(DateTime(moisAffiche.year, moisAffiche.month - 1)),
              ),
              Expanded(
                child: Text(
                  '${_nomsMois[moisAffiche.month - 1]} ${moisAffiche.year}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => onMoisChange(DateTime(moisAffiche.year, moisAffiche.month + 1)),
              ),
            ],
          ),
          Row(
            children: [
              for (final j in _nomsJours)
                Expanded(
                  child: Center(
                    child: Text(j, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
            itemCount: decalage + joursDansLeMois,
            itemBuilder: (context, index) {
              if (index < decalage) return const SizedBox.shrink();
              final jour = index - decalage + 1;
              final date = DateTime(moisAffiche.year, moisAffiche.month, jour);
              final estSelectionne = _memeJour(date, dateSelectionnee);
              final estAujourdHui = _memeJour(date, aujourdHui);
              final aUneAffectation = joursMarques.any((d) => _memeJour(d, date));

              return Padding(
                padding: const EdgeInsets.all(2),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  onTap: () => onJourSelectionne(date),
                  child: Container(
                    decoration: BoxDecoration(
                      color: estSelectionne ? AppColors.primary : Colors.transparent,
                      shape: BoxShape.circle,
                      border: estAujourdHui && !estSelectionne ? Border.all(color: AppColors.primary) : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$jour',
                          style: TextStyle(
                            color: estSelectionne ? Colors.white : AppColors.textPrimary,
                            fontWeight: estSelectionne || estAujourdHui ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                        if (aUneAffectation)
                          Container(
                            margin: const EdgeInsets.only(top: 1),
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: estSelectionne ? Colors.white : AppColors.secondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AffectationTile extends StatelessWidget {
  final Affectation affectation;
  final VoidCallback onTerminer;

  const _AffectationTile({required this.affectation, required this.onTerminer});

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
          const Icon(Icons.sync_alt, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${affectation.patientNom ?? '—'}  ↔  ${affectation.avsNom ?? '—'}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(affectation.frequence, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Terminer l\'affectation',
            icon: const Icon(Icons.close, color: AppColors.error),
            onPressed: onTerminer,
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
            const Text('Impossible de charger les affectations.', textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            FilledButton(onPressed: onReessayer, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}
