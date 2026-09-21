import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/components/app_error_state.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/dashboard_controller.dart';
import '../data/dashboard_repository.dart';
import '../models/dashboard_data.dart';
import '../widgets/academic_banner.dart';
import '../widgets/courses_section.dart';
import '../widgets/dashboard_skeleton.dart';
import '../widgets/next_course_section.dart';
import '../widgets/quick_actions_section.dart';
import '../widgets/statistics_section.dart';
import '../widgets/student_welcome_card.dart';

/// Dashboard étudiant : centre de contrôle quotidien.
///
/// Orchestre uniquement les états d'interface :
/// - chargement → skeleton ;
/// - erreur → message + Réessayer ;
/// - données → sections (bienvenue, banner, statistiques, prochain cours,
///   mes cours, actions rapides) et pull-to-refresh.
///
/// Aucun appel réseau ici : tout passe par [DashboardController].
/// La bottom navigation et l'AppBar (header) sont gérées par le
/// [StudentShell] — ce screen ne contient que le contenu scrollable.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.repository});

  /// Point d'injection pour les tests (sinon fabriqué automatiquement).
  final DashboardRepository? repository;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final DashboardController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DashboardController(repository: widget.repository);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_controller.load());
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DashboardController>.value(
      value: _controller,
      child: Consumer<DashboardController>(
        builder: (BuildContext context, DashboardController controller, _) {
          final DashboardData? data = controller.data;

          if (data == null) {
            if (controller.error != null) {
              return AppErrorState(
                message: 'Impossible de charger vos données.',
                onRetry: controller.load,
              );
            }
            return const DashboardSkeleton();
          }

          final AuthController auth = context.read<AuthController>();

          return RefreshIndicator(
            onRefresh: () => _refresh(controller),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.xxl,
              ),
              children: [
                StudentWelcomeCard(
                  user: auth.currentUser,
                  classLevel: data.classLevel ?? data.formation,
                  academicYear: data.academicYear,
                ),
                const SizedBox(height: AppSpacing.lg),
                AcademicBanner(
                  title: data.bannerTitle,
                  subtitle: data.bannerSubtitle,
                ),
                const SizedBox(height: AppSpacing.lg),
                StatisticsSection(statistics: data.statistics),
                const SizedBox(height: AppSpacing.lg),
                NextCourseSection(course: data.nextCourse),
                const SizedBox(height: AppSpacing.lg),
                CoursesSection(courses: data.courses),
                const SizedBox(height: AppSpacing.lg),
                const QuickActionsSection(),
                const SizedBox(height: AppSpacing.xs),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Pull-to-refresh : recharge en gardant l'interface actuelle.
  Future<void> _refresh(DashboardController controller) async {
    await controller.refresh();
    if (!mounted) return;

    if (controller.error != null && controller.data != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Impossible de charger vos données.')),
        );
    }
  }
}
