import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:albumtracker/core/theme/app_colors.dart';

enum TeamStickerFilter { all, missing, duplicates }

/// Tabs para filtrar: All Stickers, Missing, Duplicates (n).
class TeamStickerFilterTabs extends StatelessWidget {
  const TeamStickerFilterTabs({
    super.key,
    required this.selected,
    required this.duplicateCount,
    this.onChanged,
  });

  final TeamStickerFilter selected;
  final int duplicateCount;
  final ValueChanged<TeamStickerFilter>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          Expanded(
            child: _Chip(
              label: 'teamDetailAllStickers'.tr(),
              isSelected: selected == TeamStickerFilter.all,
              onTap: () => onChanged?.call(TeamStickerFilter.all),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _Chip(
              label: 'homeFilterMissing'.tr(),
              isSelected: selected == TeamStickerFilter.missing,
              onTap: () => onChanged?.call(TeamStickerFilter.missing),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _Chip(
              label: 'teamDetailDuplicates'.tr(args: [duplicateCount.toString()]),
              isSelected: selected == TeamStickerFilter.duplicates,
              onTap: () => onChanged?.call(TeamStickerFilter.duplicates),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.inputBorder),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
