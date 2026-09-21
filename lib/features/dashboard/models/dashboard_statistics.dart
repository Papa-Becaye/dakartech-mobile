/// Statistiques de l'étudiant affichées sur le dashboard.
///
/// Aggrégations calculées à partir des données réellement renvoyées par
/// l'API (présences émargées et notes corrigées via `/cours/:id/seances`
/// et `/cours/:id/evaluations`). Aucune valeur inventée : une
/// statistique absente du backend est `null` et l'UI affiche un état
/// neutre (« — ») plutôt qu'une valeur fictive.
///
/// Les champs `attendanceRate` et `average` sont donc optionnels :
/// - `attendanceRate` : `null` tant qu'aucune séance n'a été émargée ;
/// - `average` : `null` tant qu'aucune note n'a été corrigée.
class DashboardStatistics {
  const DashboardStatistics({
    required this.todaySessions,
    this.attendanceRate,
    required this.unjustifiedAbsences,
    this.average,
  });

  /// Nombre de séances de cours aujourd'hui (issues du planning réel).
  final int todaySessions;

  /// Taux de présence (0.0 à 100.0), ou `null` si aucune séance émargée.
  final double? attendanceRate;

  /// Nombre d'absences non justifiées (séances émargées « absent »).
  final int unjustifiedAbsences;

  /// Moyenne générale (note / 20), ou `null` si aucune note corrigée.
  final double? average;

  /// Mention associée à la moyenne, ou `null` sans moyenne.
  String? get mention {
    final double? value = average;
    if (value == null) return null;
    if (value >= 16) return 'Très bien';
    if (value >= 14) return 'Bien';
    if (value >= 12) return 'Assez bien';
    if (value >= 10) return 'Passable';
    return 'Insuffisant';
  }

  /// Qualificatif de présence, ou `null` sans séance émargée.
  String? get attendanceLabel {
    final double? value = attendanceRate;
    if (value == null) return null;
    if (value >= 90) return 'Excellent';
    if (value >= 75) return 'Très bien';
    if (value >= 60) return 'Bien';
    return 'À surveiller';
  }

  /// Statistiques neutres (aucune donnée disponible).
  static const DashboardStatistics empty = DashboardStatistics(
    todaySessions: 0,
    attendanceRate: null,
    average: null,
    unjustifiedAbsences: 0,
  );

  factory DashboardStatistics.fromJson(Map<String, dynamic> json) {
    return DashboardStatistics(
      todaySessions: (json['todaySessions'] as num?)?.toInt() ?? 0,
      attendanceRate: (json['attendanceRate'] as num?)?.toDouble(),
      average: (json['average'] as num?)?.toDouble(),
      unjustifiedAbsences: (json['unjustifiedAbsences'] as num?)?.toInt() ?? 0,
    );
  }
}
