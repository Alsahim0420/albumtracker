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
  final addedItems = successfulItems
      .where((e) => e.status == StickerScanStatus.added)
      .toList();
  final ownedItems = successfulItems
      .where((e) => e.status == StickerScanStatus.alreadyExists)
      .toList();
  final addedGroupedLines = _groupedScanSummaryLines(addedItems);
  final ownedGroupedLines = _groupedScanSummaryLines(ownedItems);
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
                                    value: result.processedStickerCount,
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
                              if (addedGroupedLines.isNotEmpty) ...[
                                const SizedBox(height: 14),
                                Text(
                                  'scanResultSectionAddedHeader'.tr(),
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                ...addedGroupedLines.map(
                                  (line) => Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Text(
                                      line,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        height: 1.25,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              if (ownedGroupedLines.isNotEmpty) ...[
                                const SizedBox(height: 14),
                                Text(
                                  'scanResultSectionOwnedHeader'.tr(),
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                ...ownedGroupedLines.map(
                                  (line) => Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Text(
                                      line,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        height: 1.25,
                                        color: colors.onSurfaceVariant,
                                      ),
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

/// Resumen agrupado por lámina (orden de primera aparición en el lote).
List<String> _groupedScanSummaryLines(List<SingleStickerScanResult> successfulItems) {
  final order = <String>[];
  final counts = <String, int>{};
  final idToSticker = <String, StickerModel>{};
  for (final e in successfulItems) {
    final s = e.matchedSticker;
    if (s == null) continue;
    counts[s.id] = (counts[s.id] ?? 0) + 1;
    idToSticker[s.id] = s;
    if (!order.contains(s.id)) order.add(s.id);
  }
  return order.map((id) {
    final sticker = idToSticker[id]!;
    final n = counts[id]!;
    final label = _successfulStickerLine(sticker);
    if (n == 1) {
      return 'scanResultScanSummaryLineOne'.tr(namedArgs: {'label': label});
    }
    return 'scanResultScanSummaryLineMany'.tr(
      namedArgs: {'label': label, 'count': '$n'},
    );
  }).toList();
}

String _successfulStickerLine(StickerModel sticker) {
  final stickerCode = sticker.code;
  final country = _teamDisplayName(sticker.teamId);
  switch (sticker.type) {
    case StickerType.badge:
      return '$stickerCode - Insignia - $country';
    case StickerType.team_photo:
      return '$stickerCode - Foto de equipo - $country';
    case StickerType.player:
      final name = (sticker.playerName ?? '').trim();
      if (name.isNotEmpty) return '$stickerCode - $name - $country';
      return '$stickerCode - Jugador - $country';
    case StickerType.special:
      return '$stickerCode - Especial - $country';
  }
}

String _teamDisplayName(String teamId) {
  if (teamId == WorldCup2026Seed.specialTeamCode) {
    return 'FIFA World Cup 2026';
  }
  for (final g in WorldCup2026Seed.groups) {
    for (final t in g.teams) {
      if (t.id == teamId) {
        return t.name.tr();
      }
    }
  }
  return teamId;
}
