
import 'package:flutter/material.dart';

class AppColors {
  // Define your custom color properties
  final Color primary;
  final Color secondary;

  final Color surface;
  final Color surfaceLight;
  final Color surfaceMoreLight;
  final Color surfaceDark;
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
//   primary: Color(0xFF1A98FF),
//   secondary: Color(0xFF42A5F5),
//   // background: Color(0xFFE4E4E6),
//   background: Color(0xFFECEEF0),
//   surface: Color.fromARGB(255, 215, 221, 228),
//   surface2: Color.fromARGB(255, 189, 198, 209),
//   iconColor: Color(0xFF57647C),
//   text: Color(0xFF222222),
//   tertiaryInv: Color(0xFFFFFFFF),
//   tertiary: Color(0xFF000000),
//   greenText: Color(0xFF14A219),
//   redText: Color(0xFFF44336),
//   yellow: Color.fromARGB(255, 255, 162, 0),
//   accent: Color(0xFF0D92FF),
// );

final clr1 = Color(0xff1C1E20); // surface
final clr5 = Color(0xff232628); // headers (more lighter)
final clr2 = Color(0xff1C1C1C); // Even rows - darker (same as background)
final clr3 = Color(0xff26282A); // odd rows - little lighter
final clr4 = Color(0xff161819); // more dark (pannel header)
const darkColors = AppColors(
  primary: Color(0xFF269DFF),
  secondary: Color(0xFF1976D2),
  surface: Color(0xff1C1E20), // background
  surfaceLight: Color(0xff232628), //header
  surfaceMoreLight: Color(0xff26282A), // odd rows
  surfaceDark: Color(0xff161819), // pannel header
  surfaceTint: Color(0xff1C1E20), // even rows
  surfaceBright: Color(0xff2E3031), // background
  iconColor: Color(0xFF8895B1),
  tertiary: Color(0xFFFFFFFF),
  tertiaryInv: Color(0xFF000000),
  text: Color(0xFFF5F5F5),
  greenText: Color(0xFF4CAF50),
  redText: Color(0xFFF44336),
  yellow: Color.fromARGB(255, 255, 217, 0),
  accent: Color.fromARGB(255, 119, 153, 255),
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
