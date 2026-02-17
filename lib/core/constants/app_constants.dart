/// Constantes globales de la app (versión, edición, textos del splash).
abstract final class AppConstants {
  AppConstants._();

  static const String appName = 'Album Tracker';
  static const String version = 'v1.0.2';
  static const String edition = 'WORLD CUP 2026 EDITION';
  static const String tagline = 'Made for Collectors';
  static const String versionTagline = '$version • $tagline';

  /// Duración del splash antes de navegar (ms).
  static const int splashDurationMs = 2500;

  // --- Login ---
  static const String loginWelcomeTitle = 'Welcome back';
  static const String loginSubtitle = 'Sign in to sync your 2026 collection across devices.';
  static const String loginEmailLabel = 'EMAIL';
  static const String loginEmailHint = 'name@example.com';
  static const String loginPasswordLabel = 'PASSWORD';
  static const String loginPasswordHint = 'Enter your password';
  static const String loginForgotPassword = 'Forgot password?';
  static const String loginButton = 'Log In';
  static const String loginOrContinueWith = 'Or continue with';
  static const String loginGoogle = 'Google';
  static const String loginApple = 'Apple';
  static const String loginNoAccount = "Don't have an account?";
  static const String loginCreateAccount = 'Create account';

  // --- Register ---
  static const String registerAppBrand = 'ALBUM TRACKER';
  static const String registerTitle = 'Create your account';
  static const String registerSubtitle =
      'Start tracking your 2026 World Cup collection today. Professional tools for serious collectors.';
  static const String registerFullNameLabel = 'Full Name';
  static const String registerFullNameHint = 'Jude Bellingham';
  static const String registerEmailLabel = 'Email address';
  static const String registerEmailHint = 'name@example.com';
  static const String registerPasswordLabel = 'Password';
  static const String registerPasswordHint = 'Minimum 8 characters';
  static const String registerButton = 'Create Account';
  static const String registerHasAccount = 'Already have an account?';
  static const String registerLogIn = 'Log in';
  static const String registerTermsPrefix =
      'By clicking "Create Account", you agree to our ';
  static const String registerTermsOfService = 'Terms of Service';
  static const String registerAnd = ' and ';
  static const String registerPrivacyPolicy = 'Privacy Policy';
  static const String registerTermsSuffix = '.';

  // --- Home ---
  static const String homeSubtitle = 'World Cup 2026';
  static const String homeCompleted = 'Completed';
  static const String homeSwapsAvailable = 'Swaps available';
  static const String homeFilterAll = 'All';
  static const String homeFilterMissing = 'Missing';
  static const String homeFilterSwaps = 'Swaps';
  static const String homeNavAlbum = 'Album';
  static const String homeNavTrade = 'Trade';
  static const String homeNavStats = 'Stats';
  static const String homeNavSettings = 'Settings';
}
