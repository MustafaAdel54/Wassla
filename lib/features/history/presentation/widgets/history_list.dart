import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/history_entry.dart';
import 'history_group_header.dart';
import 'history_item.dart';

class HistoryList extends StatelessWidget {
  final List<HistoryEntry> entries;
  final Function(HistoryEntry) onItemTap;

  const HistoryList({
    super.key,
    required this.entries,
    required this.onItemTap,
  });

  String _getGroupTitle(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final itemDate = DateTime(date.year, date.month, date.day);

    if (itemDate == today) {
      return 'Today';
    } else if (itemDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('EEE, d MMM').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, List<HistoryEntry>> groupedEntries = {};
    for (final entry in entries) {
      final title = _getGroupTitle(entry.searchedAt);
      groupedEntries.putIfAbsent(title, () => []).add(entry);
    }

    final groupTitles = groupedEntries.keys.toList();

    return ListView.builder(
      padding: EdgeInsets.only(top: 24.h, bottom: 100.h),
      itemCount: groupTitles.length,
      itemBuilder: (context, sectionIndex) {
        final title = groupTitles[sectionIndex];
        final sectionEntries = groupedEntries[title]!;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (sectionIndex > 0) SizedBox(height: 24.h),
              HistoryGroupHeader(title: title),
              ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: sectionEntries.length,
                separatorBuilder: (context, index) => Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  child: const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.lightDivider,
                  ),
                ),
                itemBuilder: (context, index) {
                  final entry = sectionEntries[index];
                  return HistoryItem(
                    entry: entry,
                    onTap: () => onItemTap(entry),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
