import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/buttons/app_primary_button.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../providers/auth_providers.dart';
import 'otp_verification_page.dart';

class LoginEmailPage extends ConsumerStatefulWidget {
  const LoginEmailPage({super.key});

  @override
  ConsumerState<LoginEmailPage> createState() => _LoginEmailPageState();
}

class _LoginEmailPageState extends ConsumerState<LoginEmailPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _soumettre() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(otpLoginControllerProvider.notifier);
    final succes = await controller.demanderCode(_emailController.text.trim());

    if (!mounted) return;

    if (succes) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const OtpVerificationPage()),
      );
    } else {
      final erreur = ref.read(otpLoginControllerProvider).errorMessage;
      context.showError(erreur ?? 'Impossible d\'envoyer le code');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(otpLoginControllerProvider.select((s) => s.isLoading));

    return Scaffold(
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
                  const Icon(Icons.medical_services_outlined, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'PRM — Espace Personnel',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Connecte-toi avec ton email professionnel. '
                    'Un code de vérification te sera envoyé.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  AppTextField(
                    controller: _emailController,
                    label: 'Email professionnel',
                    hint: 'prenom.nom@spad-cameroun.org',
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email,
                    autofocus: true,
                  ),
                  const SizedBox(height: 24),
                  AppPrimaryButton(
                    label: 'Recevoir le code',
                    isLoading: isLoading,
                    onPressed: _soumettre,
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
