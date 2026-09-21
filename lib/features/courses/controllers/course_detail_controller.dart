import 'package:flutter/foundation.dart';

import '../../../core/errors/api_exception.dart';
import '../../../core/errors/app_exception.dart';
import '../data/models/course_detail.dart';
import '../data/repositories/courses_repository.dart';

/// Gestionnaire d'état du détail d'un cours.
///
/// Machine à états consommée par `CourseDetailScreen` :
/// - détail : `detail == null` + `isLoading`/`error` (« chargement »,
///   « erreur », « 404 ») puis `detail != null` ;
/// - chaque onglet (séances, documents, évaluations) a son propre état
///   (`loading` / `error` / données), chargé depuis l'API réelle après
///   le détail, sans blocage mutuel.
///
/// Statuts dérivés exposés pour l'en-tête et les cartes :
/// - séances effectuées / progression (séances passées) ;
/// - taux de présence calculé uniquement à partir des présences
///   réellement émargées ;
/// - moyenne des notes réellement corrigées.
class CourseDetailController extends ChangeNotifier {
  CourseDetailController({required int courseId, CoursesRepository? repository})
    : _courseId = courseId,
      _repository = repository ?? buildCoursesRepository();

  final int _courseId;
  final CoursesRepository _repository;

  CourseDetail? _detail;
  AppException? _error;
  bool _isLoading = false;

  List<CourseSeance>? _seances;
  AppException? _seancesError;
  bool _seancesLoading = false;

  List<CourseDocument>? _documents;
  AppException? _documentsError;
  bool _documentsLoading = false;

  List<CourseEvaluation>? _evaluations;
  AppException? _evaluationsError;
  bool _evaluationsLoading = false;

  int get courseId => _courseId;

  CourseDetail? get detail => _detail;
  AppException? get error => _error;
  bool get isLoading => _isLoading;

  List<CourseDocument> get documents => _documents ?? const <CourseDocument>[];

  List<CourseEvaluation> get evaluations =>
      _evaluations ?? const <CourseEvaluation>[];

  bool get seancesLoading => _seancesLoading;
  AppException? get seancesError => _seancesError;
  bool get documentsLoading => _documentsLoading;
  AppException? get documentsError => _documentsError;
  bool get evaluationsLoading => _evaluationsLoading;
  AppException? get evaluationsError => _evaluationsError;

  /// Le cours est-il introuvable côté API (`404`) ?
  bool get isNotFound {
    final AppException? error = _error;
    return error is ApiException && error.statusCode == 404;
  }

  /// Séances déjà passées, de la plus récente à la plus ancienne.
  List<CourseSeance> get seancesHistorique {
    final List<CourseSeance> passees = (_seances ?? const <CourseSeance>[])
        .where((seance) => seance.estPassee)
        .toList();
    passees.sort((a, b) => b.date.compareTo(a.date));
    return passees;
  }

  int get seancesTotal => _seances?.length ?? 0;

  /// Numéro chronologique (1 = plus ancienne) de chaque séance passée.
  Map<int, int> get seancesNumbers {
    final List<CourseSeance> asc = List<CourseSeance>.of(seancesHistorique)
      ..sort((a, b) => a.date.compareTo(b.date));
    final Map<int, int> numbers = <int, int>{};
    for (var i = 0; i < asc.length; i++) {
      numbers[asc[i].id] = i + 1;
    }
    return numbers;
  }

  /// Prochaine séance fournie par le détail (`GET /cours/:id`).
  CourseSeance? get prochaineSeance => _detail?.prochaineSeance;

  /// Progression du cours (% de séances déjà effectuées).
  double get progression {
    final int total = seancesTotal;
    if (total == 0) return 0;
    return seancesHistorique.length / total;
  }

  /// Taux de présence réellement émargé (0…1), ou `null` si aucune
  /// présence n'a été enregistrée.
  double? get attendanceRate {
    final Iterable<CourseSeance> emargees =
        _seances?.where((seance) => seance.presence != null) ??
        const <CourseSeance>[];
    if (emargees.isEmpty) return null;
    final int presents = emargees
        .where((seance) => seance.presence!.present)
        .length;
    return presents / emargees.length;
  }

  /// Moyenne des notes réellement corrigées (sur 20), ou `null`.
  double? get moyenneNotes {
    final List<double> notes = evaluations
        .map((evaluation) => evaluation.note)
        .whereType<double>()
        .toList();
    if (notes.isEmpty) return null;
    return notes.reduce((a, b) => a + b) / notes.length;
  }

  /// Charge le détail puis, si le cours est trouvé, les trois onglets
  /// (séances, documents, évaluations) en parallèle.
  Future<void> load() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _detail = await _repository.getCourseById(_courseId);
    } on AppException catch (e) {
      _error = e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    if (_detail != null) {
      await Future.wait<void>([
        reloadSeances(),
        reloadDocuments(),
        reloadEvaluations(),
      ]);
    }
  }

  /// Recharge les séances (appel API réel).
  Future<void> reloadSeances() async {
    if (_seancesLoading) return;

    _seancesLoading = true;
    _seancesError = null;
    notifyListeners();

    try {
      _seances = await _repository.getCourseSeances(_courseId);
    } on AppException catch (e) {
      _seancesError = e;
    } finally {
      _seancesLoading = false;
      notifyListeners();
    }
  }

  /// Recharge les documents (appel API réel).
  Future<void> reloadDocuments() async {
    if (_documentsLoading) return;

    _documentsLoading = true;
    _documentsError = null;
    notifyListeners();

    try {
      _documents = await _repository.getCourseDocuments(_courseId);
    } on AppException catch (e) {
      _documentsError = e;
    } finally {
      _documentsLoading = false;
      notifyListeners();
    }
  }

  /// Recharge les évaluations (appel API réel).
  Future<void> reloadEvaluations() async {
    if (_evaluationsLoading) return;

    _evaluationsLoading = true;
    _evaluationsError = null;
    notifyListeners();

    try {
      _evaluations = await _repository.getCourseEvaluations(_courseId);
    } on AppException catch (e) {
      _evaluationsError = e;
    } finally {
      _evaluationsLoading = false;
      notifyListeners();
    }
  }
}
