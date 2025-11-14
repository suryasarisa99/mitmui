import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Abstract class for building TabBar panels with dynamic tab labels.
abstract class AbstractPanelTitles extends ConsumerWidget {
  const AbstractPanelTitles({
    super.key,
    required this.id,
    required this.tabController,
  });

  final String id;
  final TabController tabController;

  /// Subclasses must implement this to provide a list of tabs.
  /// Each tab is represented as a `String` label.
  List<String> buildTabLabels(WidgetRef ref, String id);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabLabels = buildTabLabels(ref, id);

    return TabBar(
      controller: tabController,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      labelColor: const .new(0xFFFF7474),
      unselectedLabelColor: Colors.grey,
      indicatorColor: const .new(0xFFFD5A4F),
      labelPadding: const .symmetric(horizontal: 8.0),
      indicatorPadding: .zero,
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.normal),
      tabs: [for (final label in tabLabels) Tab(text: label)],
    );
  }
}
