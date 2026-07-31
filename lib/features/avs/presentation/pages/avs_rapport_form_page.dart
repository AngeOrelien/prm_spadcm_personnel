import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../shared/widgets/misc/app_circle_icon_button.dart';
import '../../../../shared/widgets/dashboard/dashboard_widgets.dart';
import '../../../dashboard/presentation/widgets/app_dashboard_header.dart';
import '../providers/avs_providers.dart';

/// Formulaire structuré de rapport journalier — fidèle à la fiche terrain
/// (constantes, alimentation, médicaments, soins/tâches, observations,
/// conclusion), rempli en plusieurs étapes plutôt qu'en un seul long
/// formulaire, avec une prévisualisation + confirmation avant envoi.
///
/// Le patient concerné n'est PLUS un choix libre de l'AVS : c'est
/// systématiquement le patient auquel il est affecté (`patientId` envoyé au
/// serveur), lu depuis [widget.patientIdPreselectionne] (passé par l'onglet
/// "Mon patient") ou déduit de `mesPatientsProvider` si l'AVS n'a qu'un seul
/// patient actif — jamais une liste déroulante où n'importe quel patient du
/// système pourrait être sélectionné par erreur.
///
/// Saisi hors-ligne si besoin : si l'envoi échoue faute de connexion, le
/// rapport n'est pas perdu — il est gardé localement et réapparaît en tête
/// de "Mes rapports" avec un bouton "Réessayer" (voir `AvsActions.
/// creerRapport` / `RapportsLocauxService`).
///
/// Les champs `parametresVitaux` et `medicamentsAdministres` sont envoyés
/// comme des LISTES D'OBJETS, et `alimentation` comme un OBJET unique — le
/// backend (`RapportJournalier`, Mongoose) les modélise en sous-documents
/// embarqués et rejette une simple chaîne de caractères (voir
/// `BACKEND-TODO.md`, erreurs `CastError`/`ObjectParameterError` observées
/// avant ce correctif).
class AvsRapportFormPage extends ConsumerStatefulWidget {
  /// Patient présélectionné (ex: bouton "Nouveau rapport" depuis l'onglet
  /// "Mon patient", où le patient concerné est déjà connu).
  final String? patientIdPreselectionne;

  const AvsRapportFormPage({super.key, this.patientIdPreselectionne});

  @override
  ConsumerState<AvsRapportFormPage> createState() => _AvsRapportFormPageState();
}

class _MesureVitale {
  // Obligatoire côté backend (`RapportJournalier.parametresVitaux[].moment`,
  // enum ['matin', 'soir'], `required: true`) — son absence ici est la cause
  // du 500 renvoyé par le serveur dès qu'un AVS renseignait une constante
  // (erreur de validation Mongoose, jamais remontée proprement avant la
  // correction de `errorMiddleware.js`). Premier relevé par défaut "matin",
  // les suivants "soir", modifiable via le sélecteur du formulaire.
  String moment;
  final temperature = TextEditingController();
  final tension = TextEditingController();
  final pouls = TextEditingController();
  final saturation = TextEditingController();
  final notes = TextEditingController();

  _MesureVitale({this.moment = 'matin'});

  bool get estVide =>
      temperature.text.trim().isEmpty &&
      tension.text.trim().isEmpty &&
      pouls.text.trim().isEmpty &&
      saturation.text.trim().isEmpty &&
      notes.text.trim().isEmpty;

  // Noms de champs alignés sur `parametresVitauxSchema` (backend) : avant ce
  // correctif, `tensionArterielle`/`saturationOxygene` ne correspondaient à
  // aucun champ du schéma et étaient silencieusement ignorés par Mongoose
  // (perte de données, sans erreur) — voir `taBrasDroit`/`spo2` ci-dessous.
  Map<String, dynamic> toJson() => {
        'moment': moment,
        if (temperature.text.trim().isNotEmpty) 'temperature': temperature.text.trim(),
        if (tension.text.trim().isNotEmpty) 'taBrasDroit': tension.text.trim(),
        if (pouls.text.trim().isNotEmpty) 'pouls': pouls.text.trim(),
        if (saturation.text.trim().isNotEmpty) 'spo2': saturation.text.trim(),
        if (notes.text.trim().isNotEmpty) 'notes': notes.text.trim(),
      };

