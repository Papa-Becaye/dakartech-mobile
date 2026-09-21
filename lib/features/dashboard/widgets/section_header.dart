import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';

/// En-tête de section du dashboard : titre + action optionnelle
/// (ex. « Voir tous les cours → »).
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: AppTextStyles.title)),
        ?trailing,
      ],
    );
  }
}
