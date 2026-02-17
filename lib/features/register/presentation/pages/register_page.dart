import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/register_header.dart';

/// Pantalla de registro: nombre, email, contraseña y creación de cuenta.
class RegisterPage extends StatefulWidget {
  const RegisterPage({
    super.key,
    this.onRegisterSuccess,
    this.onLogIn,
    this.onTermsOfService,
    this.onPrivacyPolicy,
  });

  final VoidCallback? onRegisterSuccess;
  final VoidCallback? onLogIn;
  final VoidCallback? onTermsOfService;
  final VoidCallback? onPrivacyPolicy;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool _obscurePassword = true;

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
              const SizedBox(height: 24),
              const RegisterHeader(),
              const SizedBox(height: 32),
              Text(
                AppConstants.registerFullNameLabel,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              TextFormField(
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: AppConstants.registerFullNameHint,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppConstants.registerEmailLabel,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              TextFormField(
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: AppConstants.registerEmailHint,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppConstants.registerPasswordLabel,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              TextFormField(
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: AppConstants.registerPasswordHint,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 22,
                      color: AppColors.inputIcon,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: widget.onRegisterSuccess,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(AppConstants.registerButton),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 20),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppConstants.registerHasAccount,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  TextButton(
                    onPressed: widget.onLogIn,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      AppConstants.registerLogIn,
                      style: TextStyle(
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _TermsFooter(
                onTermsOfService: widget.onTermsOfService,
                onPrivacyPolicy: widget.onPrivacyPolicy,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _TermsFooter extends StatelessWidget {
  const _TermsFooter({
    this.onTermsOfService,
    this.onPrivacyPolicy,
  });

  final VoidCallback? onTermsOfService;
  final VoidCallback? onPrivacyPolicy;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    final linkStyle = style?.copyWith(
      color: AppColors.primary,
      decoration: TextDecoration.underline,
    );
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(AppConstants.registerTermsPrefix, style: style),
        GestureDetector(
          onTap: onTermsOfService,
          child: Text(AppConstants.registerTermsOfService, style: linkStyle),
        ),
        Text(AppConstants.registerAnd, style: style),
        GestureDetector(
          onTap: onPrivacyPolicy,
          child: Text(AppConstants.registerPrivacyPolicy, style: linkStyle),
        ),
        Text(AppConstants.registerTermsSuffix, style: style),
      ],
    );
  }
}
