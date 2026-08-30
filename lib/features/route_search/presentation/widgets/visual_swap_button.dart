import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class VisualSwapButton extends StatelessWidget {
  const VisualSwapButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: SvgPicture.asset(
          'assets/icons/swap.svg',
          width: 44.w, // Match typical Figma bounds or intrinsic
          height: 44.h,
        ),
      ),
    );
  }
}
