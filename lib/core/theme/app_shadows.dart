import 'package:flutter/material.dart';

/// Ombres partagées des cartes de l'application.
///
/// Une seule source de vérité pour les ombres « pro » : douce, très
/// légèrement bleutée (cohérente avec la brand DakarTech), faible bruit.
abstract final class AppShadows {
  /// Ombre subtile des cartes (surfaces blanches et encarts colorés).
  static const List<BoxShadow> card = <BoxShadow>[
    BoxShadow(color: Color(0x0D00395F), blurRadius: 14, offset: Offset(0, 4)),
  ];
}
