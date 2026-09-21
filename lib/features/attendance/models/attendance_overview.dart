/// Statut de présence à une séance passée, renvoyé par
/// `GET /presences/mon-assiduite`.
///
/// `PRESENT` : une présence `present=true` a été émargée ; `ABSENT` :
/// aucune présence émargée (ou présence `present=false`).
enum PresenceStatut {
  present('PRESENT', 'Présent'),
  absent('ABSENT', 'Absent');

  const PresenceStatut(this.apiValue, this.label);

  /// Valeur envoyée par l'API.
  final String apiValue;

  /// Libellé affichable.
  final String label;

  static PresenceStatut fromApi(String? value) {
    return PresenceStatut.values.firstWhere(
      (statut) => statut.apiValue == value,
      orElse: () => PresenceStatut.absent,
    );
  }
}

/// Élève concerné (« etudiant »), uniquement informatif — l'identité est
/// résolue côté backend depuis le JWT.
class AttendanceEtudiant {
  const AttendanceEtudiant({
    required this.id,
    required this.prenom,
    required this.nom,
    this.matricule,
    this.classeNom,
  });

  final int id;
  final String prenom;
  final String nom;

  /// Matricule (« DT2025001 »), si présent.
  final String? matricule;

  /// Nom de la classe (« IG1 »), si présent.
  final String? classeNom;

  /// « Ibrahima Sow ».
  String get fullName => '$prenom $nom';

  factory AttendanceEtudiant.fromJson(Map<String, dynamic> json) {
    return AttendanceEtudiant(
      id: (json['id'] as num).toInt(),
      prenom: json['prenom'] as String? ?? '',
      nom: json['nom'] as String? ?? '',
      matricule: json['matricule'] as String?,
      classeNom: (json['classe'] as Map<String, dynamic>?)?['nom'] as String?,
    );
  }
}

/// Bilan d'assiduité calculé par le backend à partir des séances passées
/// réelles de la classe de l'étudiant.
class AttendanceBilan {
  const AttendanceBilan({
    required this.seancesPassees,
    required this.presences,
    required this.absences,
    required this.taux,
    this.appreciation,
  });

  final int seancesPassees;
  final int presences;
  final int absences;

  /// Taux arrondi (0–100) : `round(presences / séances passées × 100)`.
  final int taux;

  /// Appréciation dérivée du taux (jamais calculée côté client).
  final String? appreciation;

  factory AttendanceBilan.fromJson(Map<String, dynamic> json) {
    return AttendanceBilan(
      seancesPassees: (json['seancesPassees'] as num?)?.toInt() ?? 0,
      presences: (json['presences'] as num?)?.toInt() ?? 0,
      absences: (json['absences'] as num?)?.toInt() ?? 0,
      taux: (json['taux'] as num?)?.toInt() ?? 0,
      appreciation: json['appreciation'] as String?,
    );
  }
}

/// Cours d'une séance (dédoublonné de `CourseModel` pour ne dépendre que
/// des données réellement renvoyées par l'endpoint présences).
class AttendanceCours {
  const AttendanceCours({
    required this.id,
    required this.titre,
    this.classeNom,
    this.matiereNom,
    this.enseignantNom,
    this.enseignantPrenom,
  });

  final int id;
  final String titre;

  /// Nom de la classe du cours (« IG1 »).
  final String? classeNom;

  /// Nom de la matière, si embarquée.
  final String? matiereNom;

  final String? enseignantNom;
  final String? enseignantPrenom;

  /// « Diop » / « Awa Diop » selon le prénom.
  String? get enseignantFullName => enseignantPrenom == null
      ? enseignantNom
      : '$enseignantPrenom $enseignantNom';

  factory AttendanceCours.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? classe =
        json['classe'] as Map<String, dynamic>?;
    final Map<String, dynamic>? matiere =
        json['matiere'] as Map<String, dynamic>?;
    final Map<String, dynamic>? enseignant =
        json['enseignant'] as Map<String, dynamic>?;
    return AttendanceCours(
      id: (json['id'] as num).toInt(),
      titre: json['titre'] as String? ?? '',
      classeNom: classe?['nom'] as String?,
      matiereNom: matiere?['nom'] as String?,
      enseignantNom: enseignant?['nom'] as String?,
      enseignantPrenom: enseignant?['prenom'] as String?,
    );
  }
}

/// Entrée de l'historique : une séance passée de la classe, avec le statut
/// de présence réel de l'étudiant.
class AttendanceHistoryEntry {
  const AttendanceHistoryEntry({
    required this.seanceId,
    required this.date,
    required this.duree,
    required this.chapitre,
    required this.statut,
    required this.cours,
    this.remarque,
    this.emargeLe,
  });

  final int seanceId;

  /// Début de la séance (heure locale).
  final DateTime date;

