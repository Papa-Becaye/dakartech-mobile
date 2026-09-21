import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';

/// Skeleton de chargement du planning.
///
/// Même convention que le dashboard : pulsation d'opacité sur des blocs
/// aux formes équivalentes aux sections réelles (navigation de semaine,
/// sélecteur de jours, résumé, timeline de séances). Aucune donnée
/// métier, aucun réseau.
class ScheduleSkeleton extends StatefulWidget {
  const ScheduleSkeleton({super.key});

  @override
  State<ScheduleSkeleton> createState() => _ScheduleSkeletonState();
}

class _ScheduleSkeletonState extends State<ScheduleSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ).drive(Tween<double>(begin: 0.45, end: 1)),
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        children: const [
          // Titre de la page.
          _SkeletonBar(height: 24, widthFactor: 0.45),
          SizedBox(height: AppSpacing.md),
          // Navigation de semaine.
          _SkeletonBar(height: 96, radius: AppRadius.lg),
          SizedBox(height: AppSpacing.md),
          // Sélecteur de jours.
          Row(
            children: [
              Expanded(child: _SkeletonBar(height: 68)),
              SizedBox(width: AppSpacing.xs),
              Expanded(child: _SkeletonBar(height: 68)),
              SizedBox(width: AppSpacing.xs),
              Expanded(child: _SkeletonBar(height: 68)),
              SizedBox(width: AppSpacing.xs),
              Expanded(child: _SkeletonBar(height: 68)),
              SizedBox(width: AppSpacing.xs),
              Expanded(child: _SkeletonBar(height: 68)),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          // Résumé de journée.
          _SkeletonBar(height: 54, radius: AppRadius.lg),
          SizedBox(height: AppSpacing.lg),
          // Éléments de la timeline.
          _SkeletonBar(height: 130, radius: AppRadius.lg),
          SizedBox(height: AppSpacing.sm),
          _SkeletonBar(height: 130, radius: AppRadius.lg),
          SizedBox(height: AppSpacing.sm),
          _SkeletonBar(height: 130, radius: AppRadius.lg),
        ],
      ),
    );
  }
}

class _SkeletonBar extends StatelessWidget {
  const _SkeletonBar({
    required this.height,
    this.widthFactor = 1,
    this.radius = AppRadius.sm,
  });

  final double height;
  final double widthFactor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Container(
          height: height,
          width: constraints.maxWidth * widthFactor,
          decoration: BoxDecoration(
            color: AppColors.graySoft,
            borderRadius: BorderRadius.circular(radius),
          ),
        );
      },
    );
  }
}
