import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../domain/entities/routing_entities.dart';

class RouteSearchResultCard extends StatelessWidget {
  final RouteResult result;

  const RouteSearchResultCard({super.key, required this.result});

  IconData _modeIcon(String mode) {
    switch (mode) {
      case 'metro':
        return Icons.subway;
      case 'bus':
        return Icons.directions_bus;
      case 'microbus':
      case 'minibus':
        return Icons.airport_shuttle;
      case 'walking':
        return Icons.directions_walk;
      default:
        return Icons.commute;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${result.durationMinutes} minutes',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '${result.transfers} transfer(s) · '
                  '${result.walkingMinutes} min walking',
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
        const Divider(),
        ...result.segments.map(
          (seg) => ListTile(
            leading: Icon(_modeIcon(seg.mode)),
            title: Text(seg.routeName ?? seg.mode),
            subtitle: Text('${seg.fromName} → ${seg.toName}'),
            trailing: Text('${seg.durationMinutes} min'),
          ),
        ),
      ],
    );
  }
}
