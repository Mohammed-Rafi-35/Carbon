import "package:flutter/material.dart";

class MaterialTheme {
  final TextTheme textTheme;

  const MaterialTheme(this.textTheme);

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff5e6045),
      surfaceTint: Color(0xff5e6045),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xfffeffdb),
      onPrimaryContainer: Color(0xff747659),
      secondary: Color(0xff765a00),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xffffc60b),
      onSecondaryContainer: Color(0xff6e5400),
      tertiary: Color(0xff914d00),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xffff8b00),
      onTertiaryContainer: Color(0xff613200),
      error: Color(0xffba1a1a),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffffdad6),
      onErrorContainer: Color(0xff93000a),
      surface: Color(0xfffcf8f8),
      onSurface: Color(0xff1c1b1b),
      onSurfaceVariant: Color(0xff444748),
      outline: Color(0xff747878),
      outlineVariant: Color(0xffc4c7c7),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff313030),
      inversePrimary: Color(0xffc7c9a7),
      primaryFixed: Color(0xffe4e5c2),
      onPrimaryFixed: Color(0xff1b1d07),
      primaryFixedDim: Color(0xffc7c9a7),
      onPrimaryFixedVariant: Color(0xff46492f),
      secondaryFixed: Color(0xffffdf96),
      onSecondaryFixed: Color(0xff251a00),
      secondaryFixedDim: Color(0xfff6bf00),
      onSecondaryFixedVariant: Color(0xff5a4400),
      tertiaryFixed: Color(0xffffdcc3),
      onTertiaryFixed: Color(0xff2f1500),
      tertiaryFixedDim: Color(0xffffb77e),
      onTertiaryFixedVariant: Color(0xff6e3900),
      surfaceDim: Color(0xffddd9d8),
      surfaceBright: Color(0xfffcf8f8),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff7f3f2),
      surfaceContainer: Color(0xfff1edec),
      surfaceContainerHigh: Color(0xffebe7e7),
      surfaceContainerHighest: Color(0xffe5e2e1),
    );
  }

  ThemeData light() {
    return theme(lightScheme());
  }

  static ColorScheme lightMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff363820),
      surfaceTint: Color(0xff5e6045),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff6d6f53),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff453400),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff886800),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff562b00),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xffa65900),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff740006),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffcf2c27),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfffcf8f8),
      onSurface: Color(0xff111111),
      onSurfaceVariant: Color(0xff333737),
      outline: Color(0xff4f5354),
      outlineVariant: Color(0xff6a6e6e),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff313030),
      inversePrimary: Color(0xffc7c9a7),
      primaryFixed: Color(0xff6d6f53),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff55573c),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff886800),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff6b5100),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xffa65900),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff834500),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffc9c6c5),
      surfaceBright: Color(0xfffcf8f8),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff7f3f2),
      surfaceContainer: Color(0xffebe7e7),
      surfaceContainerHigh: Color(0xffe0dcdb),
      surfaceContainerHighest: Color(0xffd4d1d0),
    );
  }

  ThemeData lightMediumContrast() {
    return theme(lightMediumContrastScheme());
  }

  static ColorScheme lightHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff2c2e16),
      surfaceTint: Color(0xff5e6045),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff494b31),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff392a00),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff5d4600),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff472300),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff723b00),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff600004),
      onError: Color(0xffffffff),
      errorContainer: Color(0xff98000a),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfffcf8f8),
      onSurface: Color(0xff000000),
      onSurfaceVariant: Color(0xff000000),
      outline: Color(0xff292d2d),
      outlineVariant: Color(0xff464a4a),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff313030),
      inversePrimary: Color(0xffc7c9a7),
      primaryFixed: Color(0xff494b31),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff32341c),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff5d4600),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff413000),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff723b00),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff512800),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffbbb8b7),
      surfaceBright: Color(0xfffcf8f8),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff4f0ef),
      surfaceContainer: Color(0xffe5e2e1),
      surfaceContainerHigh: Color(0xffd7d4d3),
      surfaceContainerHighest: Color(0xffc9c6c5),
    );
  }

  ThemeData lightHighContrast() {
    return theme(lightHighContrastScheme());
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffffffff),
      surfaceTint: Color(0xffc7c9a7),
      onPrimary: Color(0xff30321a),
      primaryContainer: Color(0xffe4e5c2),
      onPrimaryContainer: Color(0xff64664b),
      secondary: Color(0xffffe8b7),
      onSecondary: Color(0xff3e2e00),
      secondaryContainer: Color(0xffffc60b),
      onSecondaryContainer: Color(0xff6e5400),
      tertiary: Color(0xffffb77e),
      onTertiary: Color(0xff4d2600),
      tertiaryContainer: Color(0xffff8b00),
      onTertiaryContainer: Color(0xff613200),
      error: Color(0xffffb4ab),
      onError: Color(0xff690005),
      errorContainer: Color(0xff93000a),
      onErrorContainer: Color(0xffffdad6),
      surface: Color(0xff141313),
      onSurface: Color(0xffe5e2e1),
      onSurfaceVariant: Color(0xffc4c7c7),
      outline: Color(0xff8e9192),
      outlineVariant: Color(0xff444748),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe5e2e1),
      inversePrimary: Color(0xff5e6045),
      primaryFixed: Color(0xffe4e5c2),
      onPrimaryFixed: Color(0xff1b1d07),
      primaryFixedDim: Color(0xffc7c9a7),
      onPrimaryFixedVariant: Color(0xff46492f),
      secondaryFixed: Color(0xffffdf96),
      onSecondaryFixed: Color(0xff251a00),
      secondaryFixedDim: Color(0xfff6bf00),
      onSecondaryFixedVariant: Color(0xff5a4400),
      tertiaryFixed: Color(0xffffdcc3),
      onTertiaryFixed: Color(0xff2f1500),
      tertiaryFixedDim: Color(0xffffb77e),
      onTertiaryFixedVariant: Color(0xff6e3900),
      surfaceDim: Color(0xff141313),
      surfaceBright: Color(0xff3a3939),
      surfaceContainerLowest: Color(0xff0e0e0e),
      surfaceContainerLow: Color(0xff1c1b1b),
      surfaceContainer: Color(0xff201f1f),
      surfaceContainerHigh: Color(0xff2b2a2a),
      surfaceContainerHighest: Color(0xff353434),
    );
  }

  ThemeData dark() {
    return theme(darkScheme());
  }

  static ColorScheme darkMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffffffff),
      surfaceTint: Color(0xffc7c9a7),
      onPrimary: Color(0xff30321a),
      primaryContainer: Color(0xffe4e5c2),
      onPrimaryContainer: Color(0xff484a30),
      secondary: Color(0xffffe8b7),
      onSecondary: Color(0xff3d2d00),
      secondaryContainer: Color(0xffffc60b),
      onSecondaryContainer: Color(0xff4c3900),
      tertiary: Color(0xffffd4b5),
      onTertiary: Color(0xff3e1d00),
      tertiaryContainer: Color(0xffff8b00),
      onTertiaryContainer: Color(0xff331700),
      error: Color(0xffffd2cc),
      onError: Color(0xff540003),
      errorContainer: Color(0xffff5449),
      onErrorContainer: Color(0xff000000),
      surface: Color(0xff141313),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffdadddd),
      outline: Color(0xffafb2b3),
      outlineVariant: Color(0xff8e9191),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe5e2e1),
      inversePrimary: Color(0xff484a30),
      primaryFixed: Color(0xffe4e5c2),
      onPrimaryFixed: Color(0xff101202),
      primaryFixedDim: Color(0xffc7c9a7),
      onPrimaryFixedVariant: Color(0xff363820),
      secondaryFixed: Color(0xffffdf96),
      onSecondaryFixed: Color(0xff181000),
      secondaryFixedDim: Color(0xfff6bf00),
      onSecondaryFixedVariant: Color(0xff453400),
      tertiaryFixed: Color(0xffffdcc3),
      onTertiaryFixed: Color(0xff200c00),
      tertiaryFixedDim: Color(0xffffb77e),
      onTertiaryFixedVariant: Color(0xff562b00),
      surfaceDim: Color(0xff141313),
      surfaceBright: Color(0xff454444),
      surfaceContainerLowest: Color(0xff070707),
      surfaceContainerLow: Color(0xff1e1d1d),
      surfaceContainer: Color(0xff282827),
      surfaceContainerHigh: Color(0xff333232),
      surfaceContainerHighest: Color(0xff3e3d3d),
    );
  }

  ThemeData darkMediumContrast() {
    return theme(darkMediumContrastScheme());
  }

  static ColorScheme darkHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffffffff),
      surfaceTint: Color(0xffc7c9a7),
      onPrimary: Color(0xff000000),
      primaryContainer: Color(0xffe4e5c2),
      onPrimaryContainer: Color(0xff292c15),
      secondary: Color(0xffffeece),
      onSecondary: Color(0xff000000),
      secondaryContainer: Color(0xffffc60b),
      onSecondaryContainer: Color(0xff231800),
      tertiary: Color(0xffffede1),
      onTertiary: Color(0xff000000),
      tertiaryContainer: Color(0xffffb273),
      onTertiaryContainer: Color(0xff170700),
      error: Color(0xffffece9),
      onError: Color(0xff000000),
      errorContainer: Color(0xffffaea4),
      onErrorContainer: Color(0xff220001),
      surface: Color(0xff141313),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffffffff),
      outline: Color(0xffeef0f1),
      outlineVariant: Color(0xffc0c3c4),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe5e2e1),
      inversePrimary: Color(0xff484a30),
      primaryFixed: Color(0xffe4e5c2),
      onPrimaryFixed: Color(0xff000000),
      primaryFixedDim: Color(0xffc7c9a7),
      onPrimaryFixedVariant: Color(0xff101202),
      secondaryFixed: Color(0xffffdf96),
      onSecondaryFixed: Color(0xff000000),
      secondaryFixedDim: Color(0xfff6bf00),
      onSecondaryFixedVariant: Color(0xff181000),
      tertiaryFixed: Color(0xffffdcc3),
      onTertiaryFixed: Color(0xff000000),
      tertiaryFixedDim: Color(0xffffb77e),
      onTertiaryFixedVariant: Color(0xff200c00),
      surfaceDim: Color(0xff141313),
      surfaceBright: Color(0xff51504f),
      surfaceContainerLowest: Color(0xff000000),
      surfaceContainerLow: Color(0xff201f1f),
      surfaceContainer: Color(0xff313030),
      surfaceContainerHigh: Color(0xff3c3b3b),
      surfaceContainerHighest: Color(0xff484646),
    );
  }

  ThemeData darkHighContrast() {
    return theme(darkHighContrastScheme());
  }


  ThemeData theme(ColorScheme colorScheme) => ThemeData(
     useMaterial3: true,
     brightness: colorScheme.brightness,
     colorScheme: colorScheme,
     textTheme: textTheme.apply(
       bodyColor: colorScheme.onSurface,
       displayColor: colorScheme.onSurface,
     ),
     scaffoldBackgroundColor: colorScheme.surface,
     canvasColor: colorScheme.surface,
  );


  List<ExtendedColor> get extendedColors => [
  ];
}

class ExtendedColor {
  final Color seed, value;
  final ColorFamily light;
  final ColorFamily lightHighContrast;
  final ColorFamily lightMediumContrast;
  final ColorFamily dark;
  final ColorFamily darkHighContrast;
  final ColorFamily darkMediumContrast;

  const ExtendedColor({
    required this.seed,
    required this.value,
    required this.light,
    required this.lightHighContrast,
    required this.lightMediumContrast,
    required this.dark,
    required this.darkHighContrast,
    required this.darkMediumContrast,
  });
}

class ColorFamily {
  const ColorFamily({
    required this.color,
    required this.onColor,
    required this.colorContainer,
    required this.onColorContainer,
  });

  final Color color;
  final Color onColor;
  final Color colorContainer;
  final Color onColorContainer;
}