  void dispose() {
    temperature.dispose();
    tension.dispose();
    pouls.dispose();
    saturation.dispose();
    notes.dispose();
  }
}

class _Medicament {
  final nom = TextEditingController();
  final dosage = TextEditingController();
  final heure = TextEditingController();

  bool get estVide => nom.text.trim().isEmpty && dosage.text.trim().isEmpty && heure.text.trim().isEmpty;

  Map<String, dynamic> toJson() => {
        if (nom.text.trim().isNotEmpty) 'nom': nom.text.trim(),
        if (dosage.text.trim().isNotEmpty) 'dosage': dosage.text.trim(),
        if (heure.text.trim().isNotEmpty) 'heure': heure.text.trim(),
      };

  void dispose() {
    nom.dispose();
    dosage.dispose();
    heure.dispose();
  }
}

class _AvsRapportFormPageState extends ConsumerState<AvsRapportFormPage> {
  final _pageCtrl = PageController();
  int _etape = 0;
  bool _envoi = false;

  final List<_MesureVitale> _mesures = [_MesureVitale()];
  final List<_Medicament> _medicaments = [_Medicament()];

  // Alimentation : objet unique (voir doc en tête de fichier).
  final _petitDejeunerCtrl = TextEditingController();
  final _dejeunerCtrl = TextEditingController();
  final _dinerCtrl = TextEditingController();
  final _hydratationCtrl = TextEditingController();
  String _appetit = 'bon';

  final _soinsCtrl = TextEditingController();
  final _observationsCtrl = TextEditingController();
  final _conclusionCtrl = TextEditingController();

  static const _titresEtapes = [
    'Constantes',
    'Alimentation',
    'Médicaments',
    'Soins & conclusion',
    'Aperçu',
  ];

  @override
  void dispose() {
    _pageCtrl.dispose();
    for (final m in _mesures) {
      m.dispose();
    }
    for (final m in _medicaments) {
      m.dispose();
    }
    _petitDejeunerCtrl.dispose();
    _dejeunerCtrl.dispose();
    _dinerCtrl.dispose();
    _hydratationCtrl.dispose();
    _soinsCtrl.dispose();
    _observationsCtrl.dispose();
    _conclusionCtrl.dispose();
    super.dispose();
  }

