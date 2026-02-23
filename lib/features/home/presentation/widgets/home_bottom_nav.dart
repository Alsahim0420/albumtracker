import 'package:flutter/material.dart';

import 'package:albumtracker/core/constants/app_constants.dart';
import 'package:albumtracker/core/theme/app_colors.dart';

/// Índice de la pestaña inferior.
enum HomeNavItem { album, repeated, missing, settings }

/// Barra inferior con pestañas y FAB.
class HomeBottomNav extends StatelessWidget {
  const HomeBottomNav({
    super.key,
    required this.currentIndex,
    this.onTap,
    this.onFabTap,
    this.showFab = true,
  });

  final HomeNavItem currentIndex;
  final ValueChanged<HomeNavItem>? onTap;
  final VoidCallback? onFabTap;
  /// Si false, no se muestra el FAB (ej. en Settings).
  final bool showFab;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.navBarBackground,
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
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavTile(
                    icon: Icons.grid_view_rounded,
                    label: AppConstants.homeNavAlbum,
                    isSelected: currentIndex == HomeNavItem.album,
                    onTap: () => onTap?.call(HomeNavItem.album),
                  ),
                  _NavTile(
                    icon: Icons.copy_rounded,
                    label: AppConstants.homeNavRepeated,
                    isSelected: currentIndex == HomeNavItem.repeated,
                    onTap: () => onTap?.call(HomeNavItem.repeated),
                  ),
                  _NavTile(
                    icon: Icons.playlist_add_rounded,
                    label: AppConstants.homeNavMissing,
                    isSelected: currentIndex == HomeNavItem.missing,
                    onTap: () => onTap?.call(HomeNavItem.missing),
                  ),
                  _NavTile(
                    icon: Icons.settings_outlined,
                    label: AppConstants.homeNavSettings,
                    isSelected: currentIndex == HomeNavItem.settings,
                    onTap: () => onTap?.call(HomeNavItem.settings),
                  ),
                ],
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
    final color = isSelected ? AppColors.primary : AppColors.navUnselected;
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
