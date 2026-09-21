import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../data/dashboard_repository.dart';
import '../models/dashboard_data.dart';

/// Gestionnaire d'état du dashboard étudiant.
///
/// Machine à états simple, consommée par [DashboardScreen] :
/// - chargement initial : `_data == null` et `isLoading == true` ;
/// - erreur initiale : `_data == null` et `error != null` (bouton Réessayer) ;
/// - données : `_data != null` (le contenu est rendu).
///
/// `refresh()` rechargement silencieux : les données affichées sont
/// conservées pendant le pull-to-refresh (pas d'écran blanc) et une
/// erreur de rafraîchissement est simplement signalée sans écraser
/// l'interface existante.
class DashboardController extends ChangeNotifier {
  DashboardController({DashboardRepository? repository})
    : _repository = repository ?? buildDashboardRepository();

  final DashboardRepository _repository;

  DashboardData? _data;
  AppException? _error;
  bool _isLoading = false;

  DashboardData? get data => _data;
  AppException? get error => _error;
  bool get isLoading => _isLoading;

  /// Charge le dashboard (état de chargement plein écran).
  Future<void> load() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _data = await _repository.fetchDashboard();
    } on AppException catch (e) {
      _error = e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Recharge les données en gardant l'affichage courant.
  ///
  /// Les erreurs de rafraîchissement n'effacent pas les données déjà
  /// affichées : l'UI signale le problème (snackbar) sans écran vide.
  Future<void> refresh() async {
    try {
      _data = await _repository.fetchDashboard();
      _error = null;
    } on AppException catch (e) {
      _error = e;
    }
    notifyListeners();
  }
}
