import 'package:flutter/foundation.dart';

import '../../../core/errors/app_exception.dart';
import '../data/models/course_model.dart';
import '../data/repositories/courses_repository.dart';

/// Gestionnaire d'état des cours de l'étudiant.
///
/// Machine à états simple, consommée par « Mes cours » :
/// - chargement initial : `_courses == null` et `isLoading == true` ;
/// - erreur initiale : `_courses == null` et `error != null` ;
/// - données : `_courses != null` (liste, éventuellement vide).
///
/// `refresh()` rechargement silencieux : les cours affichés sont
/// conservés pendant le pull-to-refresh (pas d'écran blanc) et une
/// erreur de rafraîchissement est signalée sans écraser la liste.
///
/// Recherche et filtres : appliqués LOCALEMENT sur la liste réellement
/// reçue de l'API. `_courses` (source de vérité) n'est jamais modifiée ;
/// `visibleCourses` est la projection filtrée affichée par l'UI.
/// La recherche porte sur les champs réellement présents dans [Course]
/// (titre, matière, enseignant) ; les filtres sur les matières et les
/// enseignants réellement présents dans la liste — aucune valeur
/// artificielle.
class CoursesController extends ChangeNotifier {
  CoursesController({CoursesRepository? repository})
    : _repository = repository ?? buildCoursesRepository();

  final CoursesRepository _repository;

  static final RegExp _spacesPattern = RegExp(r'\s+');

  List<Course>? _courses;
  AppException? _error;
  bool _isLoading = false;

  String _searchQuery = '';
  int? _selectedMatiereId;
  int? _selectedEnseignantId;

  List<Course>? get courses => _courses;
  AppException? get error => _error;
  bool get isLoading => _isLoading;

  /// Texte de recherche courant (non normalisé, tel que saisi).
  String get searchQuery => _searchQuery;

  /// Filtre matière actif (`null` = aucun).
  int? get selectedMatiereId => _selectedMatiereId;

  /// Filtre enseignant actif (`null` = aucun).
  int? get selectedEnseignantId => _selectedEnseignantId;

  /// Cours affichables : [courses] filtrée par recherche + filtres.
  ///
  /// Retourne une nouvelle liste à chaque appel — la liste source reçue
  /// de l'API reste intacte ; aucune donnée n'est perdue par le filtrage.
  List<Course> get visibleCourses {
    final List<Course>? all = _courses;
    if (all == null || all.isEmpty) return const [];
    return all.where(_matches).toList(growable: false);
  }

  /// Matières réellement présentes dans la liste reçue de l'API, dans
  /// l'ordre d'apparition (aucune valeur inventée).
  List<CourseMatiere> get matiereFilterOptions {
    final List<CourseMatiere> result = <CourseMatiere>[];
    final Set<int> seen = <int>{};
    for (final Course course in _courses ?? const <Course>[]) {
      final CourseMatiere? matiere = course.matiere;
      if (matiere != null && seen.add(matiere.id)) {
        result.add(matiere);
      }
    }
    return result;
  }

  /// Enseignants réellement présents dans la liste reçue de l'API, dans
  /// l'ordre d'apparition (aucune valeur inventée).
  List<CourseEnseignant> get enseignantFilterOptions {
    final List<CourseEnseignant> result = <CourseEnseignant>[];
    final Set<int> seen = <int>{};
    for (final Course course in _courses ?? const <Course>[]) {
      final CourseEnseignant? enseignant = course.enseignant;
      if (enseignant != null && seen.add(enseignant.id)) {
        result.add(enseignant);
      }
    }
    return result;
  }

  /// Charge les cours depuis l'API réelle (aucune donnée locale).
  Future<void> load() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _courses = await _repository.getMyCourses();
    } on AppException catch (e) {
      _error = e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Recharge les cours en gardant l'affichage courant.
  ///
  /// La recherche et les filtres actifs sont conservés pendant le
  /// rafraîchissement ; une erreur n'efface pas la liste déjà affichée.
  Future<void> refresh() async {
    try {
      _courses = await _repository.getMyCourses();
      _error = null;
    } on AppException catch (e) {
      _error = e;
    }
    notifyListeners();
  }

  /// Met à jour le texte de recherche (réactif à chaque saisie).
  void setSearchQuery(String value) {
    if (_searchQuery == value) return;
    _searchQuery = value;
    notifyListeners();
  }

  /// Active le filtre matière ; un second appui sur la même matière le
  /// désactive.
  void toggleMatiereFilter(int matiereId) {
    final int? next = _selectedMatiereId == matiereId ? null : matiereId;
    if (_selectedMatiereId == next) return;
    _selectedMatiereId = next;
    notifyListeners();
  }

  /// Active le filtre enseignant ; un second appui sur le même
  /// enseignant le désactive.
  void toggleEnseignantFilter(int enseignantId) {
    final int? next = _selectedEnseignantId == enseignantId
        ? null
        : enseignantId;
    if (_selectedEnseignantId == next) return;
    _selectedEnseignantId = next;
    notifyListeners();
  }

  /// Supprime recherche ET filtres : la liste complète reçue de l'API
  /// est de nouveau affichée.
  void clearFilters() {
    _searchQuery = '';
    _selectedMatiereId = null;
    _selectedEnseignantId = null;
    notifyListeners();
  }

  bool _matches(Course course) {
    final int? matiereId = _selectedMatiereId;
    if (matiereId != null && course.matiere?.id != matiereId) return false;

    final int? enseignantId = _selectedEnseignantId;
    if (enseignantId != null && course.enseignant?.id != enseignantId) {
      return false;
    }

    final String query = _normalize(_searchQuery);
    if (query.isEmpty) return true;

    return _searchableTexts(course).any((String value) {
      return _normalize(value).contains(query);
    });
  }

  /// Champs réellement présents dans [Course] sur lesquels cherche
  /// l'utilisateur (titre, matière, enseignant).
  Iterable<String> _searchableTexts(Course course) sync* {
    yield course.titre;

    final CourseMatiere? matiere = course.matiere;
    if (matiere != null) {
      yield matiere.nom;
      final String? code = matiere.code;
      if (code != null && code.isNotEmpty) yield code;
    }

    final CourseEnseignant? enseignant = course.enseignant;
    if (enseignant != null) {
      yield enseignant.nom;
      final String? prenom = enseignant.prenom;
      if (prenom != null && prenom.isNotEmpty) yield prenom;
      yield enseignant.fullName;
    }
  }

  /// Insensible à la casse et tolérant aux espaces superflus.
  static String _normalize(String value) =>
      value.trim().toLowerCase().replaceAll(_spacesPattern, ' ');
}
