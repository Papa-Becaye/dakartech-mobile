import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/icons/app_icon.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/dashboard_statistics.dart';
import 'section_header.dart';

/// Grille des quatre statistiques de progression (2×2, une carte par
/// statistique).
///
/// Cartes homogènes : même hauteur, mêmes paddings, mêmes rayons, sans
/// ombre. Chaque carte présente son icône et son label en tête, puis sa
/// valeur en exergue et son caption — lecture « tableau de bord » pro
/// cohérente avec le détail de cours.
///
/// La carte Présence conserve une fine barre de progression pilotée par
/// [DashboardStatistics.attendanceRate]. Les hauteurs sont adaptatives
/// (dérivées de la largeur) pour rester lisibles sur petits écrans.
class StatisticsSection extends StatelessWidget {
  const StatisticsSection({super.key, required this.statistics});

  final DashboardStatistics statistics;

  @override
  Widget build(BuildContext context) {
    final double? attendance = statistics.attendanceRate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'En un coup d\'œil'),
        const SizedBox(height: AppSpacing.sm),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double maxWidth = constraints.maxWidth;
            final double cardWidth = (maxWidth - AppSpacing.sm) / 2;
            final double aspect = _aspectRatioFor(cardWidth);
            return GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
              childAspectRatio: aspect,
              children: [
                _StatCard(
                  icon: AppIcons.planning,
                  color: AppColors.primaryContainer,
                  label: 'Séances de cours',
                  value: '${statistics.todaySessions}',
                  caption: 'Aujourd\'hui',
                ),
                _StatCard(
                  icon: AppIcons.verified,
                  color: AppColors.success,
                  label: 'Présence',
                  value: _attendanceValue(attendance),
                  caption: statistics.attendanceLabel ?? 'Pas encore de séance',
                  progress: attendance == null ? null : attendance / 100,
                ),
                _StatCard(
                  icon: AppIcons.star,
                  color: AppColors.warning,
                  label: 'Moyenne',
                  value: _averageValue(statistics.average),
                  caption: statistics.mention ?? 'Pas encore de note',
                ),
                _StatCard(
                  icon: AppIcons.warning,
                  color: AppColors.warning,
                  label: 'Assiduité',
                  value: '${statistics.unjustifiedAbsences}',
                  caption: 'Non justifiées',
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  /// Hauteur minimale d'une carte de statistique (contenu + respirations)
  /// pour tenir sur les plus petits écrans sans débordement.
  static const double _minCardHeight = 138;

  /// Ratio largeur/hauteur des cartes : pas plus haut qu'une carte
  /// « petite » (largeur ~136 → ~138 px) sur écran étroit, mais
  /// proportionnel au format desktop sinon.
  static double _aspectRatioFor(double cardWidth) {
    final double height = math.max(_minCardHeight, cardWidth / 1.7);
    return cardWidth / height;
  }

  static String _averageValue(double? value) {
    if (value == null) return '—';
    final String fixed = value.toStringAsFixed(1);
    final String clean = fixed.endsWith('.0')
        ? value.toInt().toString()
        : fixed;
    // Le HTML utilise une virgule décimale française.
    return '${clean.replaceAll('.', ',')} /20';
  }

  /// « 92% », ou « — » tant qu'aucune séance n'a été émargée.
  static String _attendanceValue(double? value) {
    if (value == null) return '—';
    return '${value.round()}%';
  }
}

/// Carte d'une statistique : icône + label en tête, valeur en exergue,
/// caption en dessous, barre de progression optionnelle (Présence).
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.caption,
    this.progress,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String caption;

  /// 0.0 à 1.0, ou `null` pour masquer la barre.
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.dark,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: AppTextStyles.title.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              fontSize: 10,
              color: AppColors.gray,
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: AppColors.graySoft,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.success,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
