import 'course_model.dart';

/// Détail d'un cours, tel que retourné par `GET /cours/:id` (NestJS +
/// Prisma).
///
/// En plus des champs de la liste (`GET /cours/mes-cours`), la réponse
/// expose la classe de l'étudiant (filière + année académique) et la
/// prochaine séance à venir (ou `null`). Seules des données réellement
/// présentes au schéma sont modélisées — aucun champ inventé.
class CourseDetail {
  const CourseDetail({
    required this.id,
    required this.titre,
    this.volumeHoraire = 0,
    this.matiere,
    this.enseignant,
    this.classe,
    this.prochaineSeance,
  });

  final int id;
  final String titre;

  /// Volume horaire total du cours (en heures).
  final int volumeHoraire;

  final CourseMatiere? matiere;
  final CourseEnseignant? enseignant;

  /// Classe du cours (nom, filière, année académique).
  final CourseClasse? classe;

  /// Prochaine séance non passée, si elle existe.
  final CourseSeance? prochaineSeance;

  factory CourseDetail.fromJson(Map<String, dynamic> json) {
    return CourseDetail(
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
      classe: json['classe'] != null
          ? CourseClasse.fromJson(json['classe'] as Map<String, dynamic>)
          : null,
      prochaineSeance: json['prochaineSeance'] != null
          ? CourseSeance.fromJson(
              json['prochaineSeance'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

/// Classe du cours, telle qu'embarquée par `GET /cours/:id`.
class CourseClasse {
  const CourseClasse({
    required this.id,
    required this.nom,
    this.filiere,
    this.annee,
  });

  final int id;
  final String nom;
  final CourseFiliere? filiere;
  final CourseAnnee? annee;

  factory CourseClasse.fromJson(Map<String, dynamic> json) {
    return CourseClasse(
      id: (json['id'] as num).toInt(),
      nom: json['nom'] as String,
      filiere: json['filiere'] != null
          ? CourseFiliere.fromJson(json['filiere'] as Map<String, dynamic>)
          : null,
      annee: json['annee'] != null
          ? CourseAnnee.fromJson(json['annee'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Filière d'une classe.
class CourseFiliere {
  const CourseFiliere({required this.id, required this.nom});

  final int id;
  final String nom;

  factory CourseFiliere.fromJson(Map<String, dynamic> json) {
    return CourseFiliere(
      id: (json['id'] as num).toInt(),
      nom: json['nom'] as String,
    );
  }
}

/// Année académique d'une classe.
class CourseAnnee {
  const CourseAnnee({
    required this.id,
    required this.libelle,
    this.active = false,
  });

  final int id;

  /// Libellé de l'année (ex. « 2025-2026 »).
  final String libelle;

  final bool active;

  factory CourseAnnee.fromJson(Map<String, dynamic> json) {
    return CourseAnnee(
      id: (json['id'] as num).toInt(),
      libelle: json['libelle'] as String,
      active: json['active'] as bool? ?? false,
    );
  }
}

/// Séance d'un cours (prochaine séance du détail, ou liste de séances).
class CourseSeance {
  const CourseSeance({
    required this.id,
    required this.date,
    this.duree = 0,
    this.chapitre = '',
    this.contenu,
    this.presence,
  });

  final int id;
  final DateTime date;

  /// Durée de la séance (en heures).
  final int duree;

  final String chapitre;
  final String? contenu;

  /// Présence émargée de l'étudiant (`null` si non émargé).
  final CoursePresence? presence;

  bool get estPassee => !date.isAfter(DateTime.now());

  factory CourseSeance.fromJson(Map<String, dynamic> json) {
    return CourseSeance(
      id: (json['id'] as num).toInt(),
      date: DateTime.parse(json['date'] as String),
      duree: (json['duree'] as num?)?.toInt() ?? 0,
      chapitre: (json['chapitre'] as String?) ?? '',
      contenu: json['contenu'] as String?,
      presence: json['presence'] != null
          ? CoursePresence.fromJson(json['presence'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Présence d'un étudiant à une séance.
class CoursePresence {
  const CoursePresence({required this.present, this.remarque});

  final bool present;
  final String? remarque;

  factory CoursePresence.fromJson(Map<String, dynamic> json) {
    return CoursePresence(
      present: json['present'] as bool? ?? false,
      remarque: json['remarque'] as String?,
    );
  }
}

/// Document pédagogique déposé pour un cours.
class CourseDocument {
  const CourseDocument({
    required this.id,
    required this.nom,
    this.url = '',
    this.type = '',
    this.createdAt,
  });

  final int id;
  final String nom;

  /// URL de téléchargement fournie par le backend.
  final String url;

  /// Type du fichier (ex. « PDF »).
  final String type;

  final DateTime? createdAt;

  factory CourseDocument.fromJson(Map<String, dynamic> json) {
    return CourseDocument(
      id: (json['id'] as num).toInt(),
      nom: json['nom'] as String? ?? '',
      url: json['url'] as String? ?? '',
      type: json['type'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }
}

/// Type d'évaluation, tel que modélisé par le backend (`EvalType`).
enum CourseEvaluationType {
  devoir('DEVOIR', 'Devoir'),
  examen('EXAMEN', 'Examen'),
  projet('PROJET', 'Projet');

  const CourseEvaluationType(this.apiValue, this.label);

  /// Valeur envoyée par l'API.
  final String apiValue;

  /// Libellé affichable.
  final String label;

  static CourseEvaluationType fromApi(String? value) {
    return CourseEvaluationType.values.firstWhere(
      (type) => type.apiValue == value,
      orElse: () => CourseEvaluationType.devoir,
    );
  }
}

/// Évaluation d'un cours, avec la note de l'étudiant (`null` tant que
/// l'évaluation n'a pas été corrigée).
class CourseEvaluation {
  const CourseEvaluation({
    required this.id,
    required this.titre,
    required this.date,
    required this.type,
    this.note,
  });

  final int id;
  final String titre;
  final DateTime date;
  final CourseEvaluationType type;

  /// Note (sur 20) de l'étudiant, si corrigée.
  final double? note;

  bool get estNotee => note != null;

  bool get estPassee => !date.isAfter(DateTime.now());

  factory CourseEvaluation.fromJson(Map<String, dynamic> json) {
    return CourseEvaluation(
      id: (json['id'] as num).toInt(),
      titre: json['titre'] as String? ?? '',
      date: DateTime.parse(json['date'] as String),
      type: CourseEvaluationType.fromApi(json['type'] as String?),
      note: json['note'] == null ? null : (json['note'] as num).toDouble(),
    );
  }
}
