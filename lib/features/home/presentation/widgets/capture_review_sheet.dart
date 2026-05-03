import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Tras cada foto en sesión multi-cámara: revisar, repetir, añadir otra o finalizar.
enum CaptureReviewDecision {
  /// Descartar esta toma y volver a abrir la cámara.
  retake,

  /// Aceptar foto y abrir de nuevo la cámara para otra.
  saveAndContinue,

  /// Aceptar foto y terminar la sesión (procesar después).
  saveAndFinish,
}

class CaptureReviewSheet extends StatelessWidget {
  const CaptureReviewSheet({
    super.key,
    required this.imagePath,
    required this.photoNumber,
  });

  final String imagePath;
  final int photoNumber;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'scanCaptureReviewTitle'.tr(),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'scanCaptureReviewSubtitle'.tr(namedArgs: {'n': '$photoNumber'}),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 3 / 4,
                  child: Image.file(
                    File(imagePath),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () =>
                    Navigator.of(context).pop(CaptureReviewDecision.retake),
                child: Text('scanCaptureReviewRetake'.tr()),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => Navigator.of(context)
                    .pop(CaptureReviewDecision.saveAndContinue),
                child: Text('scanCaptureReviewSaveMore'.tr()),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.secondaryContainer,
                  foregroundColor: colors.onSecondaryContainer,
                ),
                onPressed: () => Navigator.of(context)
                    .pop(CaptureReviewDecision.saveAndFinish),
                child: Text('scanCaptureReviewSaveFinish'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
