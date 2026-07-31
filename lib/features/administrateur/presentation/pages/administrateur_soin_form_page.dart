import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../shared/widgets/misc/app_circle_icon_button.dart';
import '../../../../shared/widgets/misc/confirm_action_dialog.dart';
import '../../data/models/administrateur_models.dart';
import '../../domain/entities/administrateur_entities.dart';
import '../providers/administrateur_providers.dart';

/// Création ou édition d'une offre du catalogue de soins SPAD
/// (`soins_catalogue`) — ce que les patients/familles voient dans l'app.
/// La section médias (image de couverture, galerie) n'apparaît qu'une fois
/// le soin créé (il faut un id pour téléverser un fichier), donc la création
/// bascule automatiquement en mode édition juste après l'enregistrement.
class AdministrateurSoinFormPage extends ConsumerStatefulWidget {
  final Soin? soinExistant;

  const AdministrateurSoinFormPage({super.key, this.soinExistant});

  @override
  ConsumerState<AdministrateurSoinFormPage> createState() => _AdministrateurSoinFormPageState();
}

class _AdministrateurSoinFormPageState extends ConsumerState<AdministrateurSoinFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final _nomCtrl = TextEditingController(text: widget.soinExistant?.nom ?? '');
  late final _descriptionCtrl = TextEditingController(text: widget.soinExistant?.description ?? '');
  late final _prixCtrl = TextEditingController(text: widget.soinExistant?.prix.toStringAsFixed(0) ?? '');
  late final _frequenceCtrl = TextEditingController(text: widget.soinExistant?.frequenceVisites ?? '');
  late final _visitesSemaineCtrl = TextEditingController(text: '${widget.soinExistant?.visitesParSemaine ?? 7}');
  late final _dureeCtrl = TextEditingController(text: '${widget.soinExistant?.dureeEngagementJours ?? 30}');
  late final _prestationsCtrl = TextEditingController(text: widget.soinExistant?.prestationsIncluses.join('\n') ?? '');

  Soin? _soinActuel;
  bool _envoi = false;
  bool _televersementEnCours = false;

  @override
  void initState() {
    super.initState();
    _soinActuel = widget.soinExistant;
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _descriptionCtrl.dispose();
    _prixCtrl.dispose();
    _frequenceCtrl.dispose();
    _visitesSemaineCtrl.dispose();
    _dureeCtrl.dispose();
    _prestationsCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> _corpsFormulaire() {
    return SoinModel.toJson(
      nom: _nomCtrl.text.trim(),
      description: _descriptionCtrl.text.trim(),
      prix: double.tryParse(_prixCtrl.text.trim().replaceAll(',', '.')) ?? 0,
      frequenceVisites: _frequenceCtrl.text.trim(),
      visitesParSemaine: int.tryParse(_visitesSemaineCtrl.text.trim()) ?? 7,
      prestationsIncluses: _prestationsCtrl.text
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      dureeEngagementJours: int.tryParse(_dureeCtrl.text.trim()) ?? 30,
    );
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _envoi = true);
    try {
      final actions = ref.read(administrateurActionsProvider);
      if (_soinActuel == null) {
        final soinCree = await actions.creerSoin(_corpsFormulaire());
        if (mounted) {
          setState(() => _soinActuel = soinCree);
          context.showInfo('Soin créé. Ajoute maintenant une image de couverture ci-dessous.');
        }
      } else {
        await actions.modifierSoin(_soinActuel!.id, _corpsFormulaire());
        if (mounted) {
          context.showInfo('Soin mis à jour.');
          Navigator.of(context).maybePop();
        }
      }
    } catch (e) {
      if (mounted) context.showError('Échec de l\'enregistrement du soin.');
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  Future<void> _choisirEtTeleverser(String role) async {
    if (_soinActuel == null) return;
    final picker = ImagePicker();
    final XFile? fichier = role == 'video'
        ? await picker.pickVideo(source: ImageSource.gallery)
        : await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (fichier == null) return;

    setState(() => _televersementEnCours = true);
    try {
      final soinMisAJour = await ref
          .read(administrateurActionsProvider)
          .televerserMediaSoin(_soinActuel!.id, fichier.path, role: role);
      if (mounted) {
        setState(() => _soinActuel = soinMisAJour);
        context.showInfo('Média ajouté.');
      }
    } catch (e) {
      if (mounted) context.showError('Échec du téléversement du média.');
    } finally {
      if (mounted) setState(() => _televersementEnCours = false);
    }
  }

  Future<void> _supprimerSoin() async {
    if (_soinActuel == null) return;
    final confirme = await ConfirmActionDialog.show(
      context,
      titre: 'Supprimer ce soin ?',
      message:
          '"${_soinActuel!.nom}" sera définitivement retiré du catalogue. Si des patients y sont déjà souscrits, '
          'la suppression sera refusée — désactive-le plutôt (bouton "Retirer de la vitrine").',
      libelleConfirmer: 'Supprimer',
      destructif: true,
      icone: Icons.delete_outline,
    );
    if (confirme != true) return;

    try {
      await ref.read(administrateurActionsProvider).supprimerSoin(_soinActuel!.id);
      if (mounted) {
        context.showInfo('Soin supprimé.');
        Navigator.of(context).maybePop();
      }
    } catch (e) {
      if (mounted) {
        context.showError(
          'Suppression impossible : des souscriptions existent probablement déjà pour ce soin. Désactive-le à la place.',
        );
      }
    }
  }

  Future<void> _basculerStatut() async {
    if (_soinActuel == null) return;
    final nouvelActif = !_soinActuel!.actif;
    final confirme = await ConfirmActionDialog.show(
      context,
      titre: nouvelActif ? 'Remettre en vitrine ?' : 'Retirer de la vitrine ?',
      message: nouvelActif
          ? 'Ce soin redeviendra visible et souscriptible dans l\'application.'
          : 'Ce soin ne sera plus visible pour les nouveaux patients (les souscriptions déjà actives ne sont pas affectées).',
      libelleConfirmer: nouvelActif ? 'Remettre en vitrine' : 'Retirer',
      destructif: !nouvelActif,
    );
    if (confirme != true) return;

    try {
      await ref.read(administrateurActionsProvider).changerStatutSoin(_soinActuel!.id, nouvelActif);
      if (mounted) {
        setState(() => _soinActuel = Soin(
              id: _soinActuel!.id,
              nom: _soinActuel!.nom,
              description: _soinActuel!.description,
              prix: _soinActuel!.prix,
              devise: _soinActuel!.devise,
              frequenceVisites: _soinActuel!.frequenceVisites,
              visitesParSemaine: _soinActuel!.visitesParSemaine,
              prestationsIncluses: _soinActuel!.prestationsIncluses,
              dureeEngagementJours: _soinActuel!.dureeEngagementJours,
              imageCouverture: _soinActuel!.imageCouverture,
              images: _soinActuel!.images,
              videos: _soinActuel!.videos,
              actif: nouvelActif,
            ));
        ref.invalidate(soinsListProvider);
      }
    } catch (e) {
      if (mounted) context.showError('Échec de la mise à jour du statut.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final estEdition = _soinActuel != null;
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: AppSpacing.md),
          child: AppCircleIconButton(icon: Icons.arrow_back, onPressed: () => Navigator.of(context).maybePop()),
        ),
        title: Text(estEdition ? 'Modifier le soin' : 'Nouveau soin'),
        actions: [
          if (estEdition)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Supprimer',
              onPressed: _supprimerSoin,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            if (estEdition) ...[
              _SectionMedias(
                soin: _soinActuel!,
                enCours: _televersementEnCours,
                onAjouterCouverture: () => _choisirEtTeleverser('couverture'),
                onAjouterGalerie: () => _choisirEtTeleverser('galerie'),
                onAjouterVideo: () => _choisirEtTeleverser('video'),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _basculerStatut,
                      icon: Icon(_soinActuel!.actif ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      label: Text(_soinActuel!.actif ? 'Retirer de la vitrine' : 'Remettre en vitrine'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _soinActuel!.actif ? AppColors.warning : AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const Divider(),
              const SizedBox(height: AppSpacing.md),
            ],
            TextFormField(
              controller: _nomCtrl,
              decoration: const InputDecoration(labelText: 'Nom du soin'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _descriptionCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description', alignLabelWithHint: true),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _prixCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Prix (XAF)'),
                    validator: (v) => (double.tryParse((v ?? '').replaceAll(',', '.')) == null) ? 'Nombre invalide' : null,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: TextFormField(
                    controller: _visitesSemaineCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Visites / semaine'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _frequenceCtrl,
                    decoration: const InputDecoration(labelText: 'Fréquence (ex: quotidienne)'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: TextFormField(
                    controller: _dureeCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Durée engagement (jours)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _prestationsCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Prestations incluses (une par ligne)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _envoi ? null : _enregistrer,
              child: _envoi
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(estEdition ? 'Enregistrer les modifications' : 'Créer le soin'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionMedias extends StatelessWidget {
  final Soin soin;
  final bool enCours;
  final VoidCallback onAjouterCouverture;
  final VoidCallback onAjouterGalerie;
  final VoidCallback onAjouterVideo;

  const _SectionMedias({
    required this.soin,
    required this.enCours,
    required this.onAjouterCouverture,
    required this.onAjouterGalerie,
    required this.onAjouterVideo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Médias', style: TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              if (enCours) const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (soin.imageCouverture != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Image.network(soin.imageCouverture!, height: 140, width: double.infinity, fit: BoxFit.cover),
            )
          else
            Container(
              height: 100,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: AppColors.border, style: BorderStyle.solid),
              ),
              child: const Text('Aucune image de couverture', style: TextStyle(color: AppColors.textSecondary)),
            ),
          const SizedBox(height: AppSpacing.sm),
          if (soin.images.isNotEmpty)
            SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: soin.images.length,
                separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
                itemBuilder: (context, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: Image.network(soin.images[i], width: 64, height: 64, fit: BoxFit.cover),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              OutlinedButton.icon(
                onPressed: enCours ? null : onAjouterCouverture,
                icon: const Icon(Icons.image_outlined, size: 18),
                label: const Text('Couverture'),
              ),
              OutlinedButton.icon(
                onPressed: enCours ? null : onAjouterGalerie,
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: const Text('Ajouter à la galerie'),
              ),
              OutlinedButton.icon(
                onPressed: enCours ? null : onAjouterVideo,
                icon: const Icon(Icons.videocam_outlined, size: 18),
                label: const Text('Vidéo'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