  /// Durée en heures — fin = `date + duree`.
  final int duree;

  final String chapitre;

  /// `PRESENT` ou `ABSENT` (décision 100 % backend).
  final PresenceStatut statut;

  /// Remarque libre renvoyée par le backend (ex. « Retard »).
  final String? remarque;

  /// Horaire d'émargement (`presence.createdAt`), si la présence existe.
  final DateTime? emargeLe;

  final AttendanceCours cours;

  /// L'étudiant est présent (`PRESENT`) quelle que soit la remarque.
  bool get estPresent => statut == PresenceStatut.present;

  factory AttendanceHistoryEntry.fromJson(Map<String, dynamic> json) {
    return AttendanceHistoryEntry(
      seanceId: (json['seanceId'] as num).toInt(),
      date: DateTime.parse(json['date'] as String),
      duree: (json['duree'] as num?)?.toInt() ?? 0,
      chapitre: json['chapitre'] as String? ?? '',
      statut: PresenceStatut.fromApi(json['statut'] as String?),
      remarque: json['remarque'] as String?,
      emargeLe: json['emargeLe'] != null
          ? DateTime.parse(json['emargeLe'] as String)
          : null,
      cours: AttendanceCours.fromJson(
        json['cours'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      ),
    );
  }
}

/// Séance en cours ouvrant l'émargement (fenêtre `[date, date + duree)`).
class AttendanceOngoingSeance {
  const AttendanceOngoingSeance({
    required this.id,
    required this.date,
    required this.duree,
    required this.chapitre,
    required this.cours,
  });

  final int id;
  final DateTime date;
  final int duree;
  final String chapitre;
  final AttendanceCours cours;

  factory AttendanceOngoingSeance.fromJson(Map<String, dynamic> json) {
    return AttendanceOngoingSeance(
      id: (json['id'] as num).toInt(),
      date: DateTime.parse(json['date'] as String),
      duree: (json['duree'] as num?)?.toInt() ?? 0,
      chapitre: json['chapitre'] as String? ?? '',
      cours: AttendanceCours.fromJson(
        json['cours'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      ),
    );
  }
}

/// État de l'émargement sur la séance en cours (s'il y en a une).
class AttendanceEmargementState {
  const AttendanceEmargementState({
    this.seance,
    required this.autorise,
    required this.fait,
  });

  const AttendanceEmargementState.empty()
    : seance = null,
      autorise = false,
      fait = false;

  /// Séance en cours (fenêtre ouverte), ou `null` si aucune.
  final AttendanceOngoingSeance? seance;

  /// La fenêtre est ouverte ET l'étudiant n'a pas encore émargé.
  final bool autorise;

  /// L'étudiant a déjà émargé à la séance en cours.
  final bool fait;

  factory AttendanceEmargementState.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? seance =
        json['seance'] as Map<String, dynamic>?;
    return AttendanceEmargementState(
      seance: seance != null ? AttendanceOngoingSeance.fromJson(seance) : null,
      autorise: json['autorise'] as bool? ?? false,
      fait: json['fait'] as bool? ?? false,
    );
  }
}

/// Réponse complète de `GET /presences/mon-assiduite` : profil, bilan
/// calculé, historique et état de l'émargement.
class AttendanceOverview {
  const AttendanceOverview({
    required this.etudiant,
    required this.bilan,
    required this.historique,
    required this.emargement,
  });

  final AttendanceEtudiant etudiant;
  final AttendanceBilan bilan;

  /// Séances passées triées par date décroissante (plus récente d'abord).
  final List<AttendanceHistoryEntry> historique;

  final AttendanceEmargementState emargement;

  factory AttendanceOverview.fromJson(Map<String, dynamic> json) {
    return AttendanceOverview(
      etudiant: AttendanceEtudiant.fromJson(
        json['etudiant'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      ),
      bilan: AttendanceBilan.fromJson(
        json['bilan'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      ),
      historique: (json['historique'] as List<dynamic>? ?? const [])
          .map(
            (item) =>
                AttendanceHistoryEntry.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false),
      emargement: AttendanceEmargementState.fromJson(
        json['emargement'] as Map<String, dynamic>? ??
            const <String, dynamic>{},
      ),
    );
  }
}

/// Résultat de `POST /presences/:seanceId/emarger` : la présence créée.
class AttendanceEmargementResult {
  const AttendanceEmargementResult({
    required this.presenceId,
    required this.seanceId,
    required this.present,
  });

  final int presenceId;
  final int seanceId;
  final bool present;

  factory AttendanceEmargementResult.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? seance =
        json['seance'] as Map<String, dynamic>?;
    return AttendanceEmargementResult(
      presenceId: (json['id'] as num).toInt(),
      seanceId: (seance?['id'] as num?)?.toInt() ?? 0,
      present: json['present'] as bool? ?? false,
    );
  }
}
