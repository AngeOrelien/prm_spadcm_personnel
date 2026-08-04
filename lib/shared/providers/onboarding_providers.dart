import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/onboarding_service.dart';

final onboardingServiceProvider = Provider<OnboardingService>((ref) {
  return OnboardingService();
});

/// `true` dès que l'écran d'accueil (onboarding) a déjà été vu — utilisé par
/// le router (voir `app_router.dart`) pour ne l'afficher qu'au tout premier
/// lancement, avant même l'écran de connexion.
class OnboardingVuController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() {
    return ref.read(onboardingServiceProvider).aDejaVuOnboarding();
  }

  Future<void> marquerCommeVu() async {
    await ref.read(onboardingServiceProvider).marquerCommeVu();
    state = const AsyncData(true);
  }
}

final onboardingVuProvider = AsyncNotifierProvider<OnboardingVuController, bool>(
  OnboardingVuController.new,
);
