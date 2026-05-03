import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';


/// Índice de la pestaña inferior.
enum HomeNavItem { album, repeated, missing, settings }

/// Barra inferior con pestañas. El FAB (+) va en [Scaffold.floatingActionButton]
/// para que el hit-test no quede detrás del listado.
class HomeBottomNav extends StatelessWidget {
  const HomeBottomNav({
    super.key,
    required this.currentIndex,
    this.onTap,
  });

  final HomeNavItem currentIndex;
  final ValueChanged<HomeNavItem>? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavTile(
                icon: Icons.grid_view_rounded,
                label: 'homeNavAlbum'.tr(),
                isSelected: currentIndex == HomeNavItem.album,
                onTap: () => onTap?.call(HomeNavItem.album),
              ),
              _NavTile(
                icon: Icons.copy_rounded,
                label: 'homeNavRepeated'.tr(),
                isSelected: currentIndex == HomeNavItem.repeated,
                onTap: () => onTap?.call(HomeNavItem.repeated),
              ),
              _NavTile(
                icon: Icons.playlist_add_rounded,
                label: 'homeFilterMissing'.tr(),
                isSelected: currentIndex == HomeNavItem.missing,
                onTap: () => onTap?.call(HomeNavItem.missing),
              ),
              _NavTile(
                icon: Icons.settings_outlined,
                label: 'homeNavSettings'.tr(),
                isSelected: currentIndex == HomeNavItem.settings,
                onTap: () => onTap?.call(HomeNavItem.settings),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = isSelected ? colors.primary : colors.onSurface.withValues(alpha: 0.6);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
