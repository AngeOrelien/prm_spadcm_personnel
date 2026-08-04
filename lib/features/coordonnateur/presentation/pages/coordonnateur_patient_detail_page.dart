import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/utils/location_service.dart';
import '../../../../router/app_routes.dart';
import '../../../../shared/widgets/misc/app_circle_icon_button.dart';
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

class _Contenu extends ConsumerStatefulWidget {
  final Patient patient;
  final AsyncValue<List<RapportAvs>> rapportsAsync;

  const _Contenu({required this.patient, required this.rapportsAsync});

  @override
  ConsumerState<_Contenu> createState() => _ContenuState();
}

class _ContenuState extends ConsumerState<_Contenu> {
  bool _ouvertureConversationEnCours = false;

  Future<void> _discuter() async {
    if (_ouvertureConversationEnCours) return;
    final patient = widget.patient;
    setState(() => _ouvertureConversationEnCours = true);
    final compteId = patient.compteUtilisateurId;
    if (compteId == null) return; // bouton désactivé dans ce cas, voir build() ci-dessous
    try {
      // Le contact "patient" côté messagerie est le compte utilisateur lié
      // au patient (`compteUtilisateurId`), pas l'id de la fiche patient
      // elle-même — voir `Patient.compteUtilisateurId`.
      final conversation = await ref.read(coordonnateurActionsProvider).ouvrirConversationAvec(
            compteId,
            patientContexteId: patient.id,
          );
      if (!mounted) return;
      context.push(
        AppRoutes.coordonnateurMessagerieConversation(conversation.id),
        extra: {
          'conversationId': conversation.id,
          'nom': patient.nomComplet,
          'sousTitre': patient.pathologie,
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
    final patient = widget.patient;
    final rapportsAsync = widget.rapportsAsync;
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
                _CarteLocalisation(patient: patient),
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
                onPressed: (_ouvertureConversationEnCours || patient.compteUtilisateurId == null) ? null : _discuter,
                icon: _ouvertureConversationEnCours
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.chat_bubble_outline),
                label: Text(patient.compteUtilisateurId == null ? 'Pas de compte de connexion' : 'Discuter avec ce patient'),
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
                backgroundImage: (patient.photoUrl != null && patient.photoUrl!.isNotEmpty) ? NetworkImage(patient.photoUrl!) : null,
                onBackgroundImageError: (patient.photoUrl != null && patient.photoUrl!.isNotEmpty) ? (_, __) {} : null,
                child: (patient.photoUrl == null || patient.photoUrl!.isEmpty)
                    ? Text(
                        _initiales(patient.nomComplet),
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600),
                      )
                    : null,
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
              onPressed: () => context.push(AppRoutes.coordonnateurAffectations, extra: {'patientId': patient.id}),
              icon: const Icon(Icons.assignment_ind_outlined, size: 18),
              label: const Text('Assigner'),
            ),
        ],
      ),
    );
  }
}

class _CarteLocalisation extends ConsumerStatefulWidget {
  final Patient patient;

  const _CarteLocalisation({required this.patient});

  @override
  ConsumerState<_CarteLocalisation> createState() => _CarteLocalisationState();
}

class _CarteLocalisationState extends ConsumerState<_CarteLocalisation> {
  bool _enCours = false;

  Future<void> _definirLocalisation() async {
    final resultat = await showDialog<({double latitude, double longitude})>(
      context: context,
      builder: (dialogContext) => _DialogueLocalisation(patient: widget.patient),
    );
    if (resultat == null || !mounted) return;

    setState(() => _enCours = true);
    try {
      await ref.read(coordonnateurActionsProvider).definirLocalisationPatient(
            widget.patient.id,
            latitude: resultat.latitude,
            longitude: resultat.longitude,
          );
      if (!mounted) return;
      context.showInfo('Localisation du domicile enregistrée.');
    } catch (e) {
      if (!mounted) return;
      context.showError('$e');
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final patient = widget.patient;
    final renseignee = patient.aLocalisation;

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
          Icon(
            renseignee ? Icons.location_on : Icons.location_off_outlined,
            color: renseignee ? AppColors.success : AppColors.textDisabled,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Localisation du domicile', style: Theme.of(context).textTheme.bodySmall),
                Text(
                  renseignee
                      ? '${patient.latitude!.toStringAsFixed(5)}, ${patient.longitude!.toStringAsFixed(5)}'
                      : 'Non renseignée — le check-in de l\'AVS ne sera pas vérifié',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          _enCours
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : TextButton(onPressed: _definirLocalisation, child: Text(renseignee ? 'Modifier' : 'Définir')),
        ],
      ),
    );
  }
}

/// Boîte de dialogue de saisie des coordonnées GPS du domicile. Deux façons
/// de renseigner la position : saisie manuelle (latitude/longitude connues
/// à l'avance), ou "Utiliser ma position actuelle" si le coordonnateur se
/// trouve physiquement chez le patient au moment de la saisie.
class _DialogueLocalisation extends StatefulWidget {
  final Patient patient;

  const _DialogueLocalisation({required this.patient});

  @override
  State<_DialogueLocalisation> createState() => _DialogueLocalisationState();
}

class _DialogueLocalisationState extends State<_DialogueLocalisation> {
  late final TextEditingController _latitude;
  late final TextEditingController _longitude;
  bool _recherchePosition = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _latitude = TextEditingController(text: widget.patient.latitude?.toStringAsFixed(6) ?? '');
    _longitude = TextEditingController(text: widget.patient.longitude?.toStringAsFixed(6) ?? '');
  }

  @override
  void dispose() {
    _latitude.dispose();
    _longitude.dispose();
    super.dispose();
  }

  Future<void> _utiliserPositionActuelle() async {
    setState(() {
      _recherchePosition = true;
      _erreur = null;
    });
    try {
      final position = await LocationService.obtenirPositionActuelle();
      setState(() {
        _latitude.text = position.latitude.toStringAsFixed(6);
        _longitude.text = position.longitude.toStringAsFixed(6);
      });
    } on LocationServiceException catch (e) {
      setState(() => _erreur = e.message);
    } finally {
      if (mounted) setState(() => _recherchePosition = false);
    }
  }

  void _valider() {
    final lat = double.tryParse(_latitude.text.trim());
    final lon = double.tryParse(_longitude.text.trim());
    if (lat == null || lon == null || lat < -90 || lat > 90 || lon < -180 || lon > 180) {
      setState(() => _erreur = 'Coordonnées invalides.');
      return;
    }
    Navigator.of(context).pop((latitude: lat, longitude: lon));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Localisation du domicile'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Renseigne les coordonnées GPS du domicile de ${widget.patient.nomComplet}. '
            'Elles servent à vérifier que l\'AVS est bien sur place lors de son check-in.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: _recherchePosition ? null : _utiliserPositionActuelle,
            icon: _recherchePosition
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.my_location),
            label: const Text('Utiliser ma position actuelle'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _latitude,
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            decoration: const InputDecoration(labelText: 'Latitude'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _longitude,
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            decoration: const InputDecoration(labelText: 'Longitude'),
          ),
          if (_erreur != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(_erreur!, style: const TextStyle(color: AppColors.error)),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler')),
        FilledButton(onPressed: _valider, child: const Text('Enregistrer')),
      ],
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
