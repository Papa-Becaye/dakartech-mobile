import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../data/attendance_repository.dart';
import '../models/attendance_overview.dart';

/// Contrôleur de l'écran « Présences ».
///
/// Même machine à états que [ScheduleController] : `overview == null` en
/// cours de chargement, une erreur [AppException] à afficher via
/// [AppErrorState], sinon l'assiduité. L'émargement est lancé par l'écran,
/// qui affiche le succès/échec ; le contrôleur regagne ensuite l'état réel
/// depuis le backend (aucun état optimiste conservé).
class AttendanceController extends ChangeNotifier {
  AttendanceController({AttendanceRepository? repository})
    : _repository = repository ?? buildAttendanceRepository();

  final AttendanceRepository _repository;

  AttendanceOverview? _overview;
  AppException? _error;
  bool _isLoading = false;
  int? _emargingSeanceId;
  bool _lastEmargementSucceeded = false;

  /// Vue actuelle, ou `null` tant que rien n'a été chargé.
  AttendanceOverview? get overview => _overview;

  /// Dernière erreur (chargement ou émargement), affichée par l'écran.
  AppException? get error => _error;

  /// `true` pendant le premier chargement (écran entier en skeleton).
  bool get isLoading => _isLoading;

  /// Id de la séance dont l'émargement est en cours (`null` sinon).
  int? get emargingSeanceId => _emargingSeanceId;

  /// `true` si le dernier émargement (ou sa requête de rafraîchissement)
  /// s'est soldé par un succès — sert à choisir l'icône après coup.
  bool get lastEmargementSucceeded => _lastEmargementSucceeded;

  /// Charge l'assiduité au premier affichage (skeleton puis données).
  Future<void> load() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _overview = await _repository.fetchMonAssiduite();
    } on AppException catch (e) {
      _error = e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Recharge en conservant l'état courant (pull-to-refresh) : en cas
  /// d'échec, l'écran garde les données et signale l'erreur (snack);
  /// en cas de succès, [error] repasse à `null`.
  Future<void> refresh() async {
    try {
      _overview = await _repository.fetchMonAssiduite();
      _error = null;
    } on AppException catch (e) {
      _error = e;
    } finally {
      notifyListeners();
    }
  }

  /// Tente l'émargement à la séance [seanceId] (fenêtre ouverte requise).
  ///
  /// Retourne l'[AppException] en cas d'échec (`null` sinon). Après
  /// succès, l'assiduité est rechargée pour basculer le repère
  /// « émargé » depuis l'état réel du backend.
  Future<AppException?> emarger(int seanceId) async {
    if (_emargingSeanceId != null || _overview == null) return null;

    _emargingSeanceId = seanceId;
    _lastEmargementSucceeded = false;
    notifyListeners();

    try {
      await _repository.emarger(seanceId);
      _lastEmargementSucceeded = true;
      try {
        _overview = await _repository.fetchMonAssiduite();
        _error = null;
      } on AppException {
        // Émargement réussi malgré un rafraîchissement défaillant : le
        // bandeau reste marqué « émargé » par l'écran.
      }
      return null;
    } on AppException catch (e) {
      return e;
    } finally {
      _emargingSeanceId = null;
      notifyListeners();
    }
  }
}
