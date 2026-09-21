import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';

/// Skeleton de chargement du dashboard.
///
/// Remplace l'écran blanc pendant la première récupération : une simple
/// pulsation d'opacité sur des blocs aux formes équivalentes aux
/// sections réelles. Aucune donnée métier, aucun réseau.
class DashboardSkeleton extends StatefulWidget {
  const DashboardSkeleton({super.key});

  @override
  State<DashboardSkeleton> createState() => _DashboardSkeletonState();
}

class _DashboardSkeletonState extends State<DashboardSkeleton>
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
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        children: [
          // Carte de bienvenue : avatar + libellés.
          const Row(
            children: [
              _SkeletonCircle(size: 52),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonBar(height: 22, widthFactor: 0.55),
                    SizedBox(height: AppSpacing.xs),
                    _SkeletonBar(height: 14, widthFactor: 0.4),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Banner motivationnel.
          const _SkeletonBar(height: 72, radius: AppRadius.lg),
          const SizedBox(height: AppSpacing.lg),
          // Grille de statistiques 2×2.
          for (int i = 0; i < 2; i++) ...[
            const Row(
              children: [
                Expanded(child: _SkeletonBar(height: 120)),
                SizedBox(width: AppSpacing.sm),
                Expanded(child: _SkeletonBar(height: 120)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.lg),
          // Prochain cours.
          const _SkeletonBar(height: 210, radius: AppRadius.xl),
          const SizedBox(height: AppSpacing.lg),
          // Mes cours.
          for (int i = 0; i < 3; i++) ...[
            const _SkeletonBar(height: 96, radius: AppRadius.lg),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _SkeletonCircle extends StatelessWidget {
  const _SkeletonCircle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.graySoft,
        shape: BoxShape.circle,
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
