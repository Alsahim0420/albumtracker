import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:albumtracker/core/data/world_cup_2026_seed.dart';
import 'package:albumtracker/core/models/sticker_model.dart';
import 'package:albumtracker/features/home/domain/entities/sticker_scan_result.dart';

/// Diálogo modal con resumen del escaneo (éxito o con incidencias).
Future<void> showStickerScanResultDialog(
  BuildContext context,
  BatchStickerScanResult result,
) async {
  final successfulItems = result.items
      .where(
        (e) =>
            e.status == StickerScanStatus.added ||
            e.status == StickerScanStatus.alreadyExists,
      )
      .toList();
  final successfulStickers = _dedupeSuccessfulStickers(successfulItems);
  final issueItems = result.items
      .where(
        (e) =>
            e.status == StickerScanStatus.notFound ||
            e.status == StickerScanStatus.ocrFailed ||
            e.status == StickerScanStatus.error ||
            e.status == StickerScanStatus.needsManualReview,
      )
      .toList();

  final uniqueIssueLines = _dedupeIssueLines(issueItems);
  final showBackSideTip = issueItems.isNotEmpty;

  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final colors = theme.colorScheme;
      final mediaSize = MediaQuery.sizeOf(ctx);
      final screenHeight = mediaSize.height;
      final screenWidth = mediaSize.width;
      final isTablet = screenWidth >= 700;
      final modalMaxWidth = isTablet ? 620.0 : screenWidth;
      final modalHeight = math.min(
        math.max(screenHeight * 0.68, 460.0),
        screenHeight - 16,
      );
      return SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: modalMaxWidth),
            child: Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SizedBox(
                height: modalHeight,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isTablet ? 24 : 18,
                    10,
                    isTablet ? 24 : 18,
                    14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 38,
                          height: 4,
                          decoration: BoxDecoration(
                            color: colors.outlineVariant,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    uniqueIssueLines.isEmpty
                                        ? Icons.task_alt_rounded
                                        : Icons.info_outline_rounded,
                                    color: uniqueIssueLines.isEmpty
                                        ? colors.primary
                                        : colors.error,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'scanResultDialogTitle'.tr(),
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _ResultChip(
                                    label: 'scanResultChipProcessed'.tr(),
                                    value: result.total,
                                    backgroundColor: colors.surfaceContainerHigh,
                                    foregroundColor: colors.onSurface,
                                  ),
                                  _ResultChip(
                                    label: 'scanResultChipAdded'.tr(),
                                    value: result.added,
                                    backgroundColor: colors.primaryContainer,
                                    foregroundColor: colors.onPrimaryContainer,
                                  ),
                                  _ResultChip(
                                    label: 'scanResultChipOwned'.tr(),
                                    value: result.alreadyOwned,
                                    backgroundColor: colors.secondaryContainer,
                                    foregroundColor: colors.onSecondaryContainer,
                                  ),
                                  _ResultChip(
                                    label: 'scanResultChipNotFound'.tr(),
                                    value: result.notFound,
                                    backgroundColor: colors.tertiaryContainer,
                                    foregroundColor: colors.onTertiaryContainer,
                                  ),
                                  _ResultChip(
                                    label: 'scanResultChipFailed'.tr(),
                                    value: result.failed,
                                    backgroundColor: colors.errorContainer,
                                    foregroundColor: colors.onErrorContainer,
                                  ),
                                  if (result.needsManualReview > 0)
                                    _ResultChip(
                                      label: 'scanResultChipReview'.tr(),
                                      value: result.needsManualReview,
                                      backgroundColor: colors.surfaceContainerHighest,
                                      foregroundColor: colors.onSurface,
                                    ),
                                ],
                              ),
                              if (successfulStickers.isNotEmpty) ...[
                                const SizedBox(height: 14),
                                Text(
                                  'Láminas agregadas',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...successfulStickers.map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2),
                                          child: Icon(
                                            Icons.check_circle_outline_rounded,
                                            size: 18,
                                            color: colors.primary,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            item.line,
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(height: 1.25),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                              if (uniqueIssueLines.isNotEmpty) ...[
                                const SizedBox(height: 14),
                                Text(
                                  'scanResultDialogIssuesHeader'.tr(),
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...uniqueIssueLines.map(
                                  (line) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2),
                                          child: Icon(
                                            Icons.error_outline_rounded,
                                            size: 18,
                                            color: colors.error,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            line,
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              height: 1.25,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                              if (showBackSideTip) ...[
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: colors.surfaceContainerHigh,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.tips_and_updates_outlined,
                                        size: 18,
                                        color: colors.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'scanResultBackSideTip'.tr(),
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: colors.onSurfaceVariant,
                                            height: 1.25,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text('scanResultDialogOk'.tr()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _ResultChip extends StatelessWidget {
  const _ResultChip({
    required this.label,
    required this.value,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final int value;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$value',
            style: textTheme.labelLarge?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: textTheme.labelMedium?.copyWith(color: foregroundColor),
          ),
        ],
      ),
    );
  }
}

/// Evita repetir el mismo texto varias veces cuando varias imágenes fallan por el mismo motivo.
List<String> _dedupeIssueLines(List<SingleStickerScanResult> issueItems) {
  final seen = <String>{};
  final out = <String>[];
  for (final e in issueItems) {
    final line = _issueLine(e);
    if (seen.add(line)) out.add(line);
  }
  return out;
}

String _issueLine(SingleStickerScanResult e) {
  switch (e.status) {
    case StickerScanStatus.notFound:
      if (e.message == 'scanResultSideUnknown') {
        return 'scanResultSideUnknown'.tr();
      }
      if (e.message == 'scanResultFrontNoMatch') {
        return 'scanResultFrontNoMatch'.tr();
      }
      if (e.message == 'scanResultBackNoMatch') {
        return 'scanResultBackNoMatch'.tr();
      }
      if (e.message == 'scanResultWeAreNoNumber') {
        return 'scanResultWeAreNoNumber'.tr();
      }
      return 'scanResultIssueNotFound'.tr(
        namedArgs: {'hint': e.detectedIdentifier ?? '—'},
      );
    case StickerScanStatus.ocrFailed:
      return 'scanResultIssueOcr'.tr();
    case StickerScanStatus.error:
      return 'scanResultIssueError'.tr(namedArgs: {'msg': e.message});
    case StickerScanStatus.needsManualReview:
      if (e.message == 'scanResultLowConfidence') {
        return 'scanResultIssueLowConfidence'.tr(
          namedArgs: {'hint': e.detectedIdentifier ?? '—'},
        );
      }
      if (e.message == 'scanResultSpecialReview') {
        return 'scanResultSpecialReview'.tr();
      }
      if (e.message == 'scanResultSpecialFrontReview') {
        return 'scanResultSpecialFrontReview'.tr();
      }
      return 'scanResultIssueNotFound'.tr(
        namedArgs: {'hint': e.detectedIdentifier ?? '—'},
      );
    case StickerScanStatus.added:
    case StickerScanStatus.alreadyExists:
      return e.message;
  }
}

class _SuccessfulStickerLine {
  const _SuccessfulStickerLine({required this.line});
  final String line;
}

List<_SuccessfulStickerLine> _dedupeSuccessfulStickers(
  List<SingleStickerScanResult> successfulItems,
) {
  final out = <_SuccessfulStickerLine>[];
  final seen = <String>{};

  for (final e in successfulItems) {
    final sticker = e.matchedSticker;
    if (sticker == null) continue;
    final line = _successfulStickerLine(sticker);
    final key = '${sticker.id}|$line';
    if (!seen.add(key)) continue;
    out.add(_SuccessfulStickerLine(line: line));
  }

  return out;
}

String _successfulStickerLine(StickerModel sticker) {
  final country = _teamDisplayName(sticker.teamId);
  switch (sticker.type) {
    case StickerType.badge:
      return 'Insignia - $country';
    case StickerType.team_photo:
      return 'Foto de equipo - $country';
    case StickerType.player:
      final name = (sticker.playerName ?? '').trim();
      if (name.isNotEmpty) return '$name - $country';
      return 'Jugador - $country';
    case StickerType.special:
      return 'Especial - ${sticker.displayCode}';
  }
}

String _teamDisplayName(String teamId) {
  for (final g in WorldCup2026Seed.groups) {
    for (final t in g.teams) {
      if (t.id == teamId) {
        return t.name.tr();
      }
    }
  }
  return teamId;
}
