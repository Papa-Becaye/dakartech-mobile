import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../data/grades_repository.dart';
import '../models/grades_releve.dart';

/// Contrôleur de l'onglet « Notes ».
///
/// Même machine à états que [AttendanceController] : `releve == null`
/// pendant le premier chargement (skeleton), une erreur [AppException]
/// à afficher via [AppErrorState], sinon le relevé. Aucune valeur n'est
/// calculée ici : les moyennes et la mention proviennent du backend
/// (`GET /notes/mes-notes`).
class GradesController extends ChangeNotifier {
  GradesController({GradesRepository? repository})
    : _repository = repository ?? buildGradesRepository();

  final GradesRepository _repository;

  GradesReleve? _releve;
  AppException? _error;
  bool _isLoading = false;

  /// Relevé actuel, ou `null` tant que rien n'a été chargé.
  GradesReleve? get releve => _releve;

  /// Dernière erreur de chargement / rafraîchissement.
  AppException? get error => _error;

  /// `true` pendant le premier chargement (écran entier en skeleton).
  bool get isLoading => _isLoading;

  /// Charge le relevé au premier affichage (skeleton puis données).
  Future<void> load() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _releve = await _repository.fetchMonReleve();
    } on AppException catch (e) {
      _error = e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Recharge en conservant l'état courant (pull-to-refresh) : en cas
  /// d'échec, l'écran garde les données et signale l'erreur (snackbar) ;
  /// en cas de succès, [error] repasse à `null`.
  Future<void> refresh() async {
    try {
      _releve = await _repository.fetchMonReleve();
      _error = null;
    } on AppException catch (e) {
      _error = e;
    } finally {
      notifyListeners();
    }
  }
}
