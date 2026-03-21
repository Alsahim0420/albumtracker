// ignore_for_file: deprecated_member_use

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/data/world_cup_2026_seed.dart';
import '../../../../core/models/team_model.dart';
import '../../../../core/storage/hive_storage.dart';
import '../../../home/presentation/widgets/flag_placeholder.dart';

class PersonalizationPage extends StatefulWidget {
  const PersonalizationPage({
    super.key,
    required this.onComplete,
    this.onThemeChanged,
    this.showBackButton = false,
  });

  final VoidCallback onComplete;
  final void Function(String? teamId)? onThemeChanged;
  /// Si es true (abierta desde Configuración), se muestra el botón atrás en el AppBar.
  final bool showBackButton;

  @override
  State<PersonalizationPage> createState() => _PersonalizationPageState();
}

class _PersonalizationPageState extends State<PersonalizationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _searchController = TextEditingController();
  String? _selectedTeamId;
  bool _isSaving = false;

  List<TeamModel> get _teams =>
      WorldCup2026Seed.groups.expand((g) => g.teams).toList();

  List<TeamModel> get _filteredTeams {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _teams;
    return _teams.where((t) => t.name.toLowerCase().contains(q)).toList();
  }

  @override
  void initState() {
    super.initState();
    final savedName = storedUserName;
    if (savedName != null && savedName.isNotEmpty) {
      _nameController.text = savedName;
    }
    final savedTeamId = storedFavoriteTeam;
    if (savedTeamId != null && savedTeamId.isNotEmpty) {
      _selectedTeamId = savedTeamId;
    }
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTeamChanged(String? teamId) {
    setState(() => _selectedTeamId = teamId);
    widget.onThemeChanged?.call(teamId);
  }

  Future<void> _onContinue() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final name = _nameController.text.trim();
    await saveUserProfile(
      name: name,
      favoriteTeam: _selectedTeamId != null && _selectedTeamId!.isNotEmpty
          ? _selectedTeamId
          : null,
    );
    if (widget.showBackButton == false) {
      await setOnboardingCompleted();
    }
    if (!mounted) return;
    setState(() => _isSaving = false);
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        scrolledUnderElevation: 0,
        leading: widget.showBackButton
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: colors.onSurface),
                onPressed: () => Navigator.maybePop(context),
              )
            : null,
        automaticallyImplyLeading: widget.showBackButton,
        title: Text(
          context.tr('personalizationPageTitle'),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colors.onSurface,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
            child: LinearProgressIndicator(
              value: 0.75,
              backgroundColor: isDark
                  ? colors.surfaceContainerHighest
                  : colors.outline.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 32),
                      _SectionTitle(title: context.tr('personalizationNameQuestion')),
                const SizedBox(height: 8),
                Text(
                  context.tr('personalizationNameDescription'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          hintText: context.tr('personalizationNamePlaceholder'),
                          filled: true,
                          fillColor: isDark
                              ? colors.surfaceContainerHigh
                              : colors.surfaceContainerHighest.withOpacity(0.6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colors.primary, width: 1),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return context.tr('personalizationNameError');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      _SectionTitle(title: context.tr('personalizationRegionTitle')),
                const SizedBox(height: 8),
                Text(
                  context.tr('personalizationRegionDescription'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: context.tr('personalizationSearchCountries'),
                          prefixIcon: Icon(
                            Icons.search,
                            color: colors.onSurfaceVariant,
                            size: 22,
                          ),
                          filled: true,
                          fillColor: isDark
                              ? colors.surfaceContainerHigh
                              : colors.surfaceContainerHighest.withOpacity(0.6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._filteredTeams.map((team) {
                        final isSelected = _selectedTeamId == team.id;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Material(
                            color: isDark
                                ? colors.surfaceContainerHigh
                                : colors.surfaceContainerHighest.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                            elevation: isDark ? 0 : 1,
                            shadowColor: colors.shadow.withOpacity(0.08),
                            child: InkWell(
                              onTap: () => _onTeamChanged(team.id),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    _TeamFlagCircle(team: team),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        team.name,
                                        style: theme.textTheme.bodyLarge?.copyWith(
                                          color: colors.onSurface,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                    Radio<String>(
                                      value: team.id,
                                      groupValue: _selectedTeamId,
                                      onChanged: (v) => _onTeamChanged(v),
                                      activeColor: colors.primary,
                                      fillColor: WidgetStateProperty.resolveWith((states) {
                                        if (states.contains(WidgetState.selected)) {
                                          return colors.primary;
                                        }
                                        return colors.onSurfaceVariant;
                                      }),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    onPressed: _isSaving ? null : _onContinue,
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSaving
                        ? SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.onPrimary,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(context.tr('personalizationSaveAndContinue')),
                              const SizedBox(width: 8),
                              Icon(Icons.arrow_forward, size: 20, color: colors.onPrimary),
                            ],
                          ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      context.tr('personalizationChangeLater'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: colors.onSurface,
      ),
    );
  }
}

/// Mismas dimensiones que en la vista de detalle del equipo (team_detail_page).
class _TeamFlagCircle extends StatelessWidget {
  const _TeamFlagCircle({required this.team});

  final TeamModel team;

  static const double _flagWidth = 48;
  static const double _flagHeight = 36;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (team.flagAssetPath != null && team.flagAssetPath!.isNotEmpty) {
      return SizedBox(
        width: _flagWidth,
        height: _flagHeight,
        child: FittedBox(
          fit: BoxFit.contain,
          child: FlagPlaceholder(code: team.flagAssetPath!),
        ),
      );
    }
    return SizedBox(
      width: _flagWidth,
      height: _flagHeight,
      child: Container(
        decoration: BoxDecoration(
          color: colors.outlineVariant,
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: Text(
          team.name.isNotEmpty ? team.name.substring(0, 1) : '?',
          style: TextStyle(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}
