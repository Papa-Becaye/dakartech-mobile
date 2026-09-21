/// Un cours de l'étudiant connecté.
///
/// Correspond à la réponse de `GET /cours/mes-cours` (NestJS + Prisma).
/// Format réel reçu :
/// ```json
/// [
///   {
///     "id": 1,
///     "titre": "Bases de données",
///     "volumeHoraire": 36,
///     "matiere": {
///       "id": 1,
///       "nom": "Bases de données",
///       "code": "BD301",
///       "coefficient": 3
///     },
///     "enseignant": {
///       "id": 3,
///       "nom": "Diop",
///       "prenom": "Awa"
///     }
///   }
/// ]
/// ```
class Course {
  const Course({
    required this.id,
    required this.titre,
    this.volumeHoraire = 0,
    this.matiere,
    this.enseignant,
  });

  final int id;
  final String titre;

  /// Volume horaire total du cours (en heures).
  final int volumeHoraire;

  /// Matière associée (`matiere` : nom, code, coefficient).
  final CourseMatiere? matiere;

  /// Enseignant responsable (`enseignant` : nom, prénom).
  final CourseEnseignant? enseignant;

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: (json['id'] as num).toInt(),
      titre: json['titre'] as String,
      volumeHoraire: (json['volumeHoraire'] as num?)?.toInt() ?? 0,
      matiere: json['matiere'] != null
          ? CourseMatiere.fromJson(json['matiere'] as Map<String, dynamic>)
          : null,
      enseignant: json['enseignant'] != null
          ? CourseEnseignant.fromJson(
              json['enseignant'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

/// Matière d'un cours, telle qu'embarquée par `GET /cours/mes-cours`.
class CourseMatiere {
  const CourseMatiere({
    required this.id,
    required this.nom,
    this.code,
    this.coefficient = 0,
  });

  final int id;
  final String nom;

  /// Code de la matière (ex. « BD301 »).
  final String? code;

  final double coefficient;

  factory CourseMatiere.fromJson(Map<String, dynamic> json) {
    return CourseMatiere(
      id: (json['id'] as num).toInt(),
      nom: json['nom'] as String,
      code: json['code'] as String?,
      coefficient: (json['coefficient'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Enseignant responsable d'un cours, tel qu'embarqué par
/// `GET /cours/mes-cours`.
class CourseEnseignant {
  const CourseEnseignant({required this.id, required this.nom, this.prenom});

  final int id;
  final String nom;
  final String? prenom;

  /// « Awa Diop », ou simplement « Diop » si le prénom est absent.
  String get fullName => prenom == null ? nom : '$prenom $nom';

  factory CourseEnseignant.fromJson(Map<String, dynamic> json) {
    return CourseEnseignant(
      id: (json['id'] as num).toInt(),
      nom: json['nom'] as String,
      prenom: json['prenom'] as String?,
    );
  }
}
