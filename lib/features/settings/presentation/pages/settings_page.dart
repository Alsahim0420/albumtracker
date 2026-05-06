// ignore_for_file: deprecated_member_use, unused_local_variable, unnecessary_underscores, unused_import

import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:albumtracker/core/error/failures.dart';
import 'package:albumtracker/core/injection.dart';
import 'package:albumtracker/core/repository/album_repository.dart' as album_seed_stats;
import 'package:albumtracker/core/storage/hive_storage.dart';
import 'package:albumtracker/features/home/domain/repositories/album_repository.dart';
import 'package:albumtracker/features/home/domain/services/collection_human_csv_codec.dart';
import 'package:albumtracker/features/home/domain/use_cases/export_collection_csv_use_case.dart';
import 'package:albumtracker/features/home/domain/use_cases/import_collection_csv_use_case.dart';
import 'package:albumtracker/features/personalization/presentation/pages/personalization_page.dart';
import 'package:albumtracker/features/settings/presentation/widgets/settings_profile_card.dart';
import 'package:albumtracker/features/settings/presentation/widgets/settings_section.dart';

void _showLanguagePicker(BuildContext context) {
  final colors = Theme.of(context).colorScheme;
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: colors.surfaceContainerHighest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final ctxColors = Theme.of(ctx).colorScheme;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'settingsLanguage'.tr(),
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: ctxColors.onSurface,
                    ),
              ),
              const SizedBox(height: 16),
              _LanguageOption(
                label: 'languageEnglish'.tr(),
                isSelected: ctx.locale.languageCode == 'en',
                onTap: () {
                  ctx.setLocale(const Locale('en'));
                  Navigator.of(ctx).pop();
                },
              ),
              const SizedBox(height: 8),
              _LanguageOption(
                label: 'languageSpanish'.tr(),
                isSelected: ctx.locale.languageCode == 'es',
                onTap: () {
                  ctx.setLocale(const Locale('es'));
                  Navigator.of(ctx).pop();
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Contenido de la pestaña Settings (sin Scaffold; se usa dentro de Home).
class SettingsPage extends StatelessWidget {
  final Function(String?) onThemeChanged;
  final void Function(ThemeMode mode)? onThemeModeChanged;

  const SettingsPage({
    super.key,
    required this.onThemeChanged,
    this.onThemeModeChanged,
  });

  void _showAppearanceSheet(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final initialMode = storedThemeMode;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AppearanceSheetContent(
        initialMode: initialMode,
        onApply: (String mode) async {
          await saveThemeMode(mode);
          final themeMode = mode == 'light'
              ? ThemeMode.light
              : mode == 'dark'
                  ? ThemeMode.dark
                  : ThemeMode.system;
          onThemeModeChanged?.call(themeMode);
          if (ctx.mounted) Navigator.of(ctx).pop();
        },
      ),
    );
  }

  void _openPersonalizeExperience(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PersonalizationPage(
          showBackButton: true,
          onComplete: () => Navigator.of(context).pop(),
          onThemeChanged: onThemeChanged,
        ),
      ),
    );
  }

  static const _urlChannel = MethodChannel('com.app.albumcollect/url_launcher');

  Future<void> _exportCsv(BuildContext context) async {
    final export = sl<ExportCollectionCsvUseCase>();
    final result = await export(
      ExportCollectionCsvParams(languageCode: context.locale.languageCode),
    );
    if (!context.mounted) return;
    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_csvFailureMessage(failure, forImport: false))),
      ),
      (_) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('settingsExportSuccess'.tr())),
      ),
    );
  }

  Future<void> _importCsv(BuildContext context) async {
    final pick = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true,
    );
    if (!context.mounted) return;
    if (pick == null || pick.files.isEmpty) return;

    final file = pick.files.single;

    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('settingsImportReadError'.tr())),
      );
      return;
    }

    late final String csvText;
    try {
      csvText = utf8.decode(bytes);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('settingsImportEncodingError'.tr())),
        );
      }
      return;
    }

    if (csvText.trim().isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('settingsImportFileEmpty'.tr())),
        );
      }
      return;
    }

    final nameLower = file.name.toLowerCase();
    var extLower = file.extension?.toLowerCase().trim() ?? '';
    if (extLower.startsWith('.')) {
      extLower = extLower.substring(1);
    }
    final looksLikeExtensionCsv =
        nameLower.endsWith('.csv') || extLower == 'csv';
    final looksLikeContent =
        CollectionHumanCsvCodec.textLooksLikeAlbumTrackerCsv(csvText);
    if (!looksLikeExtensionCsv && !looksLikeContent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('settingsImportWrongFileType'.tr())),
      );
      return;
    }

    var mode = CollectionCsvImportMode.merge;
    final albumRepo = sl<AlbumRepository>();
    final collResult = await albumRepo.getCollection();
    final hasStickers = collResult.fold(
      (_) => false,
      (m) => m.values.any((v) => v > 0),
    );

    if (hasStickers && context.mounted) {
      final choice = await showDialog<CollectionCsvImportMode>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Text('settingsImportModalTitle'.tr()),
          content: Text('settingsImportModalMessage'.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('settingsImportModalCancel'.tr()),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(ctx).pop(CollectionCsvImportMode.replace),
              child: Text('settingsImportModalReplace'.tr()),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(ctx).pop(CollectionCsvImportMode.merge),
              child: Text('settingsImportModalMerge'.tr()),
            ),
          ],
        ),
      );
      if (!context.mounted) return;
      if (choice == null) return;
      mode = choice;
    }

    final import = sl<ImportCollectionCsvUseCase>();
    final applied = await import(
      ImportCollectionCsvParams(csvText, mode: mode),
    );
    if (!context.mounted) return;
    applied.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_csvFailureMessage(failure, forImport: true))),
      ),
      (count) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            count == 0
                ? 'settingsImportEmpty'.tr()
                : 'settingsImportSuccess'.tr(args: [count.toString()]),
          ),
        ),
      ),
    );
  }

  String _csvFailureMessage(Failure failure, {required bool forImport}) {
    if (failure is CsvImportFailure) {
      return failure.message != null && failure.message!.isNotEmpty
          ? '${'settingsImportError'.tr()}: ${failure.message}'
          : 'settingsImportError'.tr();
    }
    return forImport ? 'settingsImportError'.tr() : 'settingsExportError'.tr();
  }

  Future<void> _openUrl(BuildContext context, String urlString) async {
    try {
      try {
        final ok = await _urlChannel.invokeMethod<bool>('openUrl', {'url': urlString});
        if (ok == true) {
          return;
        }
      } on MissingPluginException {
        // En iOS/web no está el canal; usar url_launcher
      }
      final uri = Uri.parse(urlString);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir el enlace')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = storedUserName ?? 'defaultUserName'.tr();
    final colorHex = storedProfileColorHex;
    Color? avatarColor;
    if (colorHex != null && colorHex.isNotEmpty) {
      final hex = colorHex.startsWith('#') ? colorHex.substring(1) : colorHex;
      if (hex.length >= 8) {
        avatarColor = Color(int.parse(hex, radix: 16));
      } else if (hex.length == 6) {
        avatarColor = Color(int.parse('FF$hex', radix: 16));
      }
    }
    return ValueListenableBuilder(
      valueListenable: collectionBox.listenable(),
      builder: (context, __, ___) {
        final colors = Theme.of(context).colorScheme;
        final s = album_seed_stats.AlbumRepository.getGlobalStats();
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 88),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Text(
                  'settingsTitle'.tr(),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 28),
                ),
              ),
              SettingsProfileCard(
                userName: userName,
                avatarColor: avatarColor,
                collected: s.collectedStickers,
                total: s.totalStickers,
              ),
              SettingsSectionHeader(title: 'settingsAccount'),
              SettingsTile(
                icon: Icons.language_rounded,
                title: 'settingsLanguage',
                trailing: Text(
                  context.locale.languageCode == 'es' ? 'languageSpanish'.tr() : 'languageEnglish'.tr(),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                onTap: () => _showLanguagePicker(context),
              ),
              SettingsTile(
                icon: Icons.palette_outlined,
                title: 'settingsAppearance',
                onTap: () => _showAppearanceSheet(context),
              ),
              SettingsTile(
                icon: Icons.tune_rounded,
                title: 'personalizationPageTitle',
                onTap: () => _openPersonalizeExperience(context),
              ),
              SettingsTile(
                icon: Icons.shield_outlined,
                title: 'settingsPrivacySecurity',
                onTap: () => _openUrl(context, 'https://albumcollect2026.netlify.app/privacidad'),
              ),
              SettingsSectionHeader(title: 'settingsCollectionData'),
              SettingsTile(
                icon: Icons.download_outlined,
                title: 'settingsExportData',
                onTap: () => _exportCsv(context),
              ),
              SettingsTile(
                icon: Icons.upload_file_outlined,
                title: 'settingsImportData',
                onTap: () => _importCsv(context),
              ),
              SettingsSectionHeader(title: 'settingsSupport'),
              SettingsTile(
                icon: Icons.info_outline_rounded,
                title: 'settingsAppInformation',
                onTap: () => _openUrl(context, 'https://albumcollect2026.netlify.app/'),
              ),
              SettingsTile(
                icon: Icons.help_outline_rounded,
                title: 'settingsHelpFaq',
                onTap: () {},
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AppearanceSheetContent extends StatefulWidget {
  const _AppearanceSheetContent({
    required this.initialMode,
    required this.onApply,
  });

  final String initialMode;
  final void Function(String mode) onApply;

  @override
  State<_AppearanceSheetContent> createState() => _AppearanceSheetContentState();
}

class _AppearanceSheetContentState extends State<_AppearanceSheetContent> {
  late String _selectedMode;

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.initialMode;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'appearanceTitle'.tr(),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.onSurface,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'appearanceSubtitle'.tr(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: colors.onSurface),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _AppearanceOption(
              value: 'light',
              groupValue: _selectedMode,
              icon: Icons.light_mode_rounded,
              iconColor: Colors.amber.shade700,
              title: 'appearanceLight'.tr(),
              description: 'appearanceLightDesc'.tr(),
              onTap: () => setState(() => _selectedMode = 'light'),
            ),
            const SizedBox(height: 12),
            _AppearanceOption(
              value: 'dark',
              groupValue: _selectedMode,
              icon: Icons.dark_mode_rounded,
              iconColor: Colors.blue.shade200,
              title: 'appearanceDark'.tr(),
              description: 'appearanceDarkDesc'.tr(),
              onTap: () => setState(() => _selectedMode = 'dark'),
            ),
            const SizedBox(height: 12),
            _AppearanceOption(
              value: 'system',
              groupValue: _selectedMode,
              icon: Icons.settings_suggest_rounded,
              iconColor: colors.onSurfaceVariant,
              title: 'appearanceSystem'.tr(),
              description: 'appearanceSystemDesc'.tr(),
              onTap: () => setState(() => _selectedMode = 'system'),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.onSurface,
                      side: BorderSide(color: colors.outline),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('appearanceCancel'.tr()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => widget.onApply(_selectedMode),
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('appearanceApply'.tr()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AppearanceOption extends StatelessWidget {
  const _AppearanceOption({
    required this.value,
    required this.groupValue,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final String value;
  final String groupValue;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final selected = value == groupValue;
    return Material(
      color: selected ? colors.surfaceContainerHigh : colors.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.onSurface,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Radio<String>(
                value: value,
                groupValue: groupValue,
                onChanged: (_) => onTap(),
                activeColor: colors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurface,
                      ),
                ),
              ),
              if (isSelected)
                Icon(Icons.check_rounded, size: 22, color: colors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
