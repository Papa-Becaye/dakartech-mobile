import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';

/// Skeleton de l'onglet « Notes ».
///
/// Même convention que [AttendanceSkeleton] : pulsation d'opacité sur des
/// blocs aux formes équivalentes aux sections réelles (en-tête, carte de
/// moyenne générale, cartes de matières). Aucune donnée métier, aucun
/// réseau.
class GradesSkeleton extends StatefulWidget {
  const GradesSkeleton({super.key});

  @override
  State<GradesSkeleton> createState() => _GradesSkeletonState();
}

class _GradesSkeletonState extends State<GradesSkeleton>
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
          // En-tête « Notes & évaluations ».
          _SkeletonBar(height: 24, widthFactor: 0.55),
          SizedBox(height: AppSpacing.xxs),
          _SkeletonBar(height: 14, widthFactor: 0.4),
          SizedBox(height: AppSpacing.lg),
          // Carte « Moyenne générale ».
          _SkeletonBar(height: 180, radius: AppRadius.xl),
          SizedBox(height: AppSpacing.lg),
          // Titre de section matières.
          _SkeletonBar(height: 20, widthFactor: 0.35),
          SizedBox(height: AppSpacing.md),
          // Cartes de matières.
          _SkeletonBar(height: 96, radius: AppRadius.lg),
          SizedBox(height: AppSpacing.sm),
          _SkeletonBar(height: 96, radius: AppRadius.lg),
          SizedBox(height: AppSpacing.sm),
          _SkeletonBar(height: 96, radius: AppRadius.lg),
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
