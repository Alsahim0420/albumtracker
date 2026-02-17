import 'package:flutter/material.dart';

/// Paleta global de colores de la aplicación.
/// Centraliza todos los colores para mantener consistencia y facilitar cambios de tema.
abstract final class AppColors {
  AppColors._();

  // --- Splash & fondo ---
  /// Fondo principal (azul muy oscuro / casi negro).
  static const Color splashBackground = Color(0xFF1A2234);

  // --- Primario / Acento ---
  /// Azul brillante: icono de app, barra de progreso, acentos.
  static const Color primary = Color(0xFF3B82F6);

  // --- Texto ---
  /// Texto principal (títulos, contenido destacado).
  static const Color textPrimary = Color(0xFFFFFFFF);

  /// Texto secundario (pie de página, subtítulos).
  static const Color textSecondary = Color(0xFFB0B0B0);

  // --- UI ---
  /// Fondo de la barra de progreso (track).
  static const Color progressTrack = Color(0xFF2D3A4F);

  /// Superficies/cards y fondos de campos.
  static const Color surface = Color(0xFF243044);

  /// Fondo de campos de texto (inputs).
  static const Color inputBackground = Color(0xFF2D3A4F);

  /// Borde sutil de campos y separadores.
  static const Color inputBorder = Color(0xFF3D4A5F);

  /// Placeholder en campos de texto.
  static const Color placeholder = Color(0xFF8899AA);

  /// Iconos dentro de campos (sobre, ojo).
  static const Color inputIcon = Color(0xFFB0B0B0);

  /// Texto en botones sociales (Google/Apple) en tema oscuro.
  static const Color socialButtonText = Color(0xFFFFFFFF);

  // --- Home / Album ---
  /// Fondo de cards (progress card, segmentos no seleccionados).
  static const Color cardBackground = Color(0xFF243044);

  /// Verde: swaps disponibles, ítems con duplicados.
  static const Color swapGreen = Color(0xFF22C55E);

  /// Verde más oscuro para badge +1, +3.
  static const Color swapGreenDark = Color(0xFF16A34A);

  /// Fondo de ítem faltante (missing).
  static const Color itemMissing = Color(0xFF2D3A4F);

  /// Fondo de barra inferior.
  static const Color navBarBackground = Color(0xFF1A2234);

  /// Ítem de nav no seleccionado.
  static const Color navUnselected = Color(0xFF8899AA);
}