  void _allerA(int index) {
    setState(() => _etape = index);
    _pageCtrl.animateToPage(index, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  void _suivant() {
    if (_etape < _titresEtapes.length - 1) _allerA(_etape + 1);
  }

  void _precedent() {
    if (_etape > 0) _allerA(_etape - 1);
  }

  Map<String, dynamic> _construireCorps(String patientId) {
    return {
      'patientId': patientId,
      'heureSaisie': DateTime.now().toIso8601String(),
      'parametresVitaux': _mesures.where((m) => !m.estVide).map((m) => m.toJson()).toList(),
      'alimentation': {
        if (_petitDejeunerCtrl.text.trim().isNotEmpty) 'petitDejeuner': _petitDejeunerCtrl.text.trim(),
        if (_dejeunerCtrl.text.trim().isNotEmpty) 'dejeuner': _dejeunerCtrl.text.trim(),
        if (_dinerCtrl.text.trim().isNotEmpty) 'diner': _dinerCtrl.text.trim(),
        if (_hydratationCtrl.text.trim().isNotEmpty) 'hydratation': _hydratationCtrl.text.trim(),
        'appetit': _appetit,
      },
      'medicamentsAdministres': _medicaments.where((m) => !m.estVide).map((m) => m.toJson()).toList(),
      'soinsTaches': _soinsCtrl.text.trim(),
      'observations': _observationsCtrl.text.trim(),
      'conclusion': _conclusionCtrl.text.trim(),
    };
  }

  Future<bool> _confirmerEnvoi() async {
    final resultat = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Envoyer ce rapport ?'),
        content: const Text(
          'Vérifie que les informations saisies sont correctes. Une fois envoyé, le rapport sera transmis '
          'à la coordination et son heure de remise sera enregistrée.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Confirmer et envoyer')),
        ],
      ),
    );
    return resultat ?? false;
  }

  Future<void> _envoyer(String patientId, String patientNom) async {
    final confirme = await _confirmerEnvoi();
    if (!confirme || !mounted) return;

    setState(() => _envoi = true);
    try {
      await ref.read(avsActionsProvider).creerRapport(_construireCorps(patientId), patientNom: patientNom);
      if (mounted) {
        context.showInfo('Rapport envoyé. Il sera marqué à temps ou en retard selon l\'heure de saisie.');
        Navigator.of(context).maybePop();
      }
    } on RapportEnregistreLocalementException {
      if (mounted) {
        context.showInfo(
          'Pas de connexion au serveur : ton rapport est enregistré et visible dans "Mes rapports". '
          'Il sera envoyé automatiquement dès que la connexion revient (ou via le bouton "Réessayer").',
        );
        Navigator.of(context).maybePop();
      }
    } catch (e) {
      if (mounted) context.showError('$e');
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientsAsync = ref.watch(mesPatientsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        top: false,
        child: Column(
          children: [
            AppDashboardHeader.page(
              title: 'Nouveau rapport',
              subtitle: 'Étape ${_etape + 1}/${_titresEtapes.length} · ${_titresEtapes[_etape]}',
              leadingIcon: Icons.note_add_outlined,
              showBackButton: true,
            ),
            const Divider(height: 1),
            _BarreEtapes(etapeActuelle: _etape, titres: _titresEtapes, onTap: _allerA),
            Expanded(
              child: patientsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, st) => ErreurChargement(onReessayer: () => ref.invalidate(mesPatientsProvider)),
                data: (patients) {
                  // Le patient n'est jamais un choix libre : présélectionné
                  // depuis "Mon patient", ou déduit automatiquement si
                  // l'AVS n'a qu'un seul patient actif.
                  String? patientId = widget.patientIdPreselectionne;
                  String patientNom = '';
                  if (patientId != null) {
                    final trouve = patients.where((p) => p.id == patientId);
                    patientNom = trouve.isNotEmpty ? trouve.first.nomComplet : '';
                  } else if (patients.length == 1) {
                    patientId = patients.first.id;
                    patientNom = patients.first.nomComplet;
                  }

                  if (patientId == null) {
                    return Center(
                      child: EmptyStateCard(
                        icon: Icons.person_search_outlined,
                        titre: patients.isEmpty ? 'Aucun patient assigné' : 'Plusieurs patients assignés',
                        message: patients.isEmpty
                            ? 'Aucun patient ne t\'est actuellement affecté : un rapport ne peut pas être créé.'
                            : 'Ouvre la fiche du patient concerné depuis l\'onglet "Mon patient" puis '
                                'utilise le bouton "Nouveau rapport" à partir de là.',
                        action: FilledButton(onPressed: () => Navigator.of(context).maybePop(), child: const Text('Retour')),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
                        child: _PatientFige(nom: patientNom),
                      ),
                      Expanded(
                        child: PageView(
                          controller: _pageCtrl,
                          physics: const NeverScrollableScrollPhysics(),
                          onPageChanged: (i) => setState(() => _etape = i),
                          children: [
                            _EtapeConstantes(mesures: _mesures, onChanged: () => setState(() {})),
                            _EtapeAlimentation(
                              petitDejeuner: _petitDejeunerCtrl,
                              dejeuner: _dejeunerCtrl,
                              diner: _dinerCtrl,
                              hydratation: _hydratationCtrl,
                              appetit: _appetit,
                              onAppetitChanged: (v) => setState(() => _appetit = v),
                            ),
                            _EtapeMedicaments(medicaments: _medicaments, onChanged: () => setState(() {})),
                            _EtapeSoinsConclusion(
                              soins: _soinsCtrl,
                              observations: _observationsCtrl,
                              conclusion: _conclusionCtrl,
                            ),
                            _EtapeApercu(
                              patientNom: patientNom,
                              mesures: _mesures,
                              petitDejeuner: _petitDejeunerCtrl.text,
                              dejeuner: _dejeunerCtrl.text,
                              diner: _dinerCtrl.text,
                              hydratation: _hydratationCtrl.text,
                              appetit: _appetit,
                              medicaments: _medicaments,
                              soins: _soinsCtrl.text,
                              observations: _observationsCtrl.text,
                              conclusion: _conclusionCtrl.text,
                            ),
                          ],
                        ),
                      ),
                      _BarreNavigation(
                        etape: _etape,
                        derniere: _titresEtapes.length - 1,
                        envoi: _envoi,
                        onPrecedent: _precedent,
                        onSuivant: _suivant,
                        onEnvoyer: () => _envoyer(patientId!, patientNom),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PatientFige extends StatelessWidget {
  final String nom;

  const _PatientFige({required this.nom});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          const Icon(Icons.person, size: 18, color: AppColors.primaryDark),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              nom.isEmpty ? 'Patient assigné' : 'Rapport pour $nom',
              style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w600, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(Icons.lock_outline, size: 14, color: AppColors.primaryDark),
        ],
      ),
    );
  }
}

class _BarreEtapes extends StatelessWidget {
  final int etapeActuelle;
  final List<String> titres;
  final ValueChanged<int> onTap;

  const _BarreEtapes({required this.etapeActuelle, required this.titres, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: Row(
        children: [
          for (int i = 0; i < titres.length; i++) ...[
            Expanded(
              child: GestureDetector(
                onTap: i <= etapeActuelle ? () => onTap(i) : null,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: i <= etapeActuelle ? AppColors.primary : AppColors.border,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
            ),
            if (i != titres.length - 1) const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }
}

class _BarreNavigation extends StatelessWidget {
  final int etape;
  final int derniere;
  final bool envoi;
  final VoidCallback onPrecedent;
  final VoidCallback onSuivant;
  final VoidCallback onEnvoyer;

  const _BarreNavigation({
    required this.etape,
    required this.derniere,
    required this.envoi,
    required this.onPrecedent,
    required this.onSuivant,
    required this.onEnvoyer,
  });

  @override
  Widget build(BuildContext context) {
    final estDerniere = etape == derniere;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            if (etape > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: envoi ? null : onPrecedent,
                  child: const Text('Précédent'),
                ),
              ),
            if (etape > 0) const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: envoi ? null : (estDerniere ? onEnvoyer : onSuivant),
                child: envoi
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(estDerniere ? 'Envoyer le rapport' : 'Suivant'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EtapeConstantes extends StatelessWidget {
  final List<_MesureVitale> mesures;
  final VoidCallback onChanged;

  const _EtapeConstantes({required this.mesures, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          'Renseigne les constantes relevées (température, tension, pouls, saturation). '
          'Tu peux ajouter plusieurs relevés si plusieurs mesures ont été prises dans la journée.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        for (int i = 0; i < mesures.length; i++)
          _CarteSupprimable(
            titre: 'Relevé ${i + 1}',
            supprimable: mesures.length > 1,
            onSupprimer: () {
              mesures[i].dispose();
              mesures.removeAt(i);
              onChanged();
            },
            child: Column(
              children: [
                _SelecteurMoment(
                  valeur: mesures[i].moment,
                  onChanged: (v) {
                    mesures[i].moment = v;
                    onChanged();
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(child: _MiniChamp(label: 'Température (°C)', controller: mesures[i].temperature)),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: _MiniChamp(label: 'Tension artérielle', controller: mesures[i].tension)),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(child: _MiniChamp(label: 'Pouls (bpm)', controller: mesures[i].pouls)),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: _MiniChamp(label: 'Saturation O₂ (%)', controller: mesures[i].saturation)),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                _MiniChamp(label: 'Observations sur ce relevé', controller: mesures[i].notes, lignes: 2),
              ],
            ),
          ),
        OutlinedButton.icon(
          onPressed: () {
            mesures.add(_MesureVitale(moment: mesures.length.isEven ? 'matin' : 'soir'));
            onChanged();
          },
          icon: const Icon(Icons.add),
          label: const Text('Ajouter un relevé'),
        ),
      ],
    );
  }
}

class _SelecteurMoment extends StatelessWidget {
  final String valeur;
  final ValueChanged<String> onChanged;

  const _SelecteurMoment({required this.valeur, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'matin', label: Text('Matin'), icon: Icon(Icons.wb_sunny_outlined, size: 16)),
        ButtonSegment(value: 'soir', label: Text('Soir'), icon: Icon(Icons.nightlight_outlined, size: 16)),
      ],
      selected: {valeur},
      onSelectionChanged: (nouvelle) => onChanged(nouvelle.first),
      showSelectedIcon: false,
      style: const ButtonStyle(visualDensity: VisualDensity.compact),
    );
  }
}

class _EtapeAlimentation extends StatelessWidget {
  final TextEditingController petitDejeuner;
  final TextEditingController dejeuner;
  final TextEditingController diner;
  final TextEditingController hydratation;
  final String appetit;
  final ValueChanged<String> onAppetitChanged;

  const _EtapeAlimentation({
    required this.petitDejeuner,
    required this.dejeuner,
    required this.diner,
    required this.hydratation,
    required this.appetit,
    required this.onAppetitChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          'Décris ce que le patient a mangé et bu au cours de la journée.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        _MiniChamp(label: 'Petit-déjeuner', controller: petitDejeuner, lignes: 2),
        const SizedBox(height: AppSpacing.md),
        _MiniChamp(label: 'Déjeuner', controller: dejeuner, lignes: 2),
        const SizedBox(height: AppSpacing.md),
        _MiniChamp(label: 'Dîner', controller: diner, lignes: 2),
        const SizedBox(height: AppSpacing.md),
        _MiniChamp(label: 'Hydratation (quantité, type de boisson...)', controller: hydratation, lignes: 2),
        const SizedBox(height: AppSpacing.md),
        Text('Appétit général', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            for (final option in const [('bon', 'Bon'), ('moyen', 'Moyen'), ('faible', 'Faible')])
              ChoiceChip(
                label: Text(option.$2),
                selected: appetit == option.$1,
                onSelected: (_) => onAppetitChanged(option.$1),
              ),
          ],
        ),
      ],
    );
  }
}

class _EtapeMedicaments extends StatelessWidget {
  final List<_Medicament> medicaments;
  final VoidCallback onChanged;

  const _EtapeMedicaments({required this.medicaments, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          'Liste les médicaments administrés (nom, dosage, heure). Ajoute une ligne par médicament.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        for (int i = 0; i < medicaments.length; i++)
          _CarteSupprimable(
            titre: 'Médicament ${i + 1}',
            supprimable: medicaments.length > 1,
            onSupprimer: () {
              medicaments[i].dispose();
              medicaments.removeAt(i);
              onChanged();
            },
            child: Column(
              children: [
                _MiniChamp(label: 'Nom du médicament', controller: medicaments[i].nom),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(child: _MiniChamp(label: 'Dosage', controller: medicaments[i].dosage)),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: _MiniChamp(label: 'Heure (ex: 08:00)', controller: medicaments[i].heure)),
                  ],
                ),
              ],
            ),
          ),
        OutlinedButton.icon(
          onPressed: () {
            medicaments.add(_Medicament());
            onChanged();
          },
          icon: const Icon(Icons.add),
          label: const Text('Ajouter un médicament'),
        ),
      ],
    );
  }
}

class _EtapeSoinsConclusion extends StatelessWidget {
  final TextEditingController soins;
  final TextEditingController observations;
  final TextEditingController conclusion;

  const _EtapeSoinsConclusion({required this.soins, required this.observations, required this.conclusion});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _MiniChamp(label: 'Soins / tâches réalisées', controller: soins, lignes: 3),
        const SizedBox(height: AppSpacing.md),
        _MiniChamp(label: 'Observations générales', controller: observations, lignes: 3),
        const SizedBox(height: AppSpacing.md),
        _MiniChamp(label: 'Conclusion de la visite', controller: conclusion, lignes: 3),
      ],
    );
  }
}

