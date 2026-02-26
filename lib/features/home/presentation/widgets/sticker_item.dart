import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:albumtracker/core/theme/app_colors.dart';

/// Estado de una pegatina en el álbum.
enum StickerState {
  collected,
  missing,
  hasSwaps,
}

/// Celda de una pegatina en la rejilla del álbum.
class StickerItem extends StatelessWidget {
  const StickerItem({
    super.key,
    required this.number,
    required this.state,
    this.swapCount = 0,
    this.onTap,
  });

  final int number;
  final StickerState state;
  /// Cantidad extra para intercambio (muestra badge +1, +3, etc.).
  final int swapCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _backgroundColor;
    final textColor = state == StickerState.missing
        ? AppColors.textSecondary
        : AppColors.textPrimary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
          border: state == StickerState.missing
              ? Border.all(color: AppColors.inputBorder, width: 1)
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              'stickerId'.tr(args: [number.toString()]),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (swapCount > 0)
              Positioned(
                right: 4,
                bottom: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.swapGreenDark,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '+$swapCount',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color get _backgroundColor {
    switch (state) {
      case StickerState.collected:
        return AppColors.primary;
      case StickerState.missing:
        return AppColors.itemMissing;
      case StickerState.hasSwaps:
        return AppColors.swapGreen;
    }
  }
}
