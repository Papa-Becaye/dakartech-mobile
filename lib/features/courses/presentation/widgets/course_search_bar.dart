import 'package:flutter/material.dart';

import '../../../../core/icons/app_icons.dart';
import '../../../../shared/widgets/app_icon_button.dart';
import '../../../../shared/widgets/app_text_field.dart';

/// Barre de recherche des cours.
///
/// Recherche LOCALE sur la liste réellement reçue de l'API (aucun appel
/// réseau) : la saisie est transmise au contrôleur via [onChanged], le
/// bouton [onClear] efface la recherche.
///
/// Le [controller] de texte est détenu par l'écran pour rester synchrone
/// avec l'action globale « Effacer les filtres ».
class CourseSearchBar extends StatelessWidget {
  const CourseSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;

  /// Notifié à chaque saisie (recherche réactive pendant la frappe).
  final ValueChanged<String> onChanged;

  /// Efface uniquement le texte de recherche.
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      hintText: 'Rechercher un cours…',
      textInputAction: TextInputAction.search,
      prefixIcon: const Icon(AppIcons.search),
      suffixIcon: ListenableBuilder(
        listenable: controller,
        builder: (BuildContext context, Widget? _) {
          final bool hasText = controller.text.isNotEmpty;
          if (!hasText) return const SizedBox.shrink();
          return AppIconButton(
            icon: AppIcons.close,
            iconSize: 18,
            size: 40,
            tooltip: 'Effacer la recherche',
            onPressed: onClear,
          );
        },
      ),
      onChanged: onChanged,
    );
  }
}