class _EtapeApercu extends StatelessWidget {
  final String patientNom;
  final List<_MesureVitale> mesures;
  final String petitDejeuner;
  final String dejeuner;
  final String diner;
  final String hydratation;
  final String appetit;
  final List<_Medicament> medicaments;
  final String soins;
  final String observations;
  final String conclusion;

  const _EtapeApercu({
    required this.patientNom,
    required this.mesures,
    required this.petitDejeuner,
    required this.dejeuner,
    required this.diner,
    required this.hydratation,
    required this.appetit,
    required this.medicaments,
    required this.soins,
    required this.observations,
    required this.conclusion,
  });

  @override
  Widget build(BuildContext context) {
    final mesuresRemplies = mesures.where((m) => !m.estVide).toList();
    final medicamentsRemplis = medicaments.where((m) => !m.estVide).toList();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          'Vérifie les informations avant l\'envoi — tu peux revenir en arrière avec "Précédent" pour corriger.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        _SectionApercu(
          titre: 'Constantes',
          contenu: mesuresRemplies.isEmpty
              ? 'Aucune constante renseignée.'
              : mesuresRemplies
                  .map((m) => [
                        m.moment == 'matin' ? 'Matin' : 'Soir',
                        if (m.temperature.text.trim().isNotEmpty) 'Température ${m.temperature.text.trim()}°C',
                        if (m.tension.text.trim().isNotEmpty) 'Tension ${m.tension.text.trim()}',
                        if (m.pouls.text.trim().isNotEmpty) 'Pouls ${m.pouls.text.trim()}',
                        if (m.saturation.text.trim().isNotEmpty) 'SpO₂ ${m.saturation.text.trim()}%',
                      ].join(' · '))
                  .join('\n'),
        ),
        _SectionApercu(
          titre: 'Alimentation',
          contenu: [
            if (petitDejeuner.trim().isNotEmpty) 'Petit-déjeuner : ${petitDejeuner.trim()}',
            if (dejeuner.trim().isNotEmpty) 'Déjeuner : ${dejeuner.trim()}',
            if (diner.trim().isNotEmpty) 'Dîner : ${diner.trim()}',
            if (hydratation.trim().isNotEmpty) 'Hydratation : ${hydratation.trim()}',
            'Appétit : $appetit',
          ].join('\n'),
        ),
        _SectionApercu(
          titre: 'Médicaments administrés',
          contenu: medicamentsRemplis.isEmpty
              ? 'Aucun médicament renseigné.'
              : medicamentsRemplis
                  .map((m) => [m.nom.text.trim(), m.dosage.text.trim(), m.heure.text.trim()]
                      .where((s) => s.isNotEmpty)
                      .join(' · '))
                  .join('\n'),
        ),
        _SectionApercu(titre: 'Soins / tâches réalisées', contenu: soins.trim().isEmpty ? '—' : soins.trim()),
        _SectionApercu(titre: 'Observations', contenu: observations.trim().isEmpty ? '—' : observations.trim()),
        _SectionApercu(titre: 'Conclusion', contenu: conclusion.trim().isEmpty ? '—' : conclusion.trim()),
      ],
    );
  }
}

class _SectionApercu extends StatelessWidget {
  final String titre;
  final String contenu;

  const _SectionApercu({required this.titre, required this.contenu});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titre, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primaryDark)),
          const SizedBox(height: 6),
          Text(contenu, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _CarteSupprimable extends StatelessWidget {
  final String titre;
  final bool supprimable;
  final VoidCallback onSupprimer;
  final Widget child;

  const _CarteSupprimable({
    required this.titre,
    required this.supprimable,
    required this.onSupprimer,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(titre, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
              if (supprimable)
                AppCircleIconButton(icon: Icons.delete_outline, onPressed: onSupprimer),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _MiniChamp extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final int lignes;

  const _MiniChamp({required this.label, required this.controller, this.lignes = 1});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: lignes,
      decoration: InputDecoration(labelText: label, isDense: true),
    );
  }
}
