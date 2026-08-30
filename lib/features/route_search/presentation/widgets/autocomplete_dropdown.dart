import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../shared/widgets/wassla_card.dart';
import '../../domain/entities/routing_entities.dart';

class AutocompleteDropdown extends StatelessWidget {
  final List<Place> suggestions;
  final ValueChanged<Place> onSelected;

  const AutocompleteDropdown({
    super.key,
    required this.suggestions,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: 4.h),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: 250.h),
        child: Material(
          color: AppColors.lightSurface,
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.5),
          borderRadius: AppRadius.roundedMedium,
          child: ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: suggestions.length,
            itemBuilder: (context, index) {
              final place = suggestions[index];
              return ListTile(
                title: Text(place.name, style: Theme.of(context).textTheme.bodyMedium),
                dense: true,
                onTap: () => onSelected(place),
              );
            },
          ),
        ),
      ),
    );
  }
}
