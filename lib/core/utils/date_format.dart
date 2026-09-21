/// Formatage de dates en français, sans dépendance externe.
///
/// Utilisé par le détail de cours (séances, documents, évaluations) et,
/// plus généralement, partout où un horodatage doit être affiché.
library;

const List<String> _jours = <String>[
  'lundi',
  'mardi',
  'mercredi',
  'jeudi',
  'vendredi',
  'samedi',
  'dimanche',
];

const List<String> _mois = <String>[
  'janvier',
  'février',
  'mars',
  'avril',
  'mai',
  'juin',
  'juillet',
  'août',
  'septembre',
  'octobre',
  'novembre',
  'décembre',
];

const List<String> _moisAbrev = <String>[
  'janv.',
  'févr.',
  'mars',
  'avr.',
  'mai',
  'juin',
  'juil.',
  'août',
  'sept.',
  'oct.',
  'nov.',
  'déc.',
];

/// « lundi 3 novembre 2025 à 09h00 ».
String formatFrenchFull(DateTime date) {
  return '${formatFrenchDay(date)} ${date.year} '
      'à ${formatFrenchHour(date)}';
}

/// « lundi 3 novembre ».
String formatFrenchDay(DateTime date) {
  return '${_jours[date.weekday - 1]} ${formatFrenchShortDate(date)}';
}

/// « 3 novembre 2025 ».
String formatFrenchDate(DateTime date) {
  return '${formatFrenchShortDate(date)} ${date.year}';
}

/// « 3 novembre ».
String formatFrenchShortDate(DateTime date) {
  return '${date.day} ${_mois[date.month - 1]}';
}

/// « nov. » (mois abrégé pour les blocs de date).
String formatFrenchMonthShort(DateTime date) {
  return _moisAbrev[date.month - 1];
}

/// « 09h00 ».
String formatFrenchHour(DateTime date) {
  return '${date.hour.toString().padLeft(2, '0')}h'
      '${date.minute.toString().padLeft(2, '0')}';
}

/// Formate un nombre décimal fractionnaire à la française : 3 → « 3 »,
/// 2.5 → « 2,5 ».
String formatCoefficient(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  return value.toString().replaceAll('.', ',');
}

/// Formate une note sur 20 : 15 → « 15 », 14.5 → « 14,5 ».
String formatNotePour20(double note) {
  final String formatted = note == note.roundToDouble()
      ? note.toInt().toString()
      : note.toString().replaceAll('.', ',');
  return '$formatted /20';
}

/// Libellé de la semaine lisible pour le planning, à partir du lundi.
///
/// Semaine commençant et finissant le même mois : « 19 — 25 septembre 2026 ».
/// Semaine chevauchant deux mois : « 29 juin — 5 juillet 2026 ».
String formatFrenchWeekRange(DateTime monday) {
  final DateTime sunday = monday.add(const Duration(days: 6));
  if (monday.month == sunday.month) {
    return '${monday.day} — ${sunday.day} ${_mois[monday.month - 1]} ${monday.year}';
  }
  return '${monday.day} ${_mois[monday.month - 1]} — '
      '${sunday.day} ${_mois[sunday.month - 1]} ${sunday.year}';
}

/// Temps restant avant un événement, en français.
///
/// « Commence maintenant », « Dans X min », « Dans X h », « Dans X j » ou
/// « Terminé » selon la distance par rapport à [target]. Utilisé par le
/// planning pour le compte à rebours du prochain cours.
String timeUntilLabel(DateTime target, {DateTime? now}) {
  final DateTime current = now ?? DateTime.now();
  final Duration remaining = target.difference(current);
  if (remaining.isNegative) return 'Terminé';
  if (remaining.inMinutes < 1) return 'Commence maintenant';
  if (remaining.inMinutes < 60) return 'Dans ${remaining.inMinutes} min';
  if (remaining.inHours < 24) return 'Dans ${remaining.inHours} h';
  return 'Dans ${remaining.inDays} j';
}

/// Libellé de jour lisible pour un cours du dashboard.
///
/// « Aujourd'hui » / « Demain » pour les deux prochains jours, sinon le
/// nom du jour de la semaine. Utilisé par les widgets du dashboard et
/// par la couche data (prochaine séance).
String courseDayLabel(DateTime date) {
  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);
  final DateTime target = DateTime(date.year, date.month, date.day);

  final int dayDiff = target.difference(today).inDays;
  if (dayDiff == 0) return "Aujourd'hui";
  if (dayDiff == 1) return 'Demain';

  const List<String> weekdays = [
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
    'Dimanche',
  ];
  return weekdays[target.weekday - 1];
}
