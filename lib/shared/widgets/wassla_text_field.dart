import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class WasslaTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final String? errorText;
  final Color? borderColor;

  const WasslaTextField({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.focusNode,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.errorText,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 327.w),
        child: SizedBox(
          height: errorText == null ? 44.h : null, // Exact Figma height for input box
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            obscureText: obscureText,
            onChanged: onChanged,
            onTap: onTap,
            readOnly: readOnly,
            style: Theme.of(context).textTheme.bodyLarge,
            decoration: InputDecoration(
              labelText: label,
              hintText: hintText,
              hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF17182B),
                  ),
              prefixIcon: prefixIcon,
              suffixIcon: suffixIcon,
              errorText: errorText,
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              enabledBorder: borderColor != null
                  ? Theme.of(context).inputDecorationTheme.enabledBorder?.copyWith(
                        borderSide: BorderSide(color: borderColor!, width: 1.w),
                      )
                  : null,
              border: borderColor != null
                  ? Theme.of(context).inputDecorationTheme.border?.copyWith(
                        borderSide: BorderSide(color: borderColor!, width: 1.w),
                      )
                  : null,
              focusedBorder: borderColor != null
                  ? Theme.of(context).inputDecorationTheme.focusedBorder?.copyWith(
                        borderSide: BorderSide(color: borderColor!, width: 2.w),
                      )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
