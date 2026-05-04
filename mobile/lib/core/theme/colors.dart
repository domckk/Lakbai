import 'package:flutter/material.dart';

abstract final class TrailColors {
  // ── Web palette (exact match to tailwind.config.ts) ──────────────────
  static const cream   = Color(0xFFFFFDF5);  // trail-cream      → backgrounds
  static const peach   = Color(0xFFFFD4A8);  // trail-peach      → chips, surfaces, hovers
  static const orange  = Color(0xFFFF8C3B);  // trail-orange     → primary actions
  static const orangeDark = Color(0xFFE07028); // trail-orange-dark → pressed / dark variant
  static const brown   = Color(0xFF3D2000);  // trail-brown      → headings, strong text
  static const brownMid = Color(0xFF5C2D0A); // trail-brown-mid  → body text

  // ── Semantic aliases (used throughout the app) ────────────────────────
  static const primary        = orange;
  static const primaryDark    = orangeDark;
  static const secondary      = Color(0xFF0E5E6F); // Heritage Teal (off-palette, kept for variety)
  static const accent         = orange;            // XP labels, highlights → orange like the web

  static const background     = cream;
  static const surface        = Color(0xFFFFFFFF); // white cards
  static const surfaceAlt     = Color(0xFFFFEDD5); // light peach tint  (cream ↔ peach midpoint)

  static const onBackground   = brown;
  static const onSurface      = brownMid;
  static const onSurfaceMuted = Color(0xFF9CA3AF); // gray-400

  static const border         = Color(0xFFE8D5C0); // warm peach-tinted border (not cold gray)

  // ── Status ────────────────────────────────────────────────────────────
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const error   = Color(0xFFEF4444);

  // ── Pre-computed opacity variants (avoids withOpacity() per build) ────
  static const peach50        = Color(0x80FFD4A8); // peach   @ 50 %
  static const peach60        = Color(0x99FFD4A8); // peach   @ 60 %
  static const peach30        = Color(0x4DFFD4A8); // peach   @ 30 %
  static const orangeShadow   = Color(0x66FF8C3B); // orange  @ 40 %
  static const orangeFaint    = Color(0x26FF8C3B); // orange  @ 15 %
  static const primaryFaint   = Color(0x1AFF8C3B); // primary @ 10 %
  static const primaryLight   = Color(0x1EFF8C3B); // primary @ 12 %
  static const primaryMedium  = Color(0x4DFF8C3B); // primary @ 30 %
  static const brownShadow    = Color(0x4D3D2000); // brown   @ 30 %
  static const shadowSm       = Color(0x0D000000); // black   @  5 %
  static const shadowXs       = Color(0x08000000); // black   @  3 %
}
