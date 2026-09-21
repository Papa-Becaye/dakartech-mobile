import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';

/// Skeleton de la page « Présences ».
///
/// Même convention que [ScheduleSkeleton] et le dashboard : pulsation
/// d'opacité sur des blocs aux formes équivalentes aux sections réelles
/// (bandeau d'émargement, carte de bilan, filtres, timeline). Aucune
/// donnée métier, aucun réseau.
class AttendanceSkeleton extends StatefulWidget {
  const AttendanceSkeleton({super.key});

  @override
  State<AttendanceSkeleton> createState() => _AttendanceSkeletonState();
}

class _AttendanceSkeletonState extends State<AttendanceSkeleton>
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
          // Bandeau d'émargement de la séance en cours.
          _SkeletonBar(height: 150, radius: AppRadius.lg),
          SizedBox(height: AppSpacing.md),
          // Carte de bilan d'assiduité.
          _SkeletonBar(height: 160, radius: AppRadius.lg),
          SizedBox(height: AppSpacing.xl),
          // Titre de l'historique + filtres.
          _SkeletonBar(height: 24, widthFactor: 0.4),
          SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(child: _SkeletonBar(height: 36)),
              SizedBox(width: AppSpacing.xs),
              Expanded(child: _SkeletonBar(height: 36)),
              SizedBox(width: AppSpacing.xs),
              Expanded(child: _SkeletonBar(height: 36)),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          // Éléments de la timeline.
          _SkeletonBar(height: 118, radius: AppRadius.lg),
          SizedBox(height: AppSpacing.sm),
          _SkeletonBar(height: 118, radius: AppRadius.lg),
          SizedBox(height: AppSpacing.sm),
          _SkeletonBar(height: 118, radius: AppRadius.lg),
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
