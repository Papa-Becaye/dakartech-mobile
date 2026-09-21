import 'package:flutter/material.dart';

import '../../core/icons/app_icons.dart';
import '../../core/theme/app_colors.dart';
import 'app_text_field.dart';

/// Champ de mot de passe avec bascule d'affichage (masqué/visible).
class AppPasswordField extends StatefulWidget {
  const AppPasswordField({
    super.key,
    this.controller,
    this.label = 'Mot de passe',
    this.hintText = 'Entrez votre mot de passe',
    this.errorText,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController? controller;
  final String label;
  final String hintText;
  final String? errorText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: widget.controller,
      label: widget.label,
      hintText: widget.hintText,
      errorText: widget.errorText,
      obscureText: _obscureText,
      textInputAction: widget.textInputAction,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      suffixIcon: IconButton(
        icon: Icon(
          _obscureText ? AppIcons.eye : AppIcons.eyeOff,
          color: AppColors.gray,
        ),
        onPressed: () => setState(() => _obscureText = !_obscureText),
        tooltip: _obscureText
            ? 'Afficher le mot de passe'
            : 'Masquer le mot de passe',
      ),
    );
  }
}
