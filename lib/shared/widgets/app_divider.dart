import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Séparateur horizontal standardisé.
class AppDivider extends StatelessWidget {
  const AppDivider({
    super.key,
    this.thickness = 1,
    this.color = AppColors.border,
    this.indent,
    this.endIndent,
  });

  final double thickness;
  final Color color;

  /// Marge gauche (inutile sans un parent plein largeur).
  final double? indent;

  final double? endIndent;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: thickness,
      color: color,
      indent: indent,
      endIndent: endIndent,
    );
  }
}
