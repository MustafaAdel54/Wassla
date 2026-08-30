import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppRadius {
  AppRadius._();

  static const double sm = 4.0;
  static const double md = 8.0;
  static const double lg = 16.0;
  static const double xl = 24.0;

  static BorderRadius get roundedSmall => BorderRadius.all(Radius.circular(sm.r));
  static BorderRadius get roundedMedium => BorderRadius.all(Radius.circular(md.r));
  static BorderRadius get roundedLarge => BorderRadius.all(Radius.circular(lg.r));
  static BorderRadius get roundedExtraLarge => BorderRadius.all(Radius.circular(xl.r));
}
