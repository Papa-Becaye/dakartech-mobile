import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/utils/date_format.dart';
import '../data/schedule_repository.dart';
import '../models/schedule_session.dart';

/// Gestionnaire d'état de l'emploi du temps.
///
/// Machine à états consommée par [ScheduleScreen] (même convention que
/// [DashboardController]) :
/// - chargement initial : `sessions == null` et `isLoading == true` ;
/// - erreur initiale : `sessions == null` et `error != null` (Réessayer) ;
/// - données : `sessions != null` (le contenu est rendu).
///
/// La navigation semaine/jour est **locale** : toutes les séances sont
/// récupérées en une fois et filtrées côté client, le backend ne couvrant
/// pas l'historique des semaines. Le jour sélectionné et la semaine
/// affichée sont conservés lors d'un rafraîchissement.
class ScheduleController extends ChangeNotifier {
  ScheduleController({ScheduleRepository? repository})
    : _repository = repository ?? buildScheduleRepository();

  final ScheduleRepository _repository;

  List<ScheduleSession>? _sessions;
  AppException? _error;
  bool _isLoading = false;

  // Jour sélectionné au premier chargement : aujourd'hui.
  DateTime _selectedDate = _dateOnly(DateTime.now());

  List<ScheduleSession>? get sessions => _sessions;
  AppException? get error => _error;
  bool get isLoading => _isLoading;

  DateTime get selectedDate => _selectedDate;

  /// Le lundi de la semaine affichée.
  DateTime get selectedMonday =>
      _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));

  /// Le lundi de cette semaine (calendrier réel).
  DateTime get currentMonday {
    final DateTime today = _dateOnly(DateTime.now());
    return today.subtract(Duration(days: today.weekday - 1));
  }

  /// Décalage en semaines par rapport à la semaine courante
  /// (0 = cette semaine, -1 = la précédente, +1 = la suivante).
  int get selectedWeekOffset =>
      (selectedMonday.difference(currentMonday).inDays / 7).round();

  bool get isCurrentWeek => selectedWeekOffset == 0;

  /// Libellé de la semaine affichée : « 19 — 25 septembre 2026 ».
  String get weekRangeLabel => formatFrenchWeekRange(selectedMonday);

  /// Les 7 jours (lundi → dimanche) de la semaine affichée.
  List<DateTime> get weekDays => List<DateTime>.generate(
    7,
    (int i) => selectedMonday.add(Duration(days: i)),
  );

  /// Séances triées du jour [day] (comparaison « date seule »).
  List<ScheduleSession> sessionsForDay(DateTime day) {
    final List<ScheduleSession>? data = _sessions;
    if (data == null) return const <ScheduleSession>[];
    final DateTime target = _dateOnly(day);
    return data
        .where(
          (ScheduleSession s) => _dateOnly(s.start).isAtSameMomentAs(target),
        )
        .toList(growable: false);
  }

  List<ScheduleSession> sessionsForSelectedDay() =>
      sessionsForDay(_selectedDate);

  int sessionsCountForSelectedDay() => sessionsForSelectedDay().length;

  /// Première heure de début du jour, pour le résumé de journée.
  DateTime? firstStartForSelectedDay() {
    final List<ScheduleSession> day = sessionsForSelectedDay();
    if (day.isEmpty) return null;
    return day.first.start;
  }

  /// Dernière heure de fin du jour, pour le résumé de journée.
  DateTime? lastEndForSelectedDay() {
    final List<ScheduleSession> day = sessionsForSelectedDay();
    if (day.isEmpty) return null;
    return day.last.end;
  }

  /// Séance en cours sur le jour sélectionné (début ≤ maintenant ≤ fin).
  ScheduleSession? ongoingSessionForSelectedDay({DateTime? now}) {
    final DateTime current = now ?? DateTime.now();
    for (final ScheduleSession s in sessionsForSelectedDay()) {
      if (s.statusAt(current) == ScheduleSessionStatus.ongoing) {
        return s;
      }
    }
    return null;
  }

  /// Prochaine séance à venir du jour sélectionné (début > maintenant).
  ScheduleSession? nextSessionForSelectedDay({DateTime? now}) {
    final DateTime current = now ?? DateTime.now();
    for (final ScheduleSession s in sessionsForSelectedDay()) {
      if (s.statusAt(current) == ScheduleSessionStatus.upcoming) {
        return s;
      }
    }
    return null;
  }

  /// Charge l'emploi du temps (état de chargement plein écran).
  Future<void> load() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _sessions = await _repository.fetchSessions();
    } on AppException catch (e) {
      _error = e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Recharge les données en gardant l'affichage courant.
  ///
  /// Le jour et la semaine sélectionnés sont conservés ; une erreur de
  /// rafraîchissement est signalée (snackbar) sans écran vide.
  Future<void> refresh() async {
    try {
      _sessions = await _repository.fetchSessions();
      _error = null;
    } on AppException catch (e) {
      _error = e;
    }
    notifyListeners();
  }

  void selectDay(DateTime day) {
    final DateTime next = _dateOnly(day);
    if (next.isAtSameMomentAs(_selectedDate)) return;
    _selectedDate = next;
    notifyListeners();
  }

  void previousWeek() {
    _selectedDate = _selectedDate.subtract(const Duration(days: 7));
    notifyListeners();
  }

  void nextWeek() {
    _selectedDate = _selectedDate.add(const Duration(days: 7));
    notifyListeners();
  }

  /// Revient sur aujourd'hui (aucun rechargement : filtrage local).
  void goToday() {
    final DateTime today = _dateOnly(DateTime.now());
    if (today.isAtSameMomentAs(_selectedDate)) return;
    _selectedDate = today;
    notifyListeners();
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
