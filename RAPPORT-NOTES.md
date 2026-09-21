# Rapport — Étape 8 : Notes & évaluations

## 1. Objectif

Implémenter la fonctionnalité **Notes & évaluations** pour l'étudiant dans DakarTech Pro :

- **Backend (NestJS)** : module `notes` complet et sécurisé (relevé de notes + CRUD réservé aux rôles autorisés), avec jeux de tests unitaires.
- **Mobile (Flutter)** : écran « Notes & évaluations » branché sur l'API réelle, avec fiche détaillée par matière et filtres par type d'évaluation.

L'espace Enseignant, Notifications et Profil ne sont pas concernés par cette étape.

---

## 2. Règles métier implémentées

| Règle | Comportement |
| --- | --- |
| Barème | Une note est comprise entre `0` et `20` (bornes `NOTE_MIN`/`NOTE_MAX` exportées par le DTO). |
| Unicité | Une note est unique par couple `(etudiant, evaluation)` (`@@unique` dans Prisma) → toute saisie en double renvoie `409 Conflict` avec `{ "code": "NOTE_DUPLICATE" }`. |
| Lecture | Un étudiant ne consulte **que ses propres notes** via `GET /notes/mes-notes` (identité issue du JWT, aucun identifiant côté client) ; les CRUD ne sont pas exposés à l'étudiant. |
| Écriture | Seuls `ADMIN` et `ENSEIGNANT` peuvent créer/modifier/supprimer des notes ; l'enseignant n'est autorisé que sur les matières dont il est titulaire (`cours.enseignant.userId === user.sub`, sinon `403`). |
| Appartenance | Une note n'est valide que si l'étudiant appartient à la classe du cours concerné. |
| Mentions | `score ≥ 16` → **Très bien** · `≥ 14` → **Bien** · `≥ 12` → **Assez bien** · `≥ 10` → **Passable** · sinon **Insuffisant** ; sans aucune note, pas de mention (`null`). |
| Moyenne d'une matière | Moyenne de la colonne « note » (ou de l'évaluation) : les évaluations non corrigées sont ignorées ; `null` si aucune note. |
| Moyenne générale | `Σ(moyenne_matière × coefficient) / Σ(coefficients)` (matières notées uniquement), arrondie à 1 décimale. |
| Tri | Évaluations triées par date décroissante, matières par nom. |

---

## 3. Backend — module `notes`

### Endpoints

| Méthode | Route | Rôles | Description |
| --- | --- | --- | --- |
| `POST` | `/notes` | ADMIN, ENSEIGNANT | Créer une note (`etudiantId`, `evaluationId`, `valeur`). |
| `GET` | `/notes` | ADMIN, ENSEIGNANT | Lister les notes. |
| `GET` | `/notes/mes-notes` | ETUDIANT | Relevé de notes de l'étudiant connecté. |
| `GET` | `/notes/:id` | ADMIN, ENSEIGNANT | Détail d'une note. |
| `PATCH` | `/notes/:id` | ADMIN, ENSEIGNANT | Mettre à jour une note. |
| `DELETE` | `/notes/:id` | ADMIN, ENSEIGNANT | Supprimer une note. |

> `GET /notes/mes-notes` est déclaré **avant** `GET /notes/:id` pour ne pas être capturé.

### Réponse de `GET /notes/mes-notes`

```json
{
  "etudiant": {
    "id": 1, "matricule": "DT2025001", "prenom": "Jean", "nom": "Dupont",
    "classe": { "id": 1, "nom": "IG1", "annee": { "id": 1, "libelle": "2025-2026" } }
  },
  "moyenneGenerale": 13.7,
  "mention": "Assez bien",
  "matieres": [
    {
      "matiereId": 1, "matiere": "Algorithmique et Programmation",
      "code": "IG101", "coefficient": 3,
      "moyenne": 14.5, "evaluationsNotees": 2,
      "evaluations": [
        { "id": 20, "titre": "Devoir sur table", "date": "2026-08-22T09:00:00.000Z",
          "type": "DEVOIR", "coursId": 1, "cours": "Algorithmique I", "note": 14.0 }
      ]
    }
  ]
}
```

### Cas d'erreur

| Code HTTP | Code métier | Situation |
| --- | --- | --- |
| `404` | — | Étudiant, évaluation, matière ou note introuvable. |
| `403` | — | L'enseignant n'est pas titulaire de la matière ; étudiant sur une route CRUD. |
| `400` | — | Validation échouée (`valeur` hors barème, types invalides, champs interdits rejetés par `ValidationPipe`). |
| `409` | `NOTE_DUPLICATE` | Note déjà existante pour ce couple `(etudiant, evaluation)`. |

### Fichiers

