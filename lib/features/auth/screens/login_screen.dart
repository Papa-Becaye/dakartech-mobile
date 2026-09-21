import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/icons/app_icon.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_password_field.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_header.dart';

/// Écran de connexion.
///
/// UI uniquement : la logique d'authentification est déléguée à
/// [AuthController] → [AuthService] → [AuthRepository].
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _submitting = false;
  String? _emailError;
  String? _passwordError;
  String? _submitError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String value) {
    final pattern = r'^[^@\s]+@[^@\s]+\.[^@\s]+$';
    return RegExp(pattern).hasMatch(value);
  }

  void _clearFieldErrors() {
    if (_emailError != null || _passwordError != null || _submitError != null) {
      setState(() {
        _emailError = null;
        _passwordError = null;
        _submitError = null;
      });
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    _clearFieldErrors();

    final String email = _emailController.text.trim();
    final String password = _passwordController.text;

    String? emailError;
    String? passwordError;
    if (email.isEmpty) {
      emailError = 'Veuillez saisir votre email.';
    } else if (!_isValidEmail(email)) {
      emailError = 'Cet email n\'est pas valide.';
    }
    if (password.isEmpty) {
      passwordError = 'Veuillez saisir votre mot de passe.';
    }

    if (emailError != null || passwordError != null) {
      setState(() {
        _emailError = emailError;
        _passwordError = passwordError;
      });
      return;
    }

    setState(() => _submitting = true);
    try {
      await context.read<AuthController>().login(email, password);
      if (!mounted) return;
      // Remplace la pile de navigation pour empêcher un retour
      // vers le login via le bouton retour.
      context.go(AppRoutes.dashboard);
    } on AppException catch (e) {
      _handleError(e.message);
    } catch (_) {
      _handleError('Une erreur est survenue. Veuillez réessayer.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _handleError(String message) {
    if (!mounted) return;
    setState(() => _submitError = message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            // Permet au clavier de remonter le contenu.
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AuthHeader(
                    title: 'Bienvenue sur DakarTech',
                    subtitle:
                        'Connectez-vous pour suivre vos activités '
                        'pédagogiques en toute simplicité.',
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppTextField(
                    controller: _emailController,
                    label: 'Email',
                    hintText: 'vous@exemple.com',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    prefixIcon: const Icon(AppIcons.mail),
                    errorText: _emailError,
                    onChanged: (_) => _clearFieldErrors(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppPasswordField(
                    controller: _passwordController,
                    textInputAction: TextInputAction.done,
                    errorText: _passwordError,
                    onSubmitted: (_) => _submit(),
                    onChanged: (_) => _clearFieldErrors(),
                  ),
                  if (_submitError != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.errorSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AppIcon(
                            AppIcons.error,
                            size: 18,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              _submitError!,
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    label: 'Se connecter',
                    onPressed: _submit,
                    isLoading: _submitting,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Align(
                    child: TextButton(
                      onPressed: () => context.push(AppRoutes.forgotPassword),
                      child: const Text('Mot de passe oublié ?'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        child: Text(
                          'Ou',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.gray,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _GoogleLoginButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text(
                              'La connexion Google Workspace sera '
                              'bientôt disponible.',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Pas encore de compte ?',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.gray,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push(AppRoutes.register),
                        child: const Text('Créer un compte'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bouton de connexion Google Workspace.
///
/// Aucune implémentation OAuth : callback informatif jusqu'à ce que le
/// backend / le provider soit configuré.
class _GoogleLoginButton extends StatelessWidget {
  const _GoogleLoginButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(
          Icons.g_mobiledata,
          size: 28,
          color: AppColors.primary,
        ),
        label: const Text('Continuer avec Google'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
