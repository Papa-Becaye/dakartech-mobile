import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../shared/components/app_empty_state.dart';
import '../../../../shared/components/app_error_state.dart';
import '../../data/schedule_repository.dart';
import '../../controllers/schedule_controller.dart';
import '../../models/schedule_session.dart';
import '../widgets/schedule_day_selector.dart';
import '../widgets/schedule_day_summary.dart';
import '../widgets/schedule_next_session_banner.dart';
import '../widgets/schedule_skeleton.dart';
import '../widgets/schedule_timeline.dart';
import '../widgets/schedule_week_navigator.dart';

/// Écran « Planning » : l'emploi du temps réel de l'étudiant.
///
/// Orchestre uniquement les états d'interface (même convention que les
/// autres écrans étudiants) :
/// - chargement initial → [ScheduleSkeleton] (pulsation, aucun écran blanc) ;
/// - erreur initiale → message + Réessayer ;
/// - données → navigation de semaine, sélecteur de jour, résumé de
///   journée, prochain cours du jour, timeline des séances, ou état vide
///   si la journée ne contient aucune séance.
///
/// Navigue exclusivement sur les données réelles renvoyées par le backend
/// (`GET /cours/mes-cours` + `GET /cours/:id/seances`) et filtrées
/// localement par semaine/jour : aucun rechargement réseau au changement
/// de jour ou de semaine. Aucune donnée fictive n'est affichée (pas de
/// salle, pas de campus). L'AppBar et la bottom navigation sont gérées
/// par le [StudentShell] — l'écran fournit seulement le corps scrollable.
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key, this.repository});

  /// Point d'injection pour les tests (sinon fabriqué avec l'API réelle).
  final ScheduleRepository? repository;

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late final ScheduleController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScheduleController(repository: widget.repository);
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
    return ChangeNotifierProvider<ScheduleController>.value(
      value: _controller,
      child: Consumer<ScheduleController>(
        builder: (BuildContext context, ScheduleController controller, _) {
          final List<ScheduleSession>? sessions = controller.sessions;

          // Chargement initial ou erreur initiale (aucune donnée).
          if (sessions == null) {
            if (controller.error != null) {
              return AppErrorState(
                message:
                    'Impossible de charger votre emploi du temps.\n'
                    'Vérifiez votre connexion puis réessayez.',
                onRetry: controller.load,
              );
            }
            return const ScheduleSkeleton();
          }

          return _buildSchedule(controller);
        },
      ),
    );
  }

  Widget _buildSchedule(ScheduleController controller) {
    final List<ScheduleSession> daySessions = controller
        .sessionsForSelectedDay();

    // Le bandeau « Prochain cours » n'a de sens qu'aujourd'hui.
    final bool isToday = controller.selectedDate.isAtSameMomentAs(
      _todayDateOnly(),
    );
    final ScheduleSession? nextSession = isToday
        ? controller.nextSessionForSelectedDay()
        : null;

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
          // Titre de la page.
          Text(
            'Votre emploi du temps',
            style: AppTextStyles.title.copyWith(
              color: AppColors.dark,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Navigation de semaine.
          ScheduleWeekNavigator(
            weekRangeLabel: controller.weekRangeLabel,
            isCurrentWeek: controller.isCurrentWeek,
            onPreviousWeek: controller.previousWeek,
            onNextWeek: controller.nextWeek,
            onGoToday: controller.goToday,
          ),
          const SizedBox(height: AppSpacing.md),

          // Sélecteur des 7 jours.
          ScheduleDaySelector(
            days: controller.weekDays,
            selectedDate: controller.selectedDate,
            onSelected: controller.selectDay,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Résumé du jour sélectionné.
          ScheduleDaySummary(
            dayLabel: _dayLabel(controller.selectedDate),
            sessionsCount: daySessions.length,
            firstStart: controller.firstStartForSelectedDay(),
            lastEnd: controller.lastEndForSelectedDay(),
          ),
          const SizedBox(height: AppSpacing.md),

          if (nextSession != null) ...[
            ScheduleNextSessionBanner(session: nextSession),
            const SizedBox(height: AppSpacing.md),
          ],

          if (daySessions.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.lg),
              child: AppEmptyState(
                icon: AppIcons.calendarCheck,
                title: 'Aucun cours prévu',
                message:
                    'Vous n\'avez aucune séance programmée pour '
                    'cette journée.',
                actionLabel: isToday ? null : 'Voir aujourd\'hui',
                onAction: controller.goToday,
              ),
            )
          else
            ScheduleTimeline(sessions: daySessions),
        ],
      ),
    );
  }

  /// Libellé du jour sélectionné : « Aujourd'hui » ou « Lundi 19
  /// septembre » (première lettre capitalisée).
  String _dayLabel(DateTime day) {
    if (day.isAtSameMomentAs(_todayDateOnly())) return "Aujourd'hui";
    final String raw = formatFrenchDay(day);
    if (raw.isEmpty) return '';
    return raw[0].toUpperCase() + raw.substring(1);
  }

  DateTime _todayDateOnly() {
    final DateTime now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Pull-to-refresh : recharge en gardant le jour et la semaine
  /// sélectionnés. Une erreur de rafraîchissement n'efface pas le
  /// contenu affiché (snackbar).
  Future<void> _refresh(ScheduleController controller) async {
    await controller.refresh();
    if (!mounted) return;

    if (controller.error != null && controller.sessions != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'actualiser votre planning.'),
          ),
        );
    }
  }
}
