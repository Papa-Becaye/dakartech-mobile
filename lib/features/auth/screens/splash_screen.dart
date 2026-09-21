import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../controllers/auth_controller.dart';
import '../widgets/dakartech_logo.dart';

/// Écran d'accueil affiché au lancement.
///
/// Vérifie automatiquement la session puis délègue la redirection au
/// routeur (`GoRouter.redirect`) selon l'état d'authentification.
/// Le splash ne reste affiché que le temps de la vérification locale.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Lance la vérification de session une seule fois.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthController>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const DakarTechLogo(
                size: 88,
                backgroundColor: AppColors.white,
                iconColor: AppColors.primary,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                AppConstants.appName,
                style: AppTextStyles.headline.copyWith(color: AppColors.white),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                AppConstants.appTagline,
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(color: AppColors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
