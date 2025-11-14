import 'package:flutter/material.dart';

class AppColors {
  // Define your custom color properties
  final Color primary;
  final Color secondary;

  final Color surface;
  final Color surfaceLight;
  final Color surfaceMoreLight;
  final Color surfaceDark;
  final Color surfaceTooDark;
  final Color surfaceTint;
  final Color surfaceBright;

  final Color iconColor;
  final Color tertiary;
  final Color tertiaryInv;
  final Color text;
  final Color accent;
  final Color greenText;
  final Color yellow;
  final Color redText;

  const AppColors({
    required this.primary,
    required this.secondary,
    required this.surface,
    required this.surfaceLight,
    required this.surfaceMoreLight,
    required this.surfaceDark,
    required this.surfaceTooDark,
    required this.surfaceTint,
    required this.surfaceBright,
    required this.iconColor,
    required this.tertiary,
    required this.tertiaryInv,
    required this.text,
    required this.greenText,
    required this.redText,
    required this.yellow,
    required this.accent,
  });
}

// const lightColors = AppColors(
//   primary: .new(0xFF1A98FF),
//   secondary: .new(0xFF42A5F5),
//   // background: .new(0xFFE4E4E6),
//   background: .new(0xFFECEEF0),
//   surface: .fromARGB(255, 215, 221, 228),
//   surface2: .fromARGB(255, 189, 198, 209),
//   iconColor: .new(0xFF57647C),
//   text: .new(0xFF222222),
//   tertiaryInv: .new(0xFFFFFFFF),
//   tertiary: .new(0xFF000000),
//   greenText: .new(0xFF14A219),
//   redText: .new(0xFFF44336),
//   yellow: .fromARGB(255, 255, 162, 0),
//   accent: .new(0xFF0D92FF),
// );

final clr1 = Color(0xff1C1E20); // surface
final clr5 = Color(0xff232628); // headers (more lighter)
final clr2 = Color(0xff1C1C1C); // Even rows - darker (same as background)
final clr3 = Color(0xff26282A); // odd rows - little lighter
final clr4 = Color(0xff161819); // more dark (panel header)

const darkColors = AppColors(
  primary: .new(0xFF269DFF),
  secondary: .new(0xFF1976D2),
  surface: .new(0xff1C1E20), // background
  surfaceLight: .new(0xff232628), //header
  surfaceMoreLight: .new(0xff26282A), // odd rows
  surfaceDark: .new(0xff161819), // panel header
  surfaceTooDark: .new(0xFF121415), // panel header
  surfaceTint: .new(0xff1C1E20), // even rows
  surfaceBright: .new(0xff2E3031), // background
  iconColor: .new(0xFF8895B1),
  tertiary: .new(0xFFFFFFFF),
  tertiaryInv: .new(0xFF000000),
  text: .new(0xFFF5F5F5),
  greenText: .new(0xFF4CAF50),
  redText: .new(0xFFF44336),
  yellow: .fromARGB(255, 255, 217, 0),
  accent: .fromARGB(255, 119, 153, 255),
);

class AppTheme {
  static const AppColors light = darkColors;
  static const AppColors dark = darkColors;

  // Get the correct AppColors based on brightness
  static AppColors of(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? dark : light;
  }

  static AppColors from(Brightness brightness) {
    return brightness == Brightness.dark ? dark : light;
  }
}
