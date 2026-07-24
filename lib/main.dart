import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/env_config.dart';
import 'core/theme/app_theme.dart';
import 'router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Charge `.env` (voir `core/config/env_config.dart`) : c'est ce fichier,
  // à la racine du projet, qui décide si l'app parle au backend local ou à
  // celui déployé sur Vercel (ligne `APP_ENV`).
  await EnvConfig.init();
  runApp(const ProviderScope(child: PrmPersonnelApp()));
}

class PrmPersonnelApp extends ConsumerWidget {
  const PrmPersonnelApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'PRM — Personnel',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
