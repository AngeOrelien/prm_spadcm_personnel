import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../providers/auth_providers.dart';
import '../widgets/otp_code_field.dart';

// ⚠️ OTP désactivé temporairement — cet écran n'est plus poussé par
// `login_email_page.dart` (voir `AppRoutes.otp`, désormais inatteint).
// `_verifier` et `_renvoyerCode` ci-dessous appellent normalement
// `OtpLoginController.verifierCode`/`renvoyerCode`, qui sont pour l'instant
// commentées dans `auth_providers.dart`. Pour réactiver l'OTP :
//   1. Décommenter les 3 méthodes OTP dans `OtpLoginController`.
//   2. Restaurer les appels `controller.verifierCode(...)` /
//      `controller.renvoyerCode()` ci-dessous (au lieu des stubs actuels).
//   3. Dans `login_email_page.dart`, refaire naviguer `_soumettre` vers
//      `AppRoutes.otp` après un `demanderCode` réussi.
class OtpVerificationPage extends ConsumerStatefulWidget {
  const OtpVerificationPage({super.key});

  @override
  ConsumerState<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends ConsumerState<OtpVerificationPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verifier() async {
    if (!_formKey.currentState!.validate()) return;
    if (!mounted) return;
    // OTP désactivé temporairement (voir la note en haut du fichier) :
    // `controller.verifierCode(...)` est commentée dans `auth_providers.dart`.
    context.showError('Vérification par code désactivée temporairement.');
  }

  Future<void> _renvoyerCode() async {
    if (!mounted) return;
    // OTP désactivé temporairement (voir la note en haut du fichier) :
    // `controller.renvoyerCode()` est commentée dans `auth_providers.dart`.
    context.showError('Renvoi de code désactivé temporairement.');
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(otpLoginControllerProvider.select((s) => s.email));
    final isLoading = ref.watch(otpLoginControllerProvider.select((s) => s.isLoading));

    return Scaffold(
      appBar: AppBar(title: const Text('Vérification')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.mark_email_read_outlined, size: 56),
                  const SizedBox(height: 16),
                  Text(
                    'Entre le code envoyé à\n$email',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  OtpCodeField(
                    controller: _codeController,
                    validator: Validators.otpCode,
                  ),
                  const SizedBox(height: 24),
                  AppPrimaryButton(
                    label: 'Vérifier',
                    isLoading: isLoading,
                    onPressed: _verifier,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: isLoading ? null : _renvoyerCode,
                    child: const Text('Renvoyer le code'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
