import 'dart:io';

import 'package:filcnaplo/theme/colors/dark_desktop.dart';
import 'package:filcnaplo/theme/colors/dark_mobile.dart';
import 'package:filcnaplo/theme/colors/light_desktop.dart';
import 'package:filcnaplo/theme/colors/light_mobile.dart';
import 'package:flutter/material.dart';

class AppColors {
  static ThemeAppColors of(BuildContext context) =>
      fromBrightness(Theme.of(context).brightness);

  static ThemeAppColors fromBrightness(Brightness brightness) {
    if (Platform.isAndroid || Platform.isIOS) {
      switch (brightness) {
        case Brightness.light:
          return LightMobileAppColors();
        case Brightness.dark:
          return DarkMobileAppColors();
      }
    } else {
      switch (brightness) {
        case Brightness.light:
          return LightDesktopAppColors();
        case Brightness.dark:
          return DarkDesktopAppColors();
      }
    }
  }
}

abstract class ThemeAppColors {
  final Color shadow = const Color(0x00000000);
  final Color text = const Color(0x00000000);
  final Color highlight = const Color(0x00000000);
  final Color red = const Color(0x00000000);
  final Color orange = const Color(0x00000000);
  final Color yellow = const Color(0x00000000);
  final Color green = const Color(0x00000000);
  final Color filc = const Color(0x00000000);
  final Color teal = const Color(0x00000000);
  final Color blue = const Color(0x00000000);
  final Color indigo = const Color(0x00000000);
  final Color purple = const Color(0x00000000);
  final Color pink = const Color(0x00000000);
  // new default grade colors
  final Color gradeFive = const Color(0x00000000);
  final Color gradeFour = const Color(0x00000000);
  final Color gradeThree = const Color(0x00000000);
  final Color gradeTwo = const Color(0x00000000);
  final Color gradeOne = const Color(0x00000000);
  // v5 ui base
  final Color background = const Color(0x00000000);
  final Color title = const Color(0x00000000);
  // v5 ui login
  final loginPrimary = const Color(0x00000000);
  final loginSecondary = const Color(0x00000000);
  final inputBorder = const Color(0x00000000);
  final loginBackground = const Color(0x00000000);
  final buttonBackground = const Color(0x00000000);
}
