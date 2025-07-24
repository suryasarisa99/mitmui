import 'package:flutter/foundation.dart';

/// Notifier for selected row IDs in a DataGrid
class SelectedIdsNotifier extends ValueNotifier<List<dynamic>> {
  SelectedIdsNotifier() : super([]);

  /// Add IDs to the selection
  void addIds(List<dynamic> ids) {
    value = [...value, ...ids];
  }

  /// Remove IDs from the selection
  void removeIds(List<dynamic> ids) {
    value = value.where((id) => !ids.contains(id)).toList();
  }

  /// Set the selection directly
  void setIds(List<dynamic> ids) {
    value = List<dynamic>.from(ids);
  }
}

final selectedIdsNotifier = SelectedIdsNotifier();