- `src/notes/dto/create-note.dto.ts` — `@IsInt` sur les ids, `@IsNumber({maxDecimalPlaces: 2}) @Min(0) @Max(20)` sur `valeur`, exports `NOTE_MIN`/`NOTE_MAX`.
- `src/notes/dto/update-note.dto.ts` — `PartialType` (Swagger).
- `src/notes/notes.service.ts` — CRUD + `findMesNotes` + mention, gestion Prisma `P2002`, `MatiereEvaluation`/`MatiereReleve`/`NotesDb` exportées (testables, corrige l'erreur TS4053 de build).
- `src/notes/notes.controller.ts` — guards (`JwtAuthGuard`, `RolesGuard`), `@Roles`, `@CurrentUser`, ordre des routes.
- `src/notes/notes.module.ts` — importe `PrismaModule`.
- `src/notes/notes.service.spec.ts` / `notes.controller.spec.ts` — tests unitaires (mocks Prisma, sans base de données).

### Résultats backend

- `npm test` : **150/150 tests OK (25 suites)** — dont **41 tests** dédiés au module notes.
- `npm run build` : **OK**.

---

## 4. Mobile — feature `grades`

### Architecture (conforme au codebase existant)

```
lib/features/grades/
├── models/grades_releve.dart            # GradesReleve + GradesMatiere/Evaluation…
├── data/grades_endpoints.dart           # '/notes/mes-notes'
├── data/grades_repository.dart          # abstract + ApiGradesRepository (Dio)
├── controllers/grades_controller.dart   # ChangeNotifier (load/refresh)
└── presentation/
    ├── screens/grades_screen.dart       # onglet « Notes » (corps seul, AppBar du shell)
    ├── screens/grades_matiere_screen.dart
    └── widgets/                         # header / average card / cards / tiles…
```

### Écran « Notes & évaluations »

- En-tête interne : « Notes & évaluations » / « Votre progression académique ».
- **Carte moyenne** : moyenne générale sur `20`, mention en badge coloré, barre de progression, footer « Classe · Année » (`IG1 · 2025-2026`) ; « — » si aucune note notée.
- **Cartes matières** : avatar couleur (palette déterministe par `matiereId`), nom, code, coefficient, moyenne sur 20 ou « — » si non notée.
- **Évaluation** : note colorée selon la mention (arobase matière), échéance (« Prévu le … ») pour les échéances à venir, « En attente de correction » pour les évaluations corrigées mais non publiées, type en badge (Devoir/Examen/Projet).
- États : **skeleton** au chargement, **erreur** (message + Réessayer), **vide** (« Aucune note » / « Aucune évaluation »).
- Pull-to-refresh + snackbar « Impossible d'actualiser vos notes. » en cas d'échec réseau.

### Fiche détaillée matière

- AppBar au nom de la matière, carte résumé (moyenne grand format `/20`, mention, stat coefficient / évaluations notées / total).
- Filtres par type : **Toutes / Devoirs / Examens / Projets** (filtrage local, non destructif).
- Liste des évaluations, états vides par filtre.

### Navigation

- Route nommée `gradesMatiereDetail = '/notes/matiere/:id'` dans `app_router.dart`, avec la matière passée via `extra` (**aucun 2ᵉ appel réseau**) ; fallback `FeaturePlaceholderScreen` si l'`extra` manque.
- L'onglet « Notes » du shell (`StudentShell`) pointe désormais vers le vrai `GradesScreen` ; l'ancien placeholder `features/student/screens/grades_screen.dart` a été **supprimé** (aucune référence restante).

### Fichiers

- Nouveaux : `models/grades_releve.dart`, `data/grades_endpoints.dart`, `data/grades_repository.dart`, `controllers/grades_controller.dart`, `presentation/screens/grades_screen.dart`, `presentation/screens/grades_matiere_screen.dart`, `presentation/widgets/` (header, average card, matiere card, evaluation tile, avatar, mention, skeleton).
- Modifiés : `core/routes/app_routes.dart`, `core/routes/app_router.dart` (ajout de la route, imports basculés sur la feature grades, correction d'une coquille hors sujet), `test/widget_test.dart` (l'adapter Dio répond désormais à `/notes/mes-notes`).
- Tests : `test/grades_test.dart` (13 tests) — fixtures réelles, repository fake (données / vide / échec / échec-puis-succès), adaper Dio fake, test bout-en-bout de la route `/notes/matiere/:id`.

### Résultats mobile

- `flutter test` : **98/98 tests OK** (dont 13 `grades_test.dart` et les 8 `widget_test.dart` mis à jour).
- `flutter analyze` : **No issues found!**

---

## 5. Récapitulatif des livrables

| Élément | Statut |
| --- | --- |
| Règles métier (barème, mentions, rôles, unicité) | ✅ Backend + tests |
| Backend `notes` (dto, service, controller, module) | ✅ 41/41 tests, build OK |
| Relevé de notes (`GET /notes/mes-notes`) | ✅ |
| Écran Notes & évaluations (moyenne générale + matières) | ✅ |
| Fiche matière + filtres par type | ✅ |
| Tests Flutter + analyse statique | ✅ 98/98 + 0 issue |