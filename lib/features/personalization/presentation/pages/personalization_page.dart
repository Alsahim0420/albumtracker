// ignore_for_file: deprecated_member_use

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/data/world_cup_2026_seed.dart';
import '../../../../core/models/team_model.dart';
import '../../../../core/storage/hive_storage.dart';

/// Pantalla de personalización (onboarding). Solo se muestra en el primer arranque.
/// Nombre obligatorio; país/equipo favorito opcional (cambia el color de la vista como en Settings).
class PersonalizationPage extends StatefulWidget {
  const PersonalizationPage({
    super.key,
    required this.onComplete,
    this.onThemeChanged,
  });

  /// Se llama tras guardar el perfil y marcar onboarding como completado.
  final VoidCallback onComplete;

  /// Se llama al elegir un país/equipo para actualizar el tema de la vista al instante.
  final void Function(String? teamId)? onThemeChanged;

  @override
  State<PersonalizationPage> createState() => _PersonalizationPageState();
}

class _PersonalizationPageState extends State<PersonalizationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _selectedTeamId;
  bool _isSaving = false;

  List<TeamModel> get _teams =>
      WorldCup2026Seed.groups.expand((g) => g.teams).toList();

  @override
  void dispose() {
    _nameController.dispose();
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
    await setOnboardingCompleted();
    if (!mounted) return;
    setState(() => _isSaving = false);
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                Text(
                  'personalizationTitle'.tr(),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'personalizationSubtitle'.tr(),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                Text(
                  'personalizationNameLabel'.tr(),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: 'personalizationNameHint'.tr(),
                    suffixIcon: Icon(Icons.person_outline, size: 22),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'personalizationNameError'.tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'personalizationFavoriteTeamLabel'.tr(),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedTeamId ?? '',
                  decoration: InputDecoration(
                    hintText: 'personalizationFavoriteTeamHint'.tr(),
                  ),
                  dropdownColor: colors.surfaceContainerHighest,
                  items: [
                    DropdownMenuItem<String>(
                      value: '',
                      child: Text(
                        'personalizationNone'.tr(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colors.onSurface,
                            ),
                      ),
                    ),
                    ..._teams.map((team) {
                      return DropdownMenuItem<String>(
                        value: team.id,
                        child: Text(
                          team.name,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: colors.onSurface,
                              ),
                        ),
                      );
                    }),
                  ],
                  onChanged: _onTeamChanged,
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _isSaving ? null : _onContinue,
                  child: _isSaving
                      ? SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.onSurface,
                          ),
                        )
                      : Text('personalizationContinue'.tr()),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
