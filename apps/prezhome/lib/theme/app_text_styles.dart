import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_theme.dart';

/// Escala tipográfica SEMÁNTICA de PrezHome sobre la fuente Nunito.
///
/// Estos estilos sustituyen los `TextStyle` inline repartidos por las
/// pantallas (tamaños sueltos 10.5 / 11 / 13 / 14 / 15 / 22 / 24 y
/// `Colors.grey[...]` crudos). Usan siempre colores de marca:
/// [AppColors.ink] para texto principal y [AppColors.inkMuted] para texto
/// secundario / de apoyo.
///
/// La jerarquía de pesos es REAL (no todo en negrita): los títulos pesan
/// más, el cuerpo es regular y las etiquetas apoyan con peso medio.
///
/// Uso: `Text('Hola', style: AppTextStyles.title)`.
class AppTextStyles {
  const AppTextStyles._();

  /// ~28 / bold — números y titulares grandes (cabeceras de pantalla).
  static TextStyle get display => GoogleFonts.nunito(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.ink,
    height: 1.15,
  );

  /// ~22 / bold — cabeceras de sección / AppBar.
  static TextStyle get headline => GoogleFonts.nunito(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    height: 1.2,
  );

  /// ~16 / semibold — títulos de tarjeta.
  static TextStyle get title => GoogleFonts.nunito(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    height: 1.25,
  );

  /// ~14 / semibold — variante pequeña de título (subtítulos de tarjeta).
  static TextStyle get titleSmall => GoogleFonts.nunito(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
    height: 1.3,
  );

  /// ~14 / regular — cuerpo de texto estándar.
  static TextStyle get body => GoogleFonts.nunito(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.ink,
    height: 1.4,
  );

  /// ~14 / semibold — cuerpo con énfasis (datos destacados en línea).
  static TextStyle get bodyStrong => GoogleFonts.nunito(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    height: 1.4,
  );

  /// ~12 / medium — etiquetas, chips y textos pequeños.
  static TextStyle get label => GoogleFonts.nunito(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
    height: 1.3,
  );

  /// ~12 / medium — etiqueta secundaria (texto de apoyo en gris de marca).
  static TextStyle get labelMuted => GoogleFonts.nunito(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.inkMuted,
    height: 1.3,
  );

  /// ~14 / regular — cuerpo secundario en gris de marca (descripciones).
  static TextStyle get bodyMuted => GoogleFonts.nunito(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.inkMuted,
    height: 1.4,
  );
}
