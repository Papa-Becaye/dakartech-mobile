import '../../courses/data/models/course_detail.dart';

/// Résultat de `GET /notes/mes-notes` (relevé de notes de l'étudiant
/// connecté).
///
/// Toutes les valeurs — moyennes et mention comprises — sont calculées
/// par le backend à partir de notes réelles : aucun champ ni aucun
/// calcul inventé côté client.
class GradesReleve {
  const GradesReleve({
    required this.etudiant,
    required this.moyenneGenerale,
    required this.mention,
    required this.matieres,
  });

  final GradesEtudiant etudiant;

  /// Moyenne générale sur 20, pondérée par les coefficients de matière
  /// (`null` tant qu'aucune note n'existe).
  final double? moyenneGenerale;

  /// Mention dérivée de [moyenneGenerale] par le backend (« Bien », …),
  /// `null` sans moyenne.
  final String? mention;

  /// Matières de la classe de l'étudiant (avec ou sans note), triées par
  /// nom dans la réponse.
  final List<GradesMatiere> matieres;

  bool get aDesNotes => matieres.any((GradesMatiere m) => m.estNotee);

  factory GradesReleve.fromJson(Map<String, dynamic> json) {
    return GradesReleve(
      etudiant: GradesEtudiant.fromJson(
        json['etudiant'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      ),
      moyenneGenerale: json['moyenneGenerale'] == null
          ? null
          : (json['moyenneGenerale'] as num).toDouble(),
      mention: json['mention'] as String?,
      matieres: (json['matieres'] as List<dynamic>? ?? const [])
          .map((item) => GradesMatiere.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}

/// Étudiant concerné (« etudiant »), uniquement informatif — l'identité
/// est résolue côté backend depuis le JWT.
class GradesEtudiant {
  const GradesEtudiant({
    required this.id,
    required this.matricule,
    required this.prenom,
    required this.nom,
    required this.classe,
  });

  final int id;
  final String matricule;
  final String prenom;
  final String nom;

  /// Classe réelle de l'étudiant (filière + année académique).
  final GradesClasse classe;

  /// « Awa Sow ».
  String get fullName => '$prenom $nom';

  factory GradesEtudiant.fromJson(Map<String, dynamic> json) {
    return GradesEtudiant(
      id: (json['id'] as num).toInt(),
      matricule: json['matricule'] as String? ?? '',
      prenom: json['prenom'] as String? ?? '',
      nom: json['nom'] as String? ?? '',
      classe: GradesClasse.fromJson(
        json['classe'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      ),
    );
  }
}

/// Classe de l'étudiant (« IG1 », année « 2025-2026 »).
class GradesClasse {
  const GradesClasse({required this.id, required this.nom, this.annee});

  final int id;
  final String nom;

  /// Année académique en cours de l'étudiant.
  final GradesAnnee? annee;

  factory GradesClasse.fromJson(Map<String, dynamic> json) {
    return GradesClasse(
      id: (json['id'] as num).toInt(),
      nom: json['nom'] as String? ?? '',
      annee: json['annee'] != null
          ? GradesAnnee.fromJson(json['annee'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Année académique (« 2025-2026 »).
class GradesAnnee {
  const GradesAnnee({required this.id, required this.libelle});

  final int id;
  final String libelle;

  factory GradesAnnee.fromJson(Map<String, dynamic> json) {
    return GradesAnnee(
      id: (json['id'] as num).toInt(),
      libelle: json['libelle'] as String? ?? '',
    );
  }
}

/// Une matière de la classe de l'étudiant, avec sa moyenne réelle et la
/// liste de ses évaluations.
class GradesMatiere {
  const GradesMatiere({
    required this.matiereId,
    required this.matiere,
    required this.coefficient,
    required this.moyenne,
    required this.evaluationsNotees,
    required this.evaluations,
    this.code,
  });

  final int matiereId;
  final String matiere;

  /// Code de la matière (« ALGO »), si renseigné.
  final String? code;

  /// Coefficient réel de la matière (pondère la moyenne générale).
  final double coefficient;

  /// Moyenne sur 20 des notes notées de la matière (`null` si aucune).
  final double? moyenne;

  /// Nombre d'évaluations réellement corrigées (moyenne calculée dessus).
  final int evaluationsNotees;

  /// Évaluations de la matière (tous les cours de la classe rattachés),
  /// triées par date croissante.
  final List<GradesEvaluation> evaluations;

  bool get estNotee => moyenne != null;

  factory GradesMatiere.fromJson(Map<String, dynamic> json) {
    return GradesMatiere(
      matiereId: (json['matiereId'] as num).toInt(),
      matiere: json['matiere'] as String? ?? '',
      code: json['code'] as String?,
      coefficient: (json['coefficient'] as num?)?.toDouble() ?? 0,
      moyenne: json['moyenne'] == null
          ? null
          : (json['moyenne'] as num).toDouble(),
      evaluationsNotees: (json['evaluationsNotees'] as num?)?.toInt() ?? 0,
      evaluations: (json['evaluations'] as List<dynamic>? ?? const [])
          .map(
            (item) => GradesEvaluation.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false),
    );
  }
}

/// Évaluation d'une matière, avec la note réelle de l'étudiant (`null`
/// tant qu'elle n'a pas été corrigée).
class GradesEvaluation {
  const GradesEvaluation({
    required this.id,
    required this.titre,
    required this.date,
    required this.type,
    required this.coursId,
    required this.cours,
    this.note,
  });

  final int id;
  final String titre;
  final DateTime date;

  /// `DEVOIR` / `EXAMEN` / `PROJET` (même énum que les cours).
  final CourseEvaluationType type;

  /// Id et titre du cours d'origine (une matière peut avoir plusieurs
  /// cours).
  final int coursId;
  final String cours;

  /// Note sur 20 de l'étudiant, si corrigée.
  final double? note;

  bool get estNotee => note != null;

  bool get estPassee => !date.isAfter(DateTime.now());

  factory GradesEvaluation.fromJson(Map<String, dynamic> json) {
    return GradesEvaluation(
      id: (json['id'] as num).toInt(),
      titre: json['titre'] as String? ?? '',
      date: DateTime.parse(json['date'] as String),
      type: CourseEvaluationType.fromApi(json['type'] as String?),
      coursId: (json['coursId'] as num?)?.toInt() ?? 0,
      cours: json['cours'] as String? ?? '',
      note: json['note'] == null ? null : (json['note'] as num).toDouble(),
    );
  }
}
