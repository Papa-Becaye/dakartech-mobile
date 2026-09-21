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

/// Écran de création de compte étudiant.
///
/// UI uniquement : la création et le démarrage de session sont délégués
/// à [AuthController] → [AuthService] → [AuthRepository]
/// (`POST /auth/register`).
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _submitting = false;
  String? _nomError;
  String? _prenomError;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;
  String? _submitError;

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String value) {
    final pattern = r'^[^@\s]+@[^@\s]+\.[^@\s]+$';
    return RegExp(pattern).hasMatch(value);
  }

  void _clearFieldErrors() {
    if (_nomError != null ||
        _prenomError != null ||
        _emailError != null ||
        _passwordError != null ||
        _confirmError != null ||
        _submitError != null) {
      setState(() {
        _nomError = null;
        _prenomError = null;
        _emailError = null;
        _passwordError = null;
        _confirmError = null;
        _submitError = null;
      });
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    _clearFieldErrors();

    final String nom = _nomController.text.trim();
    final String prenom = _prenomController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text;
    final String confirm = _confirmController.text;

    String? nomError;
    String? prenomError;
    String? emailError;
    String? passwordError;
    String? confirmError;

    if (nom.isEmpty) {
      nomError = 'Veuillez saisir votre nom.';
    }
    if (prenom.isEmpty) {
      prenomError = 'Veuillez saisir votre prénom.';
    }
    if (email.isEmpty) {
      emailError = 'Veuillez saisir votre email.';
    } else if (!_isValidEmail(email)) {
      emailError = 'Cet email n\'est pas valide.';
    }
    if (password.isEmpty) {
      passwordError = 'Veuillez saisir un mot de passe.';
    } else if (password.length < 8) {
      passwordError = 'Le mot de passe doit contenir au moins 8 caractères.';
    }
    if (confirm.isEmpty) {
      confirmError = 'Veuillez confirmer votre mot de passe.';
    } else if (confirm != password) {
      confirmError = 'Les mots de passe ne correspondent pas.';
    }

    if (nomError != null ||
        prenomError != null ||
        emailError != null ||
        passwordError != null ||
        confirmError != null) {
      setState(() {
        _nomError = nomError;
        _prenomError = prenomError;
        _emailError = emailError;
        _passwordError = passwordError;
        _confirmError = confirmError;
      });
      return;
    }

    setState(() => _submitting = true);
    try {
      await context.read<AuthController>().register(
        nom: nom,
        prenom: prenom,
        email: email,
        password: password,
      );
      if (!mounted) return;
      // Remplace la pile de navigation pour empêcher un retour vers
      // le formulaire d'inscription via le bouton retour.
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

  Widget _errorBanner() {
    if (_submitError == null) return const SizedBox.shrink();
    return Column(
      children: [
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
              const AppIcon(AppIcons.error, size: 18, color: AppColors.error),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  _submitError!,
                  style: AppTextStyles.body.copyWith(color: AppColors.error),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
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
                    title: 'Créer un compte',
                    subtitle:
                        'Inscrivez-vous pour accéder à vos cours, notes '
                        'et à votre planning en quelques secondes.',
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _nomController,
                          label: 'Nom',
                          hintText: 'Votre nom',
                          textInputAction: TextInputAction.next,
                          prefixIcon: const Icon(AppIcons.profile),
                          errorText: _nomError,
                          onChanged: (_) => _clearFieldErrors(),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: AppTextField(
                          controller: _prenomController,
                          label: 'Prénom',
                          hintText: 'Votre prénom',
                          textInputAction: TextInputAction.next,
                          prefixIcon: const Icon(AppIcons.profile),
                          errorText: _prenomError,
                          onChanged: (_) => _clearFieldErrors(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
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
                    textInputAction: TextInputAction.next,
                    errorText: _passwordError,
                    onChanged: (_) => _clearFieldErrors(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppPasswordField(
                    controller: _confirmController,
                    label: 'Confirmer le mot de passe',
                    hintText: 'Confirmez votre mot de passe',
                    textInputAction: TextInputAction.done,
                    errorText: _confirmError,
                    onSubmitted: (_) => _submit(),
                    onChanged: (_) => _clearFieldErrors(),
                  ),
                  _errorBanner(),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    label: 'Créer mon compte',
                    onPressed: _submit,
                    isLoading: _submitting,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Align(
                    child: TextButton(
                      onPressed: () => context.go(AppRoutes.login),
                      child: const Text('J\'ai déjà un compte'),
                    ),
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
