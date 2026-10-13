import 'package:flutter/material.dart';

/// ===============================================================
/// ABAKASCAN DESIGN SYSTEM
/// ===============================================================
///
/// Shared design tokens for the ABAKASCAN Flutter Web and Mobile
/// application.
///
/// Visual direction:
/// Agriculture + Research + Computer Vision + Modern Technology
///
/// The redesign uses:
/// - Deep forest green for navigation and strong emphasis
/// - Fresh green for actions and active states
/// - Warm cream for page backgrounds
/// - Soft sage for secondary surfaces
/// - Fiber-inspired beige/gold for agricultural accents
/// - Clean typography and generous spacing
///
/// ===============================================================

class AppColors {
  AppColors._();

  // ---------------------------------------------------------------
  // BRAND COLORS
  // ---------------------------------------------------------------

  /// Fresh ABAKASCAN green.
  ///
  /// Used for:
  /// - primary actions
  /// - active states
  /// - important icons
  /// - progress indicators
  static const Color primary = Color(0xFF2E7D4B);

  /// Deep forest green.
  ///
  /// Used for:
  /// - desktop sidebars
  /// - major navigation surfaces
  /// - dark hero areas
  /// - strong emphasis
  static const Color primaryDark = Color(0xFF0F3D2E);

  /// Softer natural green.
  ///
  /// Used for:
  /// - secondary accents
  /// - supporting icons
  /// - subtle decorative elements
  static const Color secondary = Color(0xFF79A879);

  /// Light green tint for selected states and soft surfaces.
  static const Color primarySoft = Color(0xFFE5F1E6);

  /// Sage surface inspired by natural plant tones.
  static const Color sage = Color(0xFFD9E4D6);

  // ---------------------------------------------------------------
  // BACKGROUND AND SURFACES
  // ---------------------------------------------------------------

  /// Main application background.
  static const Color background = Color(0xFFF8F6ED);

  /// Main cards, forms, and panels.
  static const Color surface = Color(0xFFFFFDF8);

  /// Secondary section background.
  static const Color surfaceMuted = Color(0xFFF0F2EA);

  /// Stronger sage-tinted supporting surface.
  static const Color surfaceSage = Color(0xFFE4ECE1);

  /// Fiber-inspired beige / muted gold.
  ///
  /// Used sparingly for:
  /// - agricultural accents
  /// - badges
  /// - decorative lines
  /// - special highlights
  static const Color fiberBeige = Color(0xFFD6B67A);

  /// Softer version of fiber beige.
  static const Color fiberBeigeSoft = Color(0xFFF0E5CB);

  // ---------------------------------------------------------------
  // TEXT
  // ---------------------------------------------------------------

  /// Main charcoal-green text.
  static const Color textPrimary = Color(0xFF17251C);

  /// Secondary text.
  static const Color textSecondary = Color(0xFF667068);

  /// Text over dark green surfaces.
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  /// Softer text over dark surfaces.
  static const Color textOnPrimaryMuted = Color(0xFFDCE7DE);

  // ---------------------------------------------------------------
  // BORDERS
  // ---------------------------------------------------------------

  static const Color border = Color(0xFFDDE2DA);

  static const Color borderStrong = Color(0xFFB8C3BA);

  // ---------------------------------------------------------------
  // FEEDBACK COLORS
  // ---------------------------------------------------------------

  static const Color success = Color(0xFF2E7D4B);

  static const Color warning = Color(0xFFB17A2D);

  static const Color error = Color(0xFFA8453D);

  static const Color info = Color(0xFF496F7A);

  // ---------------------------------------------------------------
  // DISABLED STATES
  // ---------------------------------------------------------------

  static const Color disabled = Color(0xFFB4BAB5);

  static const Color disabledBackground = Color(0xFFE5E7E2);
}

/// ===============================================================
/// SPACING
/// ===============================================================

class AppSpacing {
  AppSpacing._();

  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;
}

/// ===============================================================
/// BORDER RADIUS
/// ===============================================================
///
/// Slightly softer than the old design while still avoiding
/// excessively rounded "bubble" interfaces.

class AppRadius {
  AppRadius._();

  static const double small = 8;
  static const double medium = 14;
  static const double large = 22;

  static const BorderRadius smallRadius = BorderRadius.all(
    Radius.circular(small),
  );

  static const BorderRadius mediumRadius = BorderRadius.all(
    Radius.circular(medium),
  );

  static const BorderRadius largeRadius = BorderRadius.all(
    Radius.circular(large),
  );
}

/// ===============================================================
/// RESPONSIVE BREAKPOINTS
/// ===============================================================
///
/// Mobile:
///   < 600
///
/// Tablet:
///   600 - 1023
///
/// Desktop:
///   >= 1024
///
/// Individual screens may use additional local layout thresholds
/// when their content requires it.

