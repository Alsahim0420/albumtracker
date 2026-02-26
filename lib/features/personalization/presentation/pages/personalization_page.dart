// ignore_for_file: deprecated_member_use

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/storage/hive_storage.dart';
import '../../../../core/theme/app_colors.dart';

/// Pantalla de personalización (onboarding). Solo se muestra en el primer arranque.
/// Nombre obligatorio; equipo favorito y color de perfil opcionales.
class PersonalizationPage extends StatefulWidget {
  const PersonalizationPage({
    super.key,
    required this.onComplete,
  });

  /// Se llama tras guardar el perfil y marcar onboarding como completado.
  final VoidCallback onComplete;

  @override
  State<PersonalizationPage> createState() => _PersonalizationPageState();
}

class _PersonalizationPageState extends State<PersonalizationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _selectedTeam;
  Color? _selectedColor;
  bool _isSaving = false;

  static const List<String> _teamOptions = [
    '',
    'USA',
    'Mexico',
    'Canada',
    'Argentina',
    'Brazil',
    'Costa Rica',
    'England',
    'France',
    'Germany',
    'Spain',
  ];

  static const List<Color> _colorOptions = [
    Color(0xFF3B82F6), // primary blue
    Color(0xFFE07C4A), // profile orange
    Color(0xFF22C55E), // green
    Color(0xFF8B5CF6), // purple
    Color(0xFFEC4899), // pink
    Color(0xFFF59E0B), // amber
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _onContinue() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final name = _nameController.text.trim();
    await saveUserProfile(
      name: name,
      favoriteTeam: _selectedTeam != null && _selectedTeam!.isNotEmpty
          ? _selectedTeam
          : null,
      profileColorHex: _selectedColor != null
          ? '#${_selectedColor!.value.toRadixString(16).padLeft(8, '0')}'
          : null,
    );
    await setOnboardingCompleted();
    if (!mounted) return;
    setState(() => _isSaving = false);
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.splashBackground,
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
                  value: _selectedTeam ?? '',
                  decoration: InputDecoration(
                    hintText: 'personalizationFavoriteTeamHint'.tr(),
                  ),
                  dropdownColor: AppColors.inputBackground,
                  items: _teamOptions.map((t) {
                    return DropdownMenuItem<String>(
                      value: t,
                      child: Text(
                        t.isEmpty ? 'personalizationNone'.tr() : t.tr(),
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedTeam = v),
                ),
                const SizedBox(height: 24),
                Text(
                  'personalizationColorLabel'.tr(),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: _colorOptions.map((c) {
                    final isSelected = _selectedColor == c;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _selectedColor = isSelected ? null : c),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.textPrimary
                                  : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: c.withValues(alpha: 0.5),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _isSaving ? null : _onContinue,
                  child: _isSaving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textPrimary,
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
