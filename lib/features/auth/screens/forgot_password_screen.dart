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
import '../../../shared/widgets/app_text_field.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_header.dart';

enum _ForgotState { idle, loading, success, error }

/// Écran de réinitialisation du mot de passe.
///
/// La soumission appelle l'endpoint backend via [AuthController].
/// L'endpoint n'est pas encore exposé par le backend : la configuration
/// est centralisée dans `AuthEndpoints.forgotPassword`.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();

  _ForgotState _state = _ForgotState.idle;
  String? _emailError;
  String? _submitError;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final String email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _state = _ForgotState.error;
        _emailError = 'Veuillez saisir votre email.';
        _submitError = null;
      });
      return;
    }

    setState(() {
      _state = _ForgotState.loading;
      _emailError = null;
      _submitError = null;
    });

    try {
      await context.read<AuthController>().sendPasswordResetLink(email);
      if (!mounted) return;
      setState(() => _state = _ForgotState.success);
    } on AppException catch (e) {
      _setError(e.message);
    } catch (_) {
      _setError('Une erreur est survenue. Veuillez réessayer.');
    }
  }

  void _setError(String message) {
    if (!mounted) return;
    setState(() {
      _state = _ForgotState.error;
      _submitError = message;
    });
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
              child: _state == _ForgotState.success
                  ? _buildSuccess()
                  : _buildForm(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AuthHeader(
          title: 'Mot de passe oublié ?',
          subtitle:
              'Saisissez votre adresse email, nous vous enverrons un '
              'lien pour réinitialiser votre mot de passe.',
        ),
        const SizedBox(height: AppSpacing.xl),
        AppTextField(
          controller: _emailController,
          label: 'Email',
          hintText: 'vous@exemple.com',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          prefixIcon: const Icon(AppIcons.mail),
          errorText: _emailError,
          onSubmitted: (_) => _state == _ForgotState.loading ? null : _submit(),
          onChanged: (_) {
            if (_emailError != null || _submitError != null) {
              setState(() {
                _emailError = null;
                _submitError = null;
              });
            }
          },
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
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: 'Envoyer le lien',
          onPressed: _state == _ForgotState.loading ? null : _submit,
          isLoading: _state == _ForgotState.loading,
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: 'Retour à la connexion',
          variant: AppButtonVariant.text,
          onPressed: () => context.go(AppRoutes.login),
          isFullWidth: false,
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppIcon(AppIcons.checkCircle, size: 48, color: AppColors.success),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Lien envoyé !',
          textAlign: TextAlign.center,
          style: AppTextStyles.title,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Si un compte est associé à cette adresse, un lien de '
          'réinitialisation a été envoyé par email.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyLong,
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: 'Retour à la connexion',
          onPressed: () => context.go(AppRoutes.login),
        ),
      ],
    );
  }
}
