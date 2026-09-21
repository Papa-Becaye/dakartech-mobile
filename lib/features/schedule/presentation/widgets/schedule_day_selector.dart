import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Sélecteur des 7 jours de la semaine affichée (lundi → dimanche).
///
/// Le jour sélectionné est mis en avant (fond primary, texte blanc) ; le
/// jour réel de cette semaine porte une petite pastille quand il n'est
/// pas sélectionné. Zone tactile volontairement généreuse.
class ScheduleDaySelector extends StatelessWidget {
  const ScheduleDaySelector({
    super.key,
    required this.days,
    required this.selectedDate,
    required this.onSelected,
  });

  final List<DateTime> days;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelected;

  static const List<String> _abreviations = <String>[
    'LUN',
    'MAR',
    'MER',
    'JEU',
    'VEN',
    'SAM',
    'DIM',
  ];

  @override
  Widget build(BuildContext context) {
    final DateTime today = DateTime.now();
    final bool todayInWeek = days.any((DateTime d) => _sameDay(d, today));

    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(width: AppSpacing.xs),
        itemBuilder: (BuildContext context, int index) {
          final DateTime day = days[index];
          final bool selected = _sameDay(day, selectedDate);
          final bool isToday = _sameDay(day, today);
          return _DayChip(
            label: _abreviations[day.weekday - 1],
            dayNumber: day.day,
            selected: selected,
            isToday: isToday && todayInWeek,
            onTap: () => onSelected(day),
          );
        },
      ),
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.label,
    required this.dayNumber,
    required this.selected,
    required this.isToday,
    required this.onTap,
  });

  final String label;
  final int dayNumber;
  final bool selected;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color foreground = selected ? AppColors.white : AppColors.grayLight;

    return Material(
      color: selected ? AppColors.primary : AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          width: 52,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                '$dayNumber',
                style: AppTextStyles.title.copyWith(
                  color: foreground,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              if (isToday && !selected)
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                )
              else
                const SizedBox(height: 5),
            ],
          ),
        ),
      ),
    );
  }
}
