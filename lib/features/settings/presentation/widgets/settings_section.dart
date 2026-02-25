import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Encabezado de sección en Settings (ACCOUNT, COLLECTION DATA, etc.).
class SettingsSectionHeader extends StatelessWidget {
  const SettingsSectionHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.placeholder,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}

/// Fila de configuración con icono, título, valor opcional y chevron.
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  /// Texto o badge a la derecha (ej. "On", "Up to date").
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.primaryContainer,
      child: InkWell(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: colors.onPrimaryContainer, width: 1),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: colors.onSurfaceVariant),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.onSurface,
                      ),
                ),
              ),
              if (trailing != null) ...[
                trailing!,
                const SizedBox(width: 8),
              ],
              Icon(Icons.chevron_right, color: colors.onSurfaceVariant, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
