import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:albumtracker/core/theme/app_colors.dart';
import 'package:albumtracker/features/home/presentation/models/team_sticker_item.dart';

/// Bottom sheet para marcar cantidad de una pegatina (+ / - y Listo).
class StickerCountSheet extends StatefulWidget {
  const StickerCountSheet({
    super.key,
    required this.sticker,
    required this.initialCount,
    this.onDone,
  });

  final TeamStickerItem sticker;
  final int initialCount;
  final void Function(int count)? onDone;

  @override
  State<StickerCountSheet> createState() => _StickerCountSheetState();
}

class _StickerCountSheetState extends State<StickerCountSheet> {
  late int _count;

  @override
  void initState() {
    super.initState();
    _count = widget.initialCount;
  }

  void _increment() => setState(() => _count = (_count + 1).clamp(0, 99));
  void _decrement() => setState(() => _count = (_count - 1).clamp(0, 99));

  void _done() {
    widget.onDone?.call(_count);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.splashBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: AppColors.textPrimary, size: 24),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  ),
                ],
              ),
              _StickerPreviewCard(code: widget.sticker.code, label: widget.sticker.name ?? widget.sticker.label),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _CircleButton(
                    icon: Icons.remove,
                    onTap: _decrement,
                    enabled: _count > 0,
                  ),
                  const SizedBox(width: 24),
                  SizedBox(
                    width: 64,
                    child: Text(
                      '$_count',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  _CircleButton(
                    icon: Icons.add,
                    onTap: _increment,
                    enabled: true,
                  ),
                ],
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _done,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('stickerCountDone'.tr()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StickerPreviewCard extends StatelessWidget {
  const _StickerPreviewCard({required this.code, required this.label});

  final String code;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.9),
            AppColors.primary.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 16,
            bottom: 16,
            child: Icon(Icons.star, color: AppColors.textPrimary.withValues(alpha: 0.4), size: 48),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'stickerId'.tr(args: [code]),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary.withValues(alpha: 0.95),
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? AppColors.primary : AppColors.cardBackground,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: enabled ? AppColors.textPrimary : AppColors.textSecondary,
            size: 28,
          ),
        ),
      ),
    );
  }
}
