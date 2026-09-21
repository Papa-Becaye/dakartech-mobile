import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Catalogue centralisé des icônes DakarTech.
///
/// Famille unique : **Lucide** (lignes fines ~2px, formes minimales),
/// choix cohérent avec le Design System (SaaS moderne, épuré).
///
/// Règles d'usage :
/// - les écrans ne référencent JAMAIS `Icons.*` / `LucideIcons.*`
///   directement, uniquement `AppIcons.*` ;
/// - une icône n'est ajoutée ici que si une vraie utilisation existe ;
/// - les couleurs viennent de [AppColors], les tailles de [AppIconSize].
abstract final class AppIcons {
  // ---------------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------------

  /// Accueil (bottom navigation).
  static const IconData home = LucideIcons.home;

  /// Cours (bottom navigation, cartes de cours).
  static const IconData courses = LucideIcons.book;

  /// Planning (bottom navigation, calendrier).
  static const IconData planning = LucideIcons.calendar;

  /// Notes (bottom navigation) — diplôme académique.
  static const IconData grades = LucideIcons.graduationCap;

  /// Profil.
  static const IconData profile = LucideIcons.user;

  // ---------------------------------------------------------------------
  // Académique
  // ---------------------------------------------------------------------

  /// Établissement / logo DakarTech (chapeau de diplôme).
  static const IconData school = LucideIcons.school;

  /// Évaluation, contrôle (planche de bord de notes).
  static const IconData evaluation = LucideIcons.clipboard;

  /// Document / PDF (supports de cours).
  static const IconData document = LucideIcons.fileText;

  /// Dossier (documents vides).
  static const IconData folderOpen = LucideIcons.folderOpen;

  /// Tâche validée (bannière académique).
  static const IconData taskDone = LucideIcons.checkSquare;

  /// Étoile (statistique moyenne).
  static const IconData star = LucideIcons.star;

  /// Certifié (statistique présence).
  static const IconData verified = LucideIcons.badgeCheck;

  /// Graphique en courbe (progression).
  static const IconData chart = LucideIcons.lineChart;

  /// Augmentation (tendance).
  static const IconData trendingUp = LucideIcons.trendingUp;

  // ---------------------------------------------------------------------
  // Planning & séances
  // ---------------------------------------------------------------------

  /// Séance prévue (échéance, calendrier générique).
  static const IconData calendar = LucideIcons.calendar;

  /// Jour avec séance / « Voir aujourd'hui ».
  static const IconData calendarCheck = LucideIcons.calendarCheck;

  /// Aucune séance (historique vide).
  static const IconData calendarX = LucideIcons.calendarX;

  /// Séance récurrente.
  static const IconData repeat = LucideIcons.repeat;

  /// Horaires, durée.
  static const IconData clock = LucideIcons.clock;

  /// Rappel de séance.
  static const IconData bellRing = LucideIcons.bellRing;

  /// Salle / porte de cours.
  static const IconData room = LucideIcons.doorOpen;

  // ---------------------------------------------------------------------
  // Présences
  // ---------------------------------------------------------------------

  /// Présent / succès générique.
  static const IconData checkCircle = LucideIcons.checkCircle;

  /// Absent.
  static const IconData xCircle = LucideIcons.xCircle;

  /// Coche simple.
  static const IconData check = LucideIcons.check;

  /// Séance en cours (point radio).
  static const IconData inProgress = LucideIcons.circleDot;

  /// Émargement (utilisateur validé).
  static const IconData userCheck = LucideIcons.userCheck;

  /// Contrôle des présences.
  static const IconData clipboardCheck = LucideIcons.clipboardCheck;

  // ---------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------

  /// Recherche.
  static const IconData search = LucideIcons.search;

  /// Aucun résultat de recherche.
  static const IconData searchOff = LucideIcons.searchX;

  /// Fermer / effacer.
  static const IconData close = LucideIcons.x;

  /// Retour (navigation).
  static const IconData back = LucideIcons.arrowLeft;

  /// Suivant (« Voir le cours »).
  static const IconData forward = LucideIcons.arrowRight;

  static const IconData chevronLeft = LucideIcons.chevronLeft;
  static const IconData chevronRight = LucideIcons.chevronRight;

  /// Téléchargement (ressources, documents).
  static const IconData download = LucideIcons.download;

  // ---------------------------------------------------------------------
  // Notifications & profil
  // ---------------------------------------------------------------------

  /// Notifications (AppBar).
  static const IconData notification = LucideIcons.bell;

  /// Envoyer un message / email.
  static const IconData mail = LucideIcons.mail;

  /// Déconnexion.
  static const IconData logout = LucideIcons.logOut;

  /// Afficher le mot de passe.
  static const IconData eye = LucideIcons.eye;

  /// Masquer le mot de passe.
  static const IconData eyeOff = LucideIcons.eyeOff;

  // ---------------------------------------------------------------------
  // Dashboard & divers
  // ---------------------------------------------------------------------

  /// Émarger (code QR).
  static const IconData qrCode = LucideIcons.qrCode;

  /// Scolarité (support).
  static const IconData support = LucideIcons.lifeBuoy;

  /// Base de données (cours).
  static const IconData database = LucideIcons.database;

  /// Appareils (cours).
  static const IconData devices = LucideIcons.monitor;

  /// Routeur (cours).
  static const IconData router = LucideIcons.router;

  /// Fusée (projet / ressource).
  static const IconData rocket = LucideIcons.rocket;

  /// Favori.
  static const IconData bookmark = LucideIcons.bookmark;

  /// Coefficient / balance.
  static const IconData scale = LucideIcons.scale;

  /// Nombre d'évaluations (ticket).
  static const IconData ticket = LucideIcons.ticket;

  /// Sablier (attente de correction).
  static const IconData hourglass = LucideIcons.hourglass;

  // ---------------------------------------------------------------------
  // États & alertes
  // ---------------------------------------------------------------------

  /// Alerte (erreur générique).
  static const IconData error = LucideIcons.alertCircle;

  /// Avertissement.
  static const IconData warning = LucideIcons.alertTriangle;

  /// Boîte de réception (état vide par défaut).
  static const IconData empty = LucideIcons.inbox;

  /// En construction (placeholder).
  static const IconData construction = LucideIcons.construction;

  // ---------------------------------------------------------------------
  // Variantes « pleines » — état actif (exception documentée)
  // ---------------------------------------------------------------------
  // Lucide (famille retenue) ne fournit que des glyphes en contour (~2px).
  // Pour distinguer nettement l'onglet actif de la bottom navigation, on
  // utilise ici les glyphes « pleins » du font Material (déjà embarqué,
  // `uses-material-design`). Reste du code : Lucide via AppIcons.
  static const IconData homeFilled = Icons.home;
  static const IconData coursesFilled = Icons.menu_book;
  static const IconData planningFilled = Icons.calendar_month;
  static const IconData gradesFilled = Icons.assignment;
  static const IconData profileFilled = Icons.person;
}

/// Grille de tailles d'icônes DakarTech.
///
/// Les écrans privilégient ces valeurs (20 / 24 / 28 / 32) et évitent
/// les tailles arbitraires.
abstract final class AppIconSize {
  static const double xs = 16;
  static const double sm = 20;
  static const double md = 24;
  static const double lg = 28;
  static const double xl = 32;
}
