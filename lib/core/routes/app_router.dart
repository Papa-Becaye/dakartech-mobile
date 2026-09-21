import 'package:go_router/go_router.dart';

import '../../features/auth/controllers/auth_controller.dart';
import '../../features/auth/data/auth_status.dart';
import '../../features/auth/models/user_role.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/attendance/presentation/screens/attendance_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/courses/presentation/screens/course_detail_screen.dart';
import '../../features/courses/presentation/screens/courses_screen.dart';
import '../../features/grades/models/grades_releve.dart';
import '../../features/grades/presentation/screens/grades_matiere_screen.dart';
import '../../features/grades/presentation/screens/grades_screen.dart';
import '../../features/student/screens/profile_screen.dart';
import '../../features/schedule/presentation/screens/schedule_screen.dart';
import '../../features/student/shell/student_destination.dart';
import '../../features/student/shell/student_shell.dart';
import '../../shared/components/feature_placeholder_screen.dart';
import 'app_routes.dart';

/// Routes publiques accessibles sans authentification.
const Set<String> _publicRoutes = {
  AppRoutes.splash,
  AppRoutes.login,
  AppRoutes.register,
  AppRoutes.forgotPassword,
};

/// Construit le routeur principal de l'application.
///
/// La navigation est pilotée par l'état de session :
/// - pendant la vérification → on reste sur le splash ;
/// - non authentifié → redirection vers /login ;
/// - authentifié → redirection vers l'espace correspondant au rôle.
///
/// `refreshListenable` relie le routeur au [AuthController] : toute
/// modification d'état (login / logout / expiration) réévalue la
/// redirection automatiquement.
///
/// L'espace étudiant utilise un [StatefulShellRoute.indexedStack] : les
/// 5 onglets partagent une même coquille ([StudentShell]) et conservent
/// leur état (aucune pile inutile, rebuild minimal).
GoRouter createAppRouter(AuthController authController) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: authController,
    redirect: (context, state) {
      final AuthStatus status = authController.status;
      final String location = state.matchedLocation;

      // Vérification de session en cours : uniquement le splash.
      if (status == AuthStatus.checking || status == AuthStatus.unknown) {
        return location == AppRoutes.splash ? null : AppRoutes.splash;
      }

      // Non authentifié : seul le login, la création de compte et le
      // forgot-password sont accessibles ; le splash est redirigé vers
      // le login.
      if (status == AuthStatus.unauthenticated) {
        final bool allowed =
            location == AppRoutes.login ||
            location == AppRoutes.register ||
            location == AppRoutes.forgotPassword;
        return allowed ? null : AppRoutes.login;
      }

      // Authentifié : les routes publiques (splash, login, forgot)
      // redirigent vers l'espace du rôle.
      final UserRole role =
          authController.currentUser?.role ?? UserRole.etudiant;
      if (_publicRoutes.contains(location)) return _homeRouteFor(role);

      // Contrôle d'accès par rôle : seule l'interface ETUDIANT existe
      // pour le moment. ADMIN / ENSEIGNANT arriveront aux étapes
      // suivantes (leur route de départ sera branchée ici).
      if (StudentDestinations.isStudentRoute(location) &&
          role != UserRole.etudiant) {
        return AppRoutes.rolePending;
      }

      // Un étudiant ne doit pas rester sur l'écran « espace en attente ».
      if (location == AppRoutes.rolePending && role == UserRole.etudiant) {
        return AppRoutes.dashboard;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            StudentShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.courses,
                builder: (context, state) => const CoursesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.schedule,
                builder: (context, state) => const ScheduleScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.grades,
                builder: (context, state) => const GradesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      // Assiduité + émargement de l'étudiant (Étape 7).
      GoRoute(
        path: AppRoutes.attendance,
        builder: (context, state) => const AttendanceScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) =>
            const FeaturePlaceholderScreen(title: 'Notifications'),
      ),
      GoRoute(
        path: AppRoutes.courseDetail,
        builder: (context, state) {
          final int? courseId = int.tryParse(state.pathParameters['id'] ?? '');
          if (courseId == null) {
            return const FeaturePlaceholderScreen(title: 'Détail du cours');
          }
          return CourseDetailScreen(
            courseId: courseId,
            studentInitials: authController.currentUser?.fullName,
          );
        },
      ),
      // Fiche détaillée d'une matière de l'onglet Notes. La matière est
      // transmise via `extra` (déjà chargée par /notes/mes-notes) : un
      // accès direct sans donnée passe sur le placeholder.
      GoRoute(
        path: AppRoutes.gradesMatiereDetail,
        builder: (context, state) {
          final GradesMatiere? matiere = state.extra as GradesMatiere?;
          return matiere == null
              ? const FeaturePlaceholderScreen(title: 'Matière')
              : GradesMatiereScreen(matiere: matiere);
        },
      ),
      GoRoute(
        path: AppRoutes.rolePending,
        builder: (context, state) =>
            const FeaturePlaceholderScreen(title: 'Votre espace'),
      ),
    ],
  );
}

/// Route d'accueil selon le rôle de l'utilisateur.
///
/// Les interfaces ADMIN et ENSEIGNANT seront ajoutées à l'étape des
/// dashboards respectifs.
String _homeRouteFor(UserRole role) {
  return switch (role) {
    UserRole.etudiant => AppRoutes.dashboard,
    UserRole.admin || UserRole.enseignant => AppRoutes.rolePending,
  };
}