class AppBreakpoints {
  AppBreakpoints._();

  static const double mobile = 600;

  static const double desktop = 1024;

  static bool isMobile(double width) {
    return width < mobile;
  }

  static bool isTablet(double width) {
    return width >= mobile && width < desktop;
  }

  static bool isDesktop(double width) {
    return width >= desktop;
  }
}

/// ===============================================================
/// TYPOGRAPHY
/// ===============================================================
///
/// Uses Flutter's default sans-serif font so no external font
/// dependency is required.
///
/// Screen-specific widgets may reduce these sizes on mobile.

class AppTypography {
  AppTypography._();

  /// Large editorial hero heading.
  static const TextStyle displayLarge = TextStyle(
    fontSize: 58,
    fontWeight: FontWeight.w700,
    height: 1.03,
    letterSpacing: -1.8,
    color: AppColors.textPrimary,
  );

  /// Secondary display heading.
  static const TextStyle displayMedium = TextStyle(
    fontSize: 44,
    fontWeight: FontWeight.w700,
    height: 1.08,
    letterSpacing: -1.2,
    color: AppColors.textPrimary,
  );

  /// Main page title.
  static const TextStyle pageTitle = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 1.12,
    letterSpacing: -0.7,
    color: AppColors.textPrimary,
  );

  /// Section heading.
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 25,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.25,
    color: AppColors.textPrimary,
  );

  /// Card and component title.
  static const TextStyle cardTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.28,
    color: AppColors.textPrimary,
  );

  /// Primary body copy.
  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.55,
    color: AppColors.textPrimary,
  );

  /// Supporting body copy.
  static const TextStyle bodySecondary = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textSecondary,
  );

  /// Small helper text.
  static const TextStyle caption = TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  /// Button labels.
  static const TextStyle button = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  /// Small labels, badges, and eyebrow headings.
  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.7,
    color: AppColors.textSecondary,
  );
}

/// ===============================================================
/// APPLICATION THEME
/// ===============================================================

class AppTheme {
  AppTheme._();

