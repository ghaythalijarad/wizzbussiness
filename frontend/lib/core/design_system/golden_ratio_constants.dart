/// Golden Ratio Design Constants
///
/// This file contains all the mathematical constants and calculations
/// based on the golden ratio (φ = 1.618) for consistent design proportions.
///
/// The golden ratio creates naturally pleasing proportions and is used
/// throughout Material Design 3 for spacing, typography, and sizing.

class GoldenRatio {
  // Private constructor to prevent instantiation
  GoldenRatio._();

  /// The golden ratio constant (φ = 1.618033988749)
  static const double phi = 1.618033988749;

  /// Inverse of golden ratio (1/φ = 0.618033988749)
  static const double phiInverse = 0.618033988749;

  // Base unit for spacing (following Material Design 3)
  static const double baseUnit = 8.0;

  // ══════════════════════════════════════════════════════════════════════════
  // SPACING SCALE - Based on golden ratio progression
  // ══════════════════════════════════════════════════════════════════════════

  /// Extra small spacing: 4px
  static const double xs = baseUnit * 0.5;

  /// Small spacing: 8px (base unit)
  static const double sm = baseUnit;

  /// Medium spacing: ~13px (baseUnit * φ⁻¹)
  static const double md = baseUnit * phiInverse;

  /// Large spacing: ~21px (baseUnit * φ)
  static const double lg = baseUnit * phi;

  /// Extra large spacing: ~34px (baseUnit * φ²)
  static const double xl = baseUnit * (phi * phi);

  /// Extra extra large spacing: ~55px (baseUnit * φ³)
  static const double xxl = baseUnit * (phi * phi * phi);

  /// Extra extra extra large spacing: ~89px (baseUnit * φ⁴)
  static const double xxxl = baseUnit * (phi * phi * phi * phi);

  // Practical spacing values for common UI patterns
  /// Spacing 4px - Extra minimal spacing
  static const double spacing4 = 4.0;

  /// Spacing 8px - Minimal spacing
  static const double spacing8 = 8.0;

  /// Spacing 12px - Common for padding and margins
  static const double spacing12 = 12.0;

  /// Spacing 16px - Standard component padding
  static const double spacing16 = 16.0;

  /// Spacing 18px - Medium component spacing
  static const double spacing18 = 18.0;

  /// Spacing 20px - Larger component spacing
  static const double spacing20 = 20.0;

  /// Spacing 24px - Large component spacing
  static const double spacing24 = 24.0;

  // ══════════════════════════════════════════════════════════════════════════
  // TYPOGRAPHY SCALE - Following golden ratio progression
  // ══════════════════════════════════════════════════════════════════════════

  /// Caption text size: 12px (Material Design base)
  static const double captionSize = 12.0;

  /// Body small text size: ~19px (caption * φ)
  static const double bodySmallSize = captionSize * phi;

  /// Body text size: ~31px (bodySmall * φ)
  static const double bodySize = bodySmallSize * phi;

  /// Title text size: ~50px (body * φ)
  static const double titleSize = bodySize * phi;

  /// Headline text size: ~81px (title * φ)
  static const double headlineSize = titleSize * phi;

  // More practical typography scale for UI
  /// Small text: 12px
  static const double textXs = 12.0;

  /// Regular text: 14px
  static const double textSm = 14.0;

  /// Medium text: 16px
  static const double textMd = 16.0;

  /// Large text: 18px
  static const double textLg = 18.0;

  /// Extra large text: 20px
  static const double textXl = 20.0;

  /// Title text: 24px
  static const double textTitle = 24.0;

  /// Headline text: 32px
  static const double textHeadline = 32.0;

  // ══════════════════════════════════════════════════════════════════════════
  // BORDER RADIUS SCALE - Following golden ratio
  // ══════════════════════════════════════════════════════════════════════════

  /// Extra small radius: 4px
  static const double radiusXs = 4.0;

  /// Small radius: ~6px (radiusXs * φ)
  static const double radiusSm = radiusXs * phi;

  /// Medium radius: ~10px (radiusSm * φ)
  static const double radiusMd = radiusSm * phi;

  /// Large radius: ~16px (radiusMd * φ)
  static const double radiusLg = radiusMd * phi;

  /// Extra large radius: ~26px (radiusLg * φ)
  static const double radiusXl = radiusLg * phi;

