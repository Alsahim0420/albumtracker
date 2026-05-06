import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:albumtracker/core/data/shield_assets.dart';
import 'package:albumtracker/core/data/world_cup_2026_seed.dart';
import 'package:albumtracker/features/home/presentation/widgets/flag_placeholder.dart';

/// Nombre localizado para el código de equipo del álbum (seed / traducciones JSON).
String teamCountryFilterLocalizedName(String teamCode) {
  if (teamCode == WorldCup2026Seed.specialTeamCode) {
    return 'homeTabSpecials'.tr();
  }
  final team = WorldCup2026Seed.getTeamById(teamCode);
  return team?.name.tr() ?? teamCode;
}

/// Ruta `assets/flags/*.svg` si existe en el equipo o en el mapa de escudos.
String? teamCountryFilterFlagAssetPath(String teamCode) {
  final team = WorldCup2026Seed.getTeamById(teamCode);
  final fromTeam = team?.flagAssetPath;
  if (fromTeam != null && fromTeam.isNotEmpty) return fromTeam;
  return getShieldAssetPath(teamCode);
}

/// Texto compacto: `ESP — Spain` / localizado (sin emoji; la bandera va aparte).
String teamCountryFilterTitle(String teamCode) {
  final upper = teamCode.toUpperCase();
  return '$upper — ${teamCountryFilterLocalizedName(teamCode)}';
}

/// Leading: bandera SVG o icono si no hay asset (p. ej. especiales FWC sin escudo en mapa).
class TeamCountryFilterLeading extends StatelessWidget {
  const TeamCountryFilterLeading({
    super.key,
    required this.teamCode,
  });

  final String teamCode;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final path = teamCountryFilterFlagAssetPath(teamCode);
    if (path != null) {
      return FlagPlaceholder(code: path);
    }
    return SizedBox(
      width: FlagPlaceholder.flagWidth,
      height: FlagPlaceholder.flagHeight,
      child: Icon(
        teamCode == WorldCup2026Seed.specialTeamCode
            ? Icons.auto_awesome_outlined
            : Icons.flag_outlined,
        size: 18,
        color: colors.onSurfaceVariant,
      ),
    );
  }
}

/// Etiqueta del botón “Filtrar por país” cuando hay un equipo seleccionado.
class TeamCountryFilterBarContent extends StatelessWidget {
  const TeamCountryFilterBarContent({
    super.key,
    required this.selectedTeamCode,
    required this.textStyle,
  });

  final String? selectedTeamCode;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    if (selectedTeamCode == null) {
      return Text(
        'homeFilterAll'.tr(),
        style: textStyle,
      );
    }
    final code = selectedTeamCode!;
    return Row(
      children: [
        TeamCountryFilterLeading(teamCode: code),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            teamCountryFilterTitle(code),
            style: textStyle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Fila del bottom sheet de filtro (radio + bandera + título).
class TeamCountryFilterSheetTile extends StatelessWidget {
  const TeamCountryFilterSheetTile({
    super.key,
    required this.teamCode,
    required this.isSelected,
    required this.onTap,
  });

  final String teamCode;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                size: 22,
                color: isSelected ? colors.primary : colors.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              TeamCountryFilterLeading(teamCode: teamCode),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  teamCountryFilterTitle(teamCode),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: isSelected ? colors.onSurface : colors.onSurfaceVariant,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
