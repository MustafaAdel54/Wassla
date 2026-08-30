import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/wassla_button.dart';
import '../../../../shared/widgets/wassla_card.dart';
import '../../../../shared/widgets/wassla_text_field.dart';
import '../cubit/autocomplete_cubit.dart';
import 'autocomplete_dropdown.dart';
import 'visual_swap_button.dart';

class RouteSearchForm extends StatelessWidget {
  final TextEditingController originCtrl;
  final TextEditingController destCtrl;
  final FocusNode originFocusNode;
  final FocusNode destFocusNode;
  final AutocompleteCubit fromCubit;
  final AutocompleteCubit toCubit;
  final VoidCallback onSearch;

  const RouteSearchForm({
    super.key,
    required this.originCtrl,
    required this.destCtrl,
    required this.originFocusNode,
    required this.destFocusNode,
    required this.fromCubit,
    required this.toCubit,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: SizedBox(
            width: 327.w,
            height: 184.h,
            child: Center(
              child: Image.asset('assets/icons/logo_written.png', fit: BoxFit.contain),
            ),
          ),
        ),
        Column(
          children: [
            _AutocompleteInputField(
              label: 'From',
              hintText: 'Where are you?',
              iconAsset: 'assets/icons/from_location.svg',
              controller: originCtrl,
              focusNode: originFocusNode,
              cubit: fromCubit,
            ),
            // The 32px Gap and the exactly centered Swap button
            SizedBox(
              height: 32.h,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: (32.h - 44.h) / 2 + 13.5.h,
                    child: const VisualSwapButton(),
                  ),
                ],
              ),
            ),
            _AutocompleteInputField(
              label: 'To',
              hintText: 'Where are you going?',
              iconAsset: 'assets/icons/to_location.svg',
              controller: destCtrl,
              focusNode: destFocusNode,
              cubit: toCubit,
            ),
          ],
        ),
        SizedBox(height: AppSpacing.lg.h),
        WasslaButton(
          text: 'Guide Me',
          backgroundColor: const Color(0xFF070938), // AppColors.darkBackgroundAlt
          foregroundColor: const Color(0xFFFAF9F6), // AppColors.lightBackground
          onPressed: onSearch,
        ),
        SizedBox(height: AppSpacing.md.h),
        Center(
          child: Text(
            'Recent Routes',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF56586D), // AppColors.lightTextMuted
                ),
          ),
        ),
      ],
    );
  }
}

class _AutocompleteInputField extends StatefulWidget {
  final String label;
  final String hintText;
  final String iconAsset;
  final TextEditingController controller;
  final FocusNode focusNode;
  final AutocompleteCubit cubit;

  const _AutocompleteInputField({
    required this.label,
    required this.hintText,
    required this.iconAsset,
    required this.controller,
    required this.focusNode,
    required this.cubit,
  });

  @override
  State<_AutocompleteInputField> createState() => _AutocompleteInputFieldState();
}

class _AutocompleteInputFieldState extends State<_AutocompleteInputField> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_checkScroll);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_checkScroll);
    super.dispose();
  }

  void _checkScroll() {
    if (widget.focusNode.hasFocus) {
      _scrollToVisible();
    }
  }

  void _scrollToVisible() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Scrollable.ensureVisible(
        context,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        duration: const Duration(milliseconds: 300),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final borderColor = isLight ? const Color(0xFF070938) : null;

    return BlocConsumer<AutocompleteCubit, AutocompleteState>(
      bloc: widget.cubit,
      listener: (context, state) {
        if (state.suggestions.isNotEmpty && widget.focusNode.hasFocus) {
          _scrollToVisible();
        }
      },
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: isLight ? const Color(0xFF05072F) : null,
                  ),
            ),
            SizedBox(height: AppSpacing.sm.h),
            WasslaTextField(
              hintText: widget.hintText,
              borderColor: borderColor,
              controller: widget.controller,
              focusNode: widget.focusNode,
              onChanged: widget.cubit.onQueryChanged,
              prefixIcon: Padding(
                padding: EdgeInsets.all(12.w),
                child: SvgPicture.asset(widget.iconAsset),
              ),
            ),
            if (state.suggestions.isNotEmpty)
              AutocompleteDropdown(
                suggestions: state.suggestions,
                onSelected: (place) {
                  widget.focusNode.unfocus();
                  widget.cubit.onSuggestionSelected(place);
                  widget.controller.text = place.name;
                },
              ),
          ],
        );
      },
    );
  }
}
