import 'package:flutter/material.dart';

/// Encabezado de sección del álbum (ej. FWC • INTRO, FRA • FRANCE).
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.leading,
  });

  final String title;
  /// Opcional: barra vertical o bandera (Widget pequeño).
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          leading ??
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          const SizedBox(width: 10),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.onSurface,
                ),
          ),
        ],
      ),
    );
  }
}