  // Practical border radius values
  /// Button radius: 8px
  static const double buttonRadius = 8.0;

  /// Card radius: 12px
  static const double cardRadius = 12.0;

  /// Sheet radius: 16px
  static const double sheetRadius = 16.0;

  /// Modal radius: 20px
  static const double modalRadius = 20.0;

  // ══════════════════════════════════════════════════════════════════════════
  // ICON SIZES - Following golden ratio progression
  // ══════════════════════════════════════════════════════════════════════════

  /// Small icon: 16px
  static const double iconSm = 16.0;

  /// Medium icon: ~26px (iconSm * φ)
  static const double iconMd = iconSm * phi;

  /// Large icon: ~42px (iconMd * φ)
  static const double iconLg = iconMd * phi;

  /// Extra large icon: ~68px (iconLg * φ)
  static const double iconXl = iconLg * phi;

  // Standard Material Design icon sizes
  /// Tiny icon: 12px
  static const double iconXs = 12.0;

  /// Regular icon: 24px (Material Design standard)
  static const double iconRegular = 24.0;

  /// Large icon: 32px
  static const double iconLarge = 32.0;

  /// Extra large icon: 48px
  static const double iconExtraLarge = 48.0;

  // ══════════════════════════════════════════════════════════════════════════
  // COMPONENT DIMENSIONS - Common UI element sizes
  // ══════════════════════════════════════════════════════════════════════════

  /// Standard button height: 48px
  static const double buttonHeight = 48.0;

  /// Compact button height: 36px
  static const double buttonHeightCompact = 36.0;

  /// Large button height: 56px
  static const double buttonHeightLarge = 56.0;

  /// Text field height: 56px
  static const double textFieldHeight = 56.0;

  /// App bar height: 56px (Material Design standard)
  static const double appBarHeight = 56.0;

  /// Bottom navigation height: 80px
  static const double bottomNavHeight = 80.0;

  /// Navigation rail width: 80px
  static const double navRailWidth = 80.0;

  /// Drawer width: 304px (Material Design standard)
  static const double drawerWidth = 304.0;

  // ══════════════════════════════════════════════════════════════════════════
  // ELEVATION VALUES - Material Design 3 elevation scale
  // ══════════════════════════════════════════════════════════════════════════

  /// No elevation
  static const double elevation0 = 0.0;

  /// Minimal elevation: 1px
  static const double elevation1 = 1.0;

  /// Small elevation: 2px
  static const double elevation2 = 2.0;

  /// Medium elevation: 4px
  static const double elevation3 = 4.0;

  /// Large elevation: 8px
  static const double elevation4 = 8.0;

  /// Extra large elevation: 16px
  static const double elevation5 = 16.0;

  // ══════════════════════════════════════════════════════════════════════════
  // UTILITY FUNCTIONS
  // ══════════════════════════════════════════════════════════════════════════

  /// Calculate golden ratio for any given value
  /// Example: GoldenRatio.golden(100) = 161.8
  static double golden(double value) => value * phi;

  /// Calculate inverse golden ratio for any given value
  /// Example: GoldenRatio.goldenInverse(100) = 61.8
  static double goldenInverse(double value) => value * phiInverse;

  /// Calculate golden ratio squared
  /// Example: GoldenRatio.goldenSquared(10) = 26.18
  static double goldenSquared(double value) => value * phi * phi;

  /// Calculate golden ratio cubed
  /// Example: GoldenRatio.goldenCubed(10) = 42.36
  static double goldenCubed(double value) => value * phi * phi * phi;

  /// Check if two values follow golden ratio proportion
  /// Returns true if larger/smaller ≈ φ (within tolerance)
  static bool isGoldenRatio(double larger, double smaller,
      {double tolerance = 0.01}) {
    if (smaller == 0) return false;
    final ratio = larger / smaller;
    return (ratio - phi).abs() <= tolerance;
  }

  /// Generate a sequence of values following golden ratio
  /// Starting from baseValue, generates count number of values
  static List<double> generateSequence(double baseValue, int count,
      {bool ascending = true}) {
    final List<double> sequence = [baseValue];

    for (int i = 1; i < count; i++) {
      final nextValue =
          ascending ? sequence.last * phi : sequence.last * phiInverse;
      sequence.add(nextValue);
    }

    return sequence;
  }
}
