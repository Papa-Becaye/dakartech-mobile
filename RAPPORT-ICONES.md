# Rapport — Étape 9 : Système d'icônes (Design System)

## 1. Objectif

Instaurer un **système d'icônes cohérent, premium et centralisé** dans l'application mobile DakarTech : remplacer la famille Material/Icons (générique) par une **famille unique** aux lignes fines, conforme au rendu SaaS de l'application, sans mélanger plusieurs bibliothèques.

## 2. Choix technique

| Décision | Choix | Justification |
| --- | --- | --- |
| Bibliothèque unique | **`lucide_icons` v0.257.0** (Lucide) | Famille open-source unique, **contours linéaires ~2px**, formes minimales, ~2900 icônes ; zéro variante Material restante (sauf cas exceptionnel ci-dessous). |
| Centralisation | **`AppIcons`** dans `lib/core/icons/app_icons.dart` | Les écrans ne référencent **jamais** `Icons.*` / `CupertinoIcons.*` / `LucideIcons.*` directement, uniquement `AppIcons.*`. |
| Rendu | `AppIcon` (`lib/core/icons/app_icon.dart`) | Wrapper léger (fine line) autour d'`Icon` : taille par défaut standard (`AppIconSize.sm` = 20), couleur héritée, `semanticLabel` optionnel pour l'accessibilité. |
| Tailles | `AppIconSize` (`xs 16 / sm 20 / md 24 / lg 28 / xl 32`) | Remplace les tailles arbitraires (ex. 15 → 16). |
| États nav | Icône unique + **couleur du thème** (`primary` actif / `grayLight` inactif) + pilule d'indicateur | Lucide n'a pas de variante « remplie » ; l'état actif reste clairement identifiable (cohérent avec `navigationBarTheme` existant). |
| Accessibilité | `AppIconButton` (min. 44 px, tooltip), `AppIcon(semanticLabel:)`, icônes décoratives exclues | Respect de la surface de toucher et des lecteurs d'écran. |
| Icone conservée | `Icons.g_mobiledata` (logo Google « Continuer avec Google », écran de connexion) | Icône de **marque**, pas une icône d'interface : le système d'icônes ne s'y applique pas. |

## 3. Vérification préalable

- **Une famille présente en pratique** : branche Material `Icons.*` (99 usages) ; `CupertinoIcons.*` **0 usage** (dépendance `cupertino_icons` **retirée** de `pubspec.yaml` pour ne garder qu'une seule bibliothèque).
- **Icônes Lucide vérifiées** dans le package installé avant tout remplacement.
- Règle respectée : **aucune icône ajoutée au catalogue sans utilisation réelle** (2 candidats sans usage retirés : `award`, `history`).

## 4. Catalogue `AppIcons` (54 entrées, groupées par contexte)

```
Navigation      home · courses(book) · planning(calendar) · grades(graduationCap) · profile(user)
Académique      school · evaluation(clipboard) · document(fileText) · folderOpen · taskDone(checkSquare)
                star · verified(badgeCheck) · chart(lineChart) · trendingUp
Planning        calendar · calendarCheck · calendarX · repeat · clock · bellRing · room(doorOpen)
Présences       checkCircle · xCircle · check · inProgress(circleDot) · userCheck · clipboardCheck
Actions         search · searchOff(searchX) · close(x) · back(arrowLeft) · forward(arrowRight)
                chevronLeft · chevronRight · download
Profil/Notif    notification(bell) · mail · logout(logOut) · eye · eyeOff
Divers          qrCode · support(lifeBuoy) · database · devices(monitor) · router · rocket
                bookmark · scale · ticket · hourglass · error(alertCircle) · warning(alertTriangle)
                empty(inbox) · construction
```

## 5. Fichiers créés / modifiés

### Créés

- `lib/core/icons/app_icons.dart` — catalogue `AppIcons` + grille `AppIconSize`.
- `lib/core/icons/app_icon.dart` — widget `AppIcon`.

### Remplacés (99 usages → `AppIcons.*`)

| Zone | Fichiers |
| --- | --- |
| Auth | `login_screen.dart`, `register_screen.dart`, `forgot_password_screen.dart`, `dakartech_logo.dart` |
| Shell | `student_destination.dart`, `student_app_bar.dart`, `profile_screen.dart` |
| Dashboard | `statistics_section.dart`, `academic_banner.dart`, `quick_actions_section.dart`, `courses_section.dart`, `course_progress_card.dart`, `next_course_section.dart` |
| Cours | `course_card.dart`, `course_search_bar.dart`, `course_document_card.dart`, `course_banner.dart`, `course_next_session_card.dart`, `course_stats_bento.dart`, `course_evaluation_card.dart`, `courses_screen.dart`, `course_detail_screen.dart` |
| Planning | `schedule_week_navigator.dart`, `schedule_timeline.dart`, `schedule_next_session_banner.dart`, `schedule_day_summary.dart`, `schedule_screen.dart` |
| Présences | `attendance_timeline.dart`, `attendance_emargement_banner.dart`, `attendance_bilan_card.dart`, `attendance_screen.dart` |
| Notes | `grades_screen.dart`, `grades_matiere_screen.dart`, `grades_evaluation_tile.dart`, `grades_average_card.dart`, `grades_matiere_card.dart` |
| Partagés | `app_empty_state.dart`, `app_error_state.dart`, `feature_placeholder_screen.dart`, `app_password_field.dart` |

### Configuration

- `pubspec.yaml` : ajout `lucide_icons: ^0.257.0`, **suppression** de `cupertino_icons` (inutilisée).

## 6. Écrans adaptés (résumé)

- **Onglets** : icône unique (pas d'alternative outline/filled Material) ; état actif par **couleur** + **pilule**.
- **États vides/erreurs** : `inbox` (vide), `alertCircle` (erreur), `searchOff` (aucun résultat), `construction` (placeholder).
- **Types d'évaluation** : Devoir → `clipboard`, Examen → `school`, Projet → `rocket` (idem Notes & Cours).
- **Statuts de présence** : présent `checkCircle` / absent `xCircle` ; badge « Émargé » `check` / « En cours » `inProgress`.
- **Boutons icon-only** : `AppIconButton` conservés (44 px, tooltips inchangés → tests intacts).

## 7. Résultats

- `flutter analyze` : **No issues found!**
- `flutter test` : **98/98 tests OK** (aucune régression — les tests ciblent des tooltips/textes, pas des glyphs).
- Icônes `Icons.*` restantes : **1 seule et assumée** — `Icons.g_mobiledata` (logo Google, connexion).

## 8. Livrables

| Élément | Statut |
| --- | --- |
| Famille unique implémentée (Lucide) | ✅ |
| Catalogue centralisé `AppIcons` (54 icônes, 0 inutilisée) | ✅ |
| Rendu standardisé `AppIcon` + grille `AppIconSize` | ✅ |
| 99 références Material remplacées dans 37 fichiers | ✅ |
| Icône de marque Google conservée (exception documentée) | ✅ |
| Analyse statique + tests | ✅ 0 issue / 98 tests OK |