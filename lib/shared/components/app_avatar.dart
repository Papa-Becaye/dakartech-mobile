import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Avatar circulaire : image (via URL) ou initiales en repli.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.initials,
    this.imageUrl,
    this.size = 40,
    this.backgroundColor,
    this.foregroundColor,
  });

  /// Initiales à afficher (ex. « AD »). Requises si [imageUrl] est nul.
  final String? initials;

  /// Image distante à afficher en priorité.
  final String? imageUrl;

  final double size;

  final Color? backgroundColor;
  final Color? foregroundColor;

  String get _displayInitials {
    final value = initials?.trim() ?? '';
    if (value.isEmpty) return '?';
    final parts = value.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0].toUpperCase()}${parts[1][0].toUpperCase()}';
    }
    if (value.length >= 2) {
      return value.substring(0, 2).toUpperCase();
    }
    return value.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final String? url = imageUrl;
    if (url != null && url.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildInitials(),
        ),
      );
    }
    return _buildInitials();
  }

  Widget _buildInitials() {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? AppColors.primarySoft,
      ),
      child: Text(
        _displayInitials,
        style: AppTextStyles.label.copyWith(
          fontSize: size * 0.34,
          fontWeight: FontWeight.w600,
          color: foregroundColor ?? AppColors.primary,
        ),
      ),
    );
  }
}