  static final ColorScheme _colorScheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppColors.primary,
        onPrimary: AppColors.textOnPrimary,
        primaryContainer: AppColors.primarySoft,
        onPrimaryContainer: AppColors.primaryDark,
        secondary: AppColors.secondary,
        onSecondary: AppColors.primaryDark,
        secondaryContainer: AppColors.sage,
        onSecondaryContainer: AppColors.primaryDark,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
        onError: Colors.white,
      );

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,

    colorScheme: _colorScheme,

    scaffoldBackgroundColor: AppColors.background,

    // -------------------------------------------------------------
    // TYPOGRAPHY
    // -------------------------------------------------------------
    textTheme: const TextTheme(
      displayLarge: AppTypography.displayLarge,
      displayMedium: AppTypography.displayMedium,
      headlineLarge: AppTypography.pageTitle,
      headlineMedium: AppTypography.sectionTitle,
      titleLarge: AppTypography.cardTitle,
      bodyLarge: AppTypography.body,
      bodyMedium: AppTypography.body,
      bodySmall: AppTypography.bodySecondary,
      labelLarge: AppTypography.button,
      labelMedium: AppTypography.label,
      labelSmall: AppTypography.caption,
    ),

    // -------------------------------------------------------------
    // APP BAR
    // -------------------------------------------------------------
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
      titleSpacing: AppSpacing.md,
    ),

    // -------------------------------------------------------------
    // CARDS
    // -------------------------------------------------------------
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.mediumRadius,
        side: const BorderSide(color: AppColors.border, width: 1),
      ),
    ),

    // -------------------------------------------------------------
    // INPUT FIELDS
    // -------------------------------------------------------------
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: AppColors.surface,

      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 17,
      ),

      labelStyle: AppTypography.bodySecondary.copyWith(
        color: AppColors.textSecondary,
      ),

      floatingLabelStyle: AppTypography.bodySecondary.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.w600,
      ),

      hintStyle: AppTypography.bodySecondary.copyWith(
        color: AppColors.textSecondary.withValues(alpha: 0.78),
      ),

      helperStyle: AppTypography.caption,

      errorStyle: AppTypography.caption.copyWith(color: AppColors.error),

      prefixIconColor: AppColors.textSecondary,

      suffixIconColor: AppColors.textSecondary,

      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.mediumRadius,
        borderSide: const BorderSide(color: AppColors.border, width: 1),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.mediumRadius,
        borderSide: const BorderSide(color: AppColors.primary, width: 1.7),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.mediumRadius,
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppRadius.mediumRadius,
        borderSide: const BorderSide(color: AppColors.error, width: 1.7),
      ),

      disabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.mediumRadius,
        borderSide: const BorderSide(color: AppColors.disabled, width: 1),
      ),
    ),

    // -------------------------------------------------------------
    // PRIMARY BUTTONS
    // -------------------------------------------------------------
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        foregroundColor: AppColors.textOnPrimary,
        backgroundColor: AppColors.primary,

        disabledForegroundColor: AppColors.textSecondary,

        disabledBackgroundColor: AppColors.disabledBackground,

        elevation: 0,

        minimumSize: const Size(48, 52),

        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),

        textStyle: AppTypography.button,

        shape: RoundedRectangleBorder(borderRadius: AppRadius.mediumRadius),
      ),
    ),

    // -------------------------------------------------------------
    // SECONDARY BUTTONS
    // -------------------------------------------------------------
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryDark,

        elevation: 0,

        minimumSize: const Size(48, 52),

        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),

        textStyle: AppTypography.button,

        side: const BorderSide(color: AppColors.borderStrong, width: 1),

        shape: RoundedRectangleBorder(borderRadius: AppRadius.mediumRadius),
      ),
    ),

    // -------------------------------------------------------------
    // TEXT BUTTONS
    // -------------------------------------------------------------
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,

        textStyle: AppTypography.button,

        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),

        shape: RoundedRectangleBorder(borderRadius: AppRadius.smallRadius),
      ),
    ),

    // -------------------------------------------------------------
    // ICON BUTTONS
    // -------------------------------------------------------------
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: AppColors.primaryDark),
    ),

    // -------------------------------------------------------------
    // CHECKBOXES
    // -------------------------------------------------------------
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      side: const BorderSide(color: AppColors.borderStrong),
    ),

    // -------------------------------------------------------------
    // RADIO BUTTONS
    // -------------------------------------------------------------
    radioTheme: const RadioThemeData(visualDensity: VisualDensity.standard),

    // -------------------------------------------------------------
    // SWITCHES
    // -------------------------------------------------------------
    switchTheme: const SwitchThemeData(
      materialTapTargetSize: MaterialTapTargetSize.padded,
    ),

    // -------------------------------------------------------------
    // PROGRESS INDICATORS
    // -------------------------------------------------------------
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
      linearTrackColor: AppColors.sage,
      circularTrackColor: AppColors.sage,
    ),

    // -------------------------------------------------------------
    // DIVIDERS
    // -------------------------------------------------------------
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: 1,
    ),

    // -------------------------------------------------------------
    // DIALOGS
    // -------------------------------------------------------------
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.largeRadius),
      titleTextStyle: AppTypography.cardTitle.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      contentTextStyle: AppTypography.body,
    ),

    // -------------------------------------------------------------
    // BOTTOM SHEETS
    // -------------------------------------------------------------
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
    ),

    // -------------------------------------------------------------
    // NAVIGATION RAIL
    // -------------------------------------------------------------
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: AppColors.surface,

      indicatorColor: AppColors.primarySoft,

      selectedIconTheme: IconThemeData(color: AppColors.primary),

      unselectedIconTheme: IconThemeData(color: AppColors.textSecondary),

      selectedLabelTextStyle: TextStyle(
        color: AppColors.primaryDark,
        fontWeight: FontWeight.w700,
      ),

      unselectedLabelTextStyle: TextStyle(color: AppColors.textSecondary),
    ),

    // -------------------------------------------------------------
    // MOBILE BOTTOM NAVIGATION
    // -------------------------------------------------------------
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: AppColors.surface,

      indicatorColor: AppColors.primarySoft,

      elevation: 0,

      height: 70,

      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),

    // -------------------------------------------------------------
    // DRAWER
    // -------------------------------------------------------------
    drawerTheme: const DrawerThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
    ),

    // -------------------------------------------------------------
    // TOOLTIP
    // -------------------------------------------------------------
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: AppRadius.smallRadius,
      ),
      textStyle: AppTypography.caption.copyWith(color: AppColors.textOnPrimary),
    ),

    // -------------------------------------------------------------
    // SNACKBARS
    // -------------------------------------------------------------
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.primaryDark,
      contentTextStyle: AppTypography.bodySecondary.copyWith(
        color: AppColors.textOnPrimary,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.mediumRadius),
    ),

    // -------------------------------------------------------------
    // POPUP MENUS
    // -------------------------------------------------------------
    popupMenuTheme: PopupMenuThemeData(
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.mediumRadius),
    ),

    // -------------------------------------------------------------
    // GENERAL
    // -------------------------------------------------------------
    dividerColor: AppColors.border,

    disabledColor: AppColors.disabled,

    focusColor: AppColors.primary,

    hoverColor: AppColors.primary.withValues(alpha: 0.06),

    highlightColor: AppColors.primary.withValues(alpha: 0.05),

    splashColor: AppColors.primary.withValues(alpha: 0.08),

    iconTheme: const IconThemeData(color: AppColors.textPrimary),
  );
}
