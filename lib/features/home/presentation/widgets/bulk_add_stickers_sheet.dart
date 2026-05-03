import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:albumtracker/core/data/world_cup_2026_seed.dart';
import 'package:albumtracker/core/theme/app_colors.dart';

/// Bottom sheet para agregar múltiples laminas por números (comas o espacios).
class BulkAddStickersSheet extends StatefulWidget {
  const BulkAddStickersSheet({
    super.key,
    this.onConfirm,
  });

  /// Lista de stickerIds únicos resueltos (acepta `POR 11`, `POR-11`, `41`, etc.).
  final void Function(List<String> stickerIds)? onConfirm;

  @override
  State<BulkAddStickersSheet> createState() => _BulkAddStickersSheetState();
}

class _BulkAddStickersSheetState extends State<BulkAddStickersSheet> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<String> _parsedStickerIds = [];
  static final RegExp _codeRegex = RegExp(r'\b([A-Z]{3})\s*[- ]?\s*(\d{1,2})\b');
  static final RegExp _numberRegex = RegExp(r'\b\d{1,4}\b');

  @override
  void initState() {
    super.initState();
    _controller.addListener(_parseInput);
  }

  @override
  void dispose() {
    _controller.removeListener(_parseInput);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _parseInput() {
    final text = _controller.text.toUpperCase();
    final ids = <String>{};

    for (final m in _codeRegex.allMatches(text)) {
      final team = m.group(1);
      final nRaw = m.group(2);
      if (team == null || nRaw == null) continue;
      final n = int.tryParse(nRaw);
      if (n == null || n < 1 || n > 20) continue;
      final sticker = WorldCup2026Seed.getStickerByFlexibleIdentifier('$team $n');
      if (sticker != null) ids.add(sticker.id);
    }

    for (final m in _numberRegex.allMatches(text)) {
      final token = m.group(0);
      if (token == null) continue;
      final sticker = WorldCup2026Seed.getStickerByFlexibleIdentifier(token);
      if (sticker != null) ids.add(sticker.id);
    }
    final sorted = ids.toList()..sort();
    if (listEquals(sorted, _parsedStickerIds)) return;
    setState(() => _parsedStickerIds = sorted);
  }

  void _insertShortcut(String char) {
    final text = _controller.text;
    var selection = _controller.selection;
    // Sin foco o selección inválida, `start`/`end` pueden ser -1 → RangeError en replaceRange.
    if (!selection.isValid) {
      selection = TextSelection.collapsed(offset: text.length);
    }
    var start = selection.start.clamp(0, text.length);
    var end = selection.end.clamp(0, text.length);
    if (start > end) {
      final t = start;
      start = end;
      end = t;
    }
    final newText = text.replaceRange(start, end, char);
    final newOffset = (start + char.length).clamp(0, newText.length);
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newOffset),
    );
  }

  void _confirm() {
    widget.onConfirm?.call(List.from(_parsedStickerIds));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'bulkAddTitle'.tr(),
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 22),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'bulkAddSubtitle'.tr(),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: colors.onSurface, size: 24),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 20, color: colors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'bulkAddInfoText'.tr(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                              height: 1.35,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    maxLines: 5,
                    minLines: 4,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.onSurface),
                    decoration: InputDecoration(
                      hintText: 'bulkAddPlaceholder'.tr(),
                      hintStyle: const TextStyle(color: AppColors.placeholder),
                      filled: true,
                      fillColor: colors.surfaceContainerHighest,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.outlineVariant),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colors.primary, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.fromLTRB(14, 14, 14, 32),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 12, bottom: 8),
                    child: Text(
                      '${_parsedStickerIds.length} ${'bulkAddStickersFound'.tr()}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'bulkAddExampleFormat'.tr(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _ExampleChip(label: 'bulkAddExample1'.tr()),
                  const SizedBox(width: 10),
                  _ExampleChip(label: 'bulkAddExample2'.tr()),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _ShortcutButton(
                    label: ',',
                    onTap: () => _insertShortcut(', '),
                  ),
                  const SizedBox(width: 10),
                  _ShortcutButton(
                    label: '-',
                    onTap: () => _insertShortcut('-'),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'bulkAddShortcuts'.tr(),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.inputBorder),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('bulkAddCancel'.tr()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _parsedStickerIds.isEmpty ? null : _confirm,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              'bulkAddConfirm'.tr(),
                              maxLines: 2,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.check, size: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          ),
        ),
      ),
    );
  }
}

class _ExampleChip extends StatelessWidget {
  const _ExampleChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontFamily: 'monospace',
            ),
      ),
    );
  }
}

class _ShortcutButton extends StatelessWidget {
  const _ShortcutButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.inputBorder),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
        ),
      ),
    );
  }
}
