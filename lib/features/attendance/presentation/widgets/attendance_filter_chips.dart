import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';

/// Filtre appliqué localement à l'historique (aucun appel réseau).
enum AttendanceFilter {
  all('Toutes'),
  present('Présents'),
  absent('Absents');

  const AttendanceFilter(this.label);

  final String label;
}

/// Sélecteur de filtre de l'historique d'assiduité.
class AttendanceFilterChips extends StatelessWidget {
  const AttendanceFilterChips({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final AttendanceFilter value;
  final ValueChanged<AttendanceFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (final AttendanceFilter filter in AttendanceFilter.values) ...[
            _AttendanceChip(
              label: filter.label,
              selected: value == filter,
              onTap: () => onChanged(filter),
            ),
            if (filter != AttendanceFilter.values.last)
              const SizedBox(width: AppSpacing.xs),
          ],
          const SizedBox(width: AppSpacing.md),
        ],
      ),
    );
  }
}

class _AttendanceChip extends StatelessWidget {
  const _AttendanceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.white : AppColors.gray,
            ),
          ),
        ),
      ),
    );
  }
}
