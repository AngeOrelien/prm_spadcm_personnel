import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../providers/auth_providers.dart';
import '../widgets/otp_code_field.dart';

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

    final controller = ref.read(otpLoginControllerProvider.notifier);
    final succes = await controller.verifierCode(_codeController.text.trim());

    if (!mounted) return;

    if (!succes) {
      final erreur = ref.read(otpLoginControllerProvider).errorMessage;
      context.showError(erreur ?? 'Code invalide');
      return;
    }
    // Le router (redirect sur authControllerProvider) bascule automatiquement
    // vers l'écran d'accueil dès que la session est marquée "connectée".
  }

  Future<void> _renvoyerCode() async {
    final email = ref.read(otpLoginControllerProvider).email;
    final controller = ref.read(otpLoginControllerProvider.notifier);
    final succes = await controller.renvoyerCode();
    if (!mounted) return;
    if (succes) {
      context.showInfo('Un nouveau code a été envoyé à $email');
    } else {
      final erreur = ref.read(otpLoginControllerProvider).errorMessage;
      context.showError(erreur ?? 'Impossible de renvoyer le code');
    }
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
