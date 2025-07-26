import 'package:flutter_riverpod/flutter_riverpod.dart';

class FilteredFlowsProvider extends Notifier<Set<String>> {
  FilteredFlowsProvider() : super();

  @override
  Set<String> build() {
    return {};
  }

  void updateInitial(Set<String> initialFlows) {
    state = initialFlows;
  }

  void addNew(String flowId) {
    state = {...state, flowId};
  }

  void clear() {
    state = {};
  }
}

final filteredFlowsProvider =
    NotifierProvider<FilteredFlowsProvider, Set<String>>(
      FilteredFlowsProvider.new,
    );
