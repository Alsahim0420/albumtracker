import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/google_icon.dart';
import '../widgets/login_header.dart';
import '../widgets/social_login_button.dart';

/// Pantalla de inicio de sesión: email, contraseña, Log In y opciones sociales.
class LoginPage extends StatelessWidget {
  const LoginPage({
    super.key,
    this.onLoginSuccess,
    this.onCreateAccount,
    this.onForgotPassword,
  });

  /// Se invoca con el [BuildContext] de esta pantalla para navegar de forma segura.
  final void Function(BuildContext context)? onLoginSuccess;
  final void Function(BuildContext context)? onCreateAccount;
  final VoidCallback? onForgotPassword;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.splashBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              const LoginHeader(),
              const SizedBox(height: 32),
              Text(
                AppConstants.loginEmailLabel,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              TextFormField(
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: AppConstants.loginEmailHint,
                  suffixIcon: const Icon(Icons.mail_outline, size: 22),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppConstants.loginPasswordLabel,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              TextFormField(
                obscureText: true,
                decoration: InputDecoration(
                  hintText: AppConstants.loginPasswordHint,
                  suffixIcon: const Icon(Icons.visibility_off_outlined, size: 22),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onForgotPassword,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                  ),
                  child: const Text(AppConstants.loginForgotPassword),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onLoginSuccess != null ? () => onLoginSuccess!(context) : null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(AppConstants.loginButton),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 20),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(child: Divider(color: AppColors.inputBorder)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      AppConstants.loginOrContinueWith,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Expanded(child: Divider(color: AppColors.inputBorder)),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SocialLoginButton(
                      label: AppConstants.loginGoogle,
                      icon: const GoogleIcon(size: 20),
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SocialLoginButton(
                      label: AppConstants.loginApple,
                      icon: const Icon(Icons.apple_rounded, size: 22, color: AppColors.socialButtonText),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppConstants.loginNoAccount,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  TextButton(
                    onPressed: onCreateAccount != null ? () => onCreateAccount!(context) : null,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(AppConstants.loginCreateAccount),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
