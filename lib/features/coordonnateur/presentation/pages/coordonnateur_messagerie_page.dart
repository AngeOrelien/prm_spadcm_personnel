import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/pages/messagerie_stub_page.dart';
import '../../../dashboard/presentation/widgets/app_dashboard_header.dart';
import '../providers/coordonnateur_providers.dart';
import '../widgets/coordonnateur_widgets.dart';

/// Onglet "Messagerie" du coordonnateur : fils par AVS de l'équipe et par
/// patient/famille suivi (README §7.2).
class CoordonnateurMessageriePage extends ConsumerStatefulWidget {
  const CoordonnateurMessageriePage({super.key});

  @override
  ConsumerState<CoordonnateurMessageriePage> createState() => _CoordonnateurMessageriePageState();
}

class _CoordonnateurMessageriePageState extends ConsumerState<CoordonnateurMessageriePage> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final avsAsync = ref.watch(avsListProvider);
    final patientsAsync = ref.watch(patientsListProvider);

    return Column(
      children: [
        const AppDashboardHeader.page(title: 'Messagerie', subtitle: 'Équipe et familles', leadingIcon: Icons.forum_outlined),
        TabBar(controller: _tabController, tabs: const [Tab(text: 'Équipe AVS'), Tab(text: 'Familles')]),
        const Divider(height: 1),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              avsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => ErreurChargement(onReessayer: () => ref.invalidate(avsListProvider)),
                data: (liste) => liste.isEmpty
                    ? Center(child: Text('Aucun AVS dans l\'équipe.', style: Theme.of(context).textTheme.bodySmall))
                    : ListView.builder(
                        itemCount: liste.length,
                        itemBuilder: (context, index) {
                          final avs = liste[index];
                          return ListTile(
                            leading: InitialsAvatar(nomComplet: avs.nomComplet, couleur: AppColors.roleAvs),
                            title: Text(avs.nomComplet, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(avs.statut.libelle),
                            trailing: const Icon(Icons.chevron_right, color: AppColors.textDisabled),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => MessagerieStubPage(interlocuteurNom: avs.nomComplet, interlocuteurSousTitre: 'Agent AVS'),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              patientsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => ErreurChargement(onReessayer: () => ref.invalidate(patientsListProvider)),
                data: (liste) => liste.isEmpty
                    ? Center(child: Text('Aucun patient suivi.', style: Theme.of(context).textTheme.bodySmall))
                    : ListView.builder(
                        itemCount: liste.length,
                        itemBuilder: (context, index) {
                          final patient = liste[index];
                          return ListTile(
                            leading: InitialsAvatar(nomComplet: patient.nomComplet),
                            title: Text(patient.nomComplet, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: const Text('Patient / famille'),
                            trailing: const Icon(Icons.chevron_right, color: AppColors.textDisabled),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => MessagerieStubPage(interlocuteurNom: patient.nomComplet, interlocuteurSousTitre: 'Patient / famille'),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
