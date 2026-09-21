import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/network/api_client.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/data/auth_service.dart';
import 'features/auth/data/token_storage.dart';

void main() {
  // Chaîne de dépendances de l'authentification :
  // UI (AuthController) → service → repository → ApiClient (Dio).
  //
  // `late` casse la dépendance circulaire : le réseau est initialisé
  // en premier, mais les callbacks (token + 401) ne sont exécutés
  // qu'au moment des requêtes, une fois le service prêt.
  late final AuthService authService;
  late final AuthController authController;

  ApiClient.instance.init(
    tokenProvider: () => authService.currentAccessToken,
    onUnauthorized: () => authController.handleSessionExpired(),
  );

  authService = AuthService(
    authRepository: AuthRepository(ApiClient.instance.dio),
    tokenStorage: SecureTokenStorage(const FlutterSecureStorage()),
  );
  authController = AuthController(authService);

  runApp(
    ChangeNotifierProvider<AuthController>.value(
      value: authController,
      child: DakarTechApp(routerConfig: createAppRouter(authController)),
    ),
  );
}

class DakarTechApp extends StatelessWidget {
  const DakarTechApp({super.key, required this.routerConfig});

  final GoRouter routerConfig;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: routerConfig,
    );
  }
}
