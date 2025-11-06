import 'package:flutter/material.dart';
import 'package:mitmui/screens/filter_manager.dart';
import 'package:mitmui/theme.dart';
import 'package:mitmui/widgets/filter/filter_group.dart';

class FilterPopup extends StatelessWidget {
  final FilterManager filterManager;
  final String title;

  const FilterPopup({
    super.key,
    required this.filterManager,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.from(Theme.brightnessOf(context));
    final screenHeight = MediaQuery.sizeOf(context).height;
    final filterWidget = FilterGroupWidget(
      group: filterManager.rootFilter,
      manager: filterManager,
      isRoot: true,
      index: 0,
    );
    return Align(
      alignment: Alignment(0, -0.3),
      child: Material(
        color: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: screenHeight * 0.8),
          child: Container(
            padding: const EdgeInsets.all(16),
            width: 600,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: theme.surface,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 8),
                  child: Text(
                    title.toUpperCase(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: theme.text,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(child: filterWidget),

                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
