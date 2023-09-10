import 'package:filcnaplo/theme/colors/colors.dart';
import 'package:flutter/material.dart';

class DarkDesktopAppColors implements ThemeAppColors {
  @override
  final shadow = const Color(0x00000000);
  @override
  final text = Colors.white;
  // @override
  // final background = const Color.fromARGB(255, 42, 42, 42);
  @override
  final highlight = const Color.fromARGB(255, 46, 48, 50);
  @override
  final red = const Color(0xffFF453A);
  @override
  final orange = const Color(0xffFF9F0A);
  @override
  final yellow = const Color(0xffFFD60A);
  @override
  final green = const Color(0xff32D74B);
  @override
  final filc = const Color(0xff3d7bf4);
  @override
  final teal = const Color(0xff64D2FF);
  @override
  final blue = const Color(0xff0A84FF);
  @override
  final indigo = const Color(0xff5E5CE6);
  @override
  final purple = const Color(0xffBF5AF2);
  @override
  final pink = const Color(0xffFF375F);
  // new default grade colors
  @override
  final gradeFive = const Color(0xff3d7bf4);
  @override
  final gradeFour = const Color(0xFF4C3DF4);
  @override
  final gradeThree = const Color(0xFF833DF4);
  @override
  final gradeTwo = const Color(0xFFAE3DF4);
  @override
  final gradeOne = const Color(0xFFF43DAB);
  // v5 ui base
  @override
  final background = const Color(0xFF0F131D);
  @override
  final title = const Color(0xFFD4DAE7);
  // v5 ui login
  @override
  final loginPrimary = const Color(0xFF0A1C41);
  @override
  final loginSecondary = const Color(0xFF0A1C41);
  @override
  final inputBorder = const Color(0xFF586A8E);
  @override
  final loginBackground = const Color(0xFFEFF4FE);
  @override
  final buttonBackground = const Color(0xFF0A1C41);
}
