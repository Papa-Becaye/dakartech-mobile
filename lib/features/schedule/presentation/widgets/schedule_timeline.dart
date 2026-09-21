import 'package:flutter/material.dart';

import '../../../../core/icons/app_icon.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/course_colors.dart';
import '../../models/schedule_session.dart';

/// Timeline de l'emploi du temps du jour sélectionné.
///
/// Chaque séance est un trait « rail horaire » (heure à gauche, pastille +
/// ligne verticale de liaison, carte à droite) — lecture calendar comme
/// sur les agendas professionnels. Les données viennent exclusivement du
/// backend ; aucune salle n'est affichée (absente du schéma Prisma).
class ScheduleTimeline extends StatelessWidget {
  const ScheduleTimeline({super.key, required this.sessions, this.now});

  final List<ScheduleSession> sessions;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) return const SizedBox.shrink();
    final DateTime current = now ?? DateTime.now();
    return Column(
      children: [
        for (int i = 0; i < sessions.length; i++)
          _TimelineEntry(
            session: sessions[i],
            isLast: i == sessions.length - 1,
            now: current,
          ),
      ],
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  const _TimelineEntry({
    required this.session,
    required this.isLast,
    required this.now,
  });

  final ScheduleSession session;
  final bool isLast;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final ScheduleSessionStatus status = session.statusAt(now);
    final bool ongoing = status == ScheduleSessionStatus.ongoing;
    final bool passed = status == ScheduleSessionStatus.passed;
    final CourseTone tone = CourseTones.toneFor(
      matiereId: session.course.matiere?.id,
      name: session.course.titre,
    );

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Heure de début sur le rail.
            SizedBox(
              width: 52,
              child: Padding(
                padding: const EdgeInsets.only(top: 15),
                child: Text(
                  _hourLabel(session.start),
                  textAlign: TextAlign.right,
                  style: AppTextStyles.caption.copyWith(
                    color: ongoing
                        ? tone.strong
                        : (passed ? AppColors.grayLight : AppColors.dark),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            // Pastille + ligne verticale de liaison.
            SizedBox(
              width: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: passed
                            ? tone.strong.withValues(alpha: 0.35)
                            : tone.strong,
                        shape: BoxShape.circle,
                        border: ongoing
                            ? Border.all(
                                color: tone.strong.withValues(alpha: 0.28),
                                width: 3,
                              )
                            : null,
                      ),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xxs),
                        child: Container(
                          width: 2,
                          color: ongoing
                              ? AppColors.accent
                              : AppColors.graySoftDark,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Carte de la séance.
            Expanded(
              child: _SessionCard(session: session, status: status, tone: tone),
            ),
          ],
        ),
      ),
    );
  }

  static String _hourLabel(DateTime date) {
    final String hour = date.hour.toString().padLeft(2, '0');
    final String minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.session,
    required this.status,
    required this.tone,
  });

  final ScheduleSession session;
  final ScheduleSessionStatus status;
  final CourseTone tone;

  @override
  Widget build(BuildContext context) {
    final bool ongoing = status == ScheduleSessionStatus.ongoing;
    final String? teacher = session.teacherName;
    final String chapitre = session.seance.chapitre;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: tone.soft,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Stack(
        children: [
          if (ongoing)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: SizedBox(width: 4, child: ColoredBox(color: tone.strong)),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              ongoing ? AppSpacing.lg : AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _TimeChip(
                      label: session.timeRangeLabel,
                      highlighted: ongoing,
                      tone: tone,
                    ),
                    const Spacer(),
                    _statusWidget(ongoing),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  session.course.titre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.dark,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (teacher != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  _MetaRow(icon: AppIcons.profile, text: teacher),
                ],
                if (chapitre.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  _MetaRow(icon: AppIcons.courses, text: chapitre),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusWidget(bool ongoing) {
    switch (status) {
      case ScheduleSessionStatus.ongoing:
        return const _OngoingBadge();
      case ScheduleSessionStatus.passed:
        return Text(
          'Terminée',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.grayLight,
            fontWeight: FontWeight.w500,
          ),
        );
      case ScheduleSessionStatus.upcoming:
        return Text(
          'À venir',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w500,
          ),
        );
    }
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({
    required this.label,
    required this.highlighted,
    required this.tone,
  });

  final String label;
  final bool highlighted;
  final CourseTone tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: highlighted
            ? tone.strong
            : AppColors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: highlighted ? AppColors.white : AppColors.gray,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppIcon(icon, size: AppIconSize.xs, color: AppColors.grayLight),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(color: AppColors.gray),
          ),
        ),
      ],
    );
  }
}

/// Badge « En cours » animé : pulsation d'opacité tant que la séance est
/// en cours. Ne se répète que si réellement affiché (aucun impact sur les
/// tests sans séance active).
class _OngoingBadge extends StatefulWidget {
  const _OngoingBadge();

  @override
  State<_OngoingBadge> createState() => _OngoingBadgeState();
}

class _OngoingBadgeState extends State<_OngoingBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(
        begin: 0.55,
        end: 1,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut)),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.xxs),
            Text(
              'EN COURS',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
