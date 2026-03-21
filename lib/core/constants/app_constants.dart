/// Constantes globales de la app (versión, edición, textos del splash).
abstract final class AppConstants {
  AppConstants._();

  static const String appName = 'Album Collect 2026';
  static const String version = 'v1.0.2';
  static const String edition = 'WORLD CUP 2026 EDITION';
  static const String tagline = 'Made for Collectors';
  static const String versionTagline = '$version • $tagline';

  /// Duración del splash antes de navegar (ms).
  static const int splashDurationMs = 2500;

  // --- Personalization (Onboarding) ---
  static const String personalizationTitle = 'Personalize your experience';
  static const String personalizationSubtitle =
      'Set up your profile to get started. You can change this later in Settings.';
  static const String personalizationNameLabel = 'Your name';
  static const String personalizationNameHint = 'e.g. Alex';
  static const String personalizationFavoriteTeamLabel = 'Favorite team (optional)';
  static const String personalizationFavoriteTeamHint = 'Select a team';
  static const String personalizationColorLabel = 'Profile color (optional)';
  static const String personalizationContinue = 'Continue';

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
  static const String homeTitle = 'World Cup 2026';
  static const String homeSubtitle = 'World Cup 2026';
  static const String homeAlbumCollection = 'ALBUM COLLECTION';
  static const String homeTotalCollection = 'TOTAL COLLECTION';
  static const String homeCompleted = 'Completed';
  static const String homeSwapsAvailable = 'Swaps available';
  static const String homeFilterAll = 'All';
  static const String homeFilterMissing = 'Missing';
  static const String homeFilterSwaps = 'Swaps';
  static const String homeTabGroups = 'Groups';
  static const String homeTabTeams = 'Teams';
  static const String homeTabSpecials = 'Specials';
  static const String homeTabMarketplace = 'Marketplace';
  static const String homeComplete = 'COMPLETE';
  static const String homeShowMoreGroups = 'Show %s More Groups';
  static const String homeNavAlbum = 'Album';
  static const String homeNavTrade = 'Trade';
  static const String homeNavRepeated = 'Repeated';
  static const String homeNavMissing = 'Missing';
  static const String homeNavSettings = 'Settings';

  // --- Team detail ---
  static const String teamDetailBackGroups = 'Groups';
  static const String teamDetailGroupEvent = '%s • 2026 World Cup';
  static const String teamDetailCompletionStatus = 'COMPLETION STATUS';
  static const String teamDetailTotal = 'TOTAL';
  static const String teamDetailFound = 'FOUND';
  static const String teamDetailMissing = 'MISSING';
  static const String teamDetailAllStickers = 'All Stickers';
  static const String teamDetailMissingTab = 'Missing';
  static const String teamDetailDuplicates = 'Duplicates';
  static const String teamDetailSquadMembers = 'SQUAD MEMBERS';
  static const String teamDetailTeamBadge = 'Team Badge';
  static const String teamDetailTeamPhoto = 'Team Photo';
  static const String teamDetailNotFound = 'Not Found';
  static const String stickerCountDone = 'Listo';

  // --- Bulk Add Stickers ---
  static const String bulkAddTitle = 'Bulk Add Stickers';
  static const String bulkAddSubtitle = 'Quickly import multiple numbers';
  static const String bulkAddInfoText =
      'Type sticker numbers separated by commas or spaces. Duplicates will be ignored automatically.';
  static const String bulkAddPlaceholder = 'e.g. 12, 45, 102, 290...';
  static const String bulkAddStickersFound = 'stickers found';
  static const String bulkAddExampleFormat = 'EXAMPLE FORMAT';
  static const String bulkAddExample1 = '10, 24, 32';
  static const String bulkAddExample2 = '10 24 32';
  static const String bulkAddShortcuts = 'Shortcuts';
  static const String bulkAddCancel = 'Cancel';
  static const String bulkAddConfirm = 'Confirm & Add';

  // --- Settings ---
  static const String settingsTitle = 'Settings';
  static const String settingsCollectorLevel = 'Collector Level: Gold';
  static const String settingsStickersCollected = 'Stickers Collected';
  static const String settingsAccount = 'ACCOUNT';
  static const String settingsAccountSettings = 'Account Settings';
  static const String settingsNotifications = 'Notifications';
  static const String settingsNotificationsOn = 'On';
  static const String settingsPrivacySecurity = 'Privacy & Security';
  static const String settingsCollectionData = 'COLLECTION DATA';
  static const String settingsExportData = 'Export Data';
  static const String settingsSyncStatus = 'Sync Status';
  static const String settingsSyncUpToDate = 'Up to date';
  static const String settingsSupport = 'SUPPORT';
  static const String settingsAppInformation = 'App Information';
  static const String settingsHelpFaq = 'Help & FAQ';
}
