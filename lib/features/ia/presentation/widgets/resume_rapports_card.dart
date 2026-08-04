import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../providers/ia_providers.dart';

/// Résumé automatique des derniers rapports journaliers d'un patient
/// (`POST /api/ia/resume-rapports`, voir `resumeRapportsProvider`) — un
/// paragraphe généré par le service IA plutôt que de dérouler chaque
/// rapport un par un.
class ResumeRapportsCard extends ConsumerWidget {
  final String patientId;

  const ResumeRapportsCard({super.key, required this.patientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(resumeRapportsProvider(patientId));

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: async.when(
        loading: () => const SizedBox(height: 60, child: Center(child: CircularProgressIndicator())),
        error: (e, _) => Row(
          children: [
            const Icon(Icons.cloud_off, color: AppColors.textDisabled, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                e is AppException ? e.message : 'Résumé indisponible pour le moment',
                style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              ),
            ),
            TextButton(onPressed: () => ref.invalidate(resumeRapportsProvider(patientId)), child: const Text('Réessayer')),
          ],
        ),
        data: (resume) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.summarize_outlined, size: 18, color: AppColors.accent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Résumé · ${resume.periode.isNotEmpty ? resume.periode : "période récente"}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              resume.resume.isNotEmpty ? resume.resume : "Pas assez de rapports récents pour générer un résumé.",
              style: const TextStyle(fontSize: 13, height: 1.4, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              '${resume.nombreRapportsAnalyses} rapport(s) analysé(s)',
              style: const TextStyle(fontSize: 11, color: AppColors.textDisabled),
            ),
          ],
        ),
      ),
    );
  }
}
