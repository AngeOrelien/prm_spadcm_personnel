import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/presentation/providers/auth_providers.dart';

/// Écran temporaire : confirme que l'auth fonctionne de bout en bout.
/// Sera remplacé par le vrai tableau de bord (par rôle) dans la Phase 2.
class HomePlaceholderScreen extends ConsumerWidget {
  const HomePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personnel = ref.watch(authControllerProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accueil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: () => ref.read(authControllerProvider.notifier).deconnecter(),
          ),
        ],
      ),
      body: Center(
        child: Text(
          personnel == null
              ? 'Non connecté'
              : 'Bienvenue ${personnel.nomComplet}\nRôle : ${personnel.role.name}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}
