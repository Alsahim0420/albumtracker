import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';


enum HomeFilter { all, missing, swaps }

/// Segmentos de filtro: All, Missing, Swaps.
class FilterSegments extends StatelessWidget {
  const FilterSegments({
    super.key,
    required this.selected,
    this.onChanged,
  });

  final HomeFilter selected;
  final ValueChanged<HomeFilter>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          _Segment(
            label: 'homeFilterAll'.tr(),
            isSelected: selected == HomeFilter.all,
            isFirst: true,
            onTap: () => onChanged?.call(HomeFilter.all),
          ),
          _Segment(
            label: 'homeFilterMissing'.tr(),
            isSelected: selected == HomeFilter.missing,
            isFirst: false,
            onTap: () => onChanged?.call(HomeFilter.missing),
          ),
          _Segment(
            label: 'homeFilterSwaps'.tr(),
            isSelected: selected == HomeFilter.swaps,
            isFirst: false,
            isLast: true,
            onTap: () => onChanged?.call(HomeFilter.swaps),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.isSelected,
    required this.isFirst,
    this.isLast = false,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? colors.primary : colors.primaryContainer,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(isFirst ? 10 : 0),
              bottomLeft: Radius.circular(isFirst ? 10 : 0),
              topRight: Radius.circular(isLast ? 10 : 0),
              bottomRight: Radius.circular(isLast ? 10 : 0),
            ),
            border: Border.all(
              color: colors.outlineVariant,
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: isSelected ? colors.onSurface : colors.onSurfaceVariant,
                  fontSize: 14,
                ),
          ),
        ),
      ),
    );
  }
}
