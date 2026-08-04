import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../router/app_routes.dart';
import '../../../../shared/providers/onboarding_providers.dart';

/// Une diapositive de l'onboarding : image + titre + description.
///
/// `image` pointe vers `assets/images/onboarding/*.png` (voir
/// `pubspec.yaml`, section `assets`). Tant que les visuels définitifs ne
/// sont pas fournis, `_SlideImage` retombe automatiquement sur une icône de
/// remplacement si le fichier est absent — il suffit de déposer les 3
/// images aux emplacements indiqués ci-dessous pour qu'elles s'affichent,
/// sans toucher au code.
class _OnboardingSlide {
  final String image;
  final IconData iconRepli;
  final String titre;
  final String description;

  const _OnboardingSlide({
    required this.image,
    required this.iconRepli,
    required this.titre,
    required this.description,
  });
}

const _slides = <_OnboardingSlide>[
  _OnboardingSlide(
    image: 'assets/images/onboarding/onboarding_1.png',
    iconRepli: Icons.volunteer_activism_outlined,
    titre: 'Bienvenue sur MySPAD Pro',
    description:
        'L\'application du personnel SPAD Cameroun : AVS, médecins, coordonnateurs et administrateurs, '
        'tous réunis pour le suivi quotidien des patients pris en charge à domicile.',
  ),
  _OnboardingSlide(
    image: 'assets/images/onboarding/onboarding_2.png',
    iconRepli: Icons.fact_check_outlined,
    titre: 'Rapports et présence, même hors ligne',
    description:
        'Fais ton check-in géolocalisé chez le patient et rédige tes rapports même sans connexion : '
        'ils se synchronisent automatiquement dès que le réseau revient, sans perdre l\'heure réelle de ta saisie.',
  ),
  _OnboardingSlide(
    image: 'assets/images/onboarding/onboarding_3.png',
    iconRepli: Icons.groups_outlined,
    titre: 'Toute l\'équipe, au même endroit',
    description:
        'Affectations, validation des rapports, dossiers médicaux et messagerie : coordonnateurs et médecins '
        'suivent chaque famille en temps réel, du premier contact jusqu\'au suivi médical.',
  ),
];

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _terminer() async {
    await ref.read(onboardingVuProvider.notifier).marquerCommeVu();
    if (mounted) context.go(AppRoutes.login);
  }

  void _suivant() {
    if (_index == _slides.length - 1) {
      _terminer();
      return;
    }
    _controller.nextPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final dernierSlide = _index == _slides.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                child: TextButton(
                  onPressed: dernierSlide ? null : _terminer,
                  child: Text(
                    'Passer',
                    style: TextStyle(color: dernierSlide ? Colors.transparent : AppColors.textSecondary),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => _SlideContenu(slide: _slides[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < _slides.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _index ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _index ? AppColors.primary : AppColors.border,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _suivant,
                  child: Text(dernierSlide ? 'Commencer' : 'Suivant'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideContenu extends StatelessWidget {
  final _OnboardingSlide slide;

  const _SlideContenu({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: _SlideImage(image: slide.image, iconRepli: slide.iconRepli),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            slide.titre,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            slide.description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }
}

/// Affiche l'image d'onboarding si elle a été fournie dans les assets,
/// sinon un disque avec une icône de remplacement — pour que l'écran reste
/// présentable avant que les visuels définitifs ne soient déposés dans
/// `assets/images/onboarding/`.
class _SlideImage extends StatelessWidget {
  final String image;
  final IconData iconRepli;

  const _SlideImage({required this.image, required this.iconRepli});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 260,
      child: Image.asset(
        image,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Container(
          decoration: BoxDecoration(color: AppColors.primarySurface, shape: BoxShape.circle),
          child: Icon(iconRepli, size: 96, color: AppColors.primary),
        ),
      ),
    );
  }
}
