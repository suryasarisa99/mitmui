import 'package:mitmui/models/flow.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Manages a collection of flows with notification capabilities
class FlowsProvider extends Notifier<Map<String, MitmFlow>> {
  List<MitmFlow> _filteredFlows = [];
  String _filter = '';
  FlowsProvider() : super();
  @override
  Map<String, MitmFlow> build() {
    return {};
  }

  /// Get all flows as a list
  List<MitmFlow> get flows => state.values.toList();

  /// Get filtered flows
  List<MitmFlow> get filteredFlows => _filteredFlows;

  /// Get the current filter text
  String get filter => _filter;

  /// Get count of all flows
  int get count => state.length;

  /// Get count of filtered flows
  int get filteredCount => _filteredFlows.length;

  /// Add or update a flow in the store
  void addOrUpdateFlow(MitmFlow flow) {
    // state[flow.id] = flow;
    state = {...state, flow.id: flow};
    _applyFilter();
  }

  void addAll(List<MitmFlow> flows) {
    // for (final flow in flows) {
    //   state[flow.id] = flow;
    // }
    state = {...state, for (final flow in flows) flow.id: flow};
    _applyFilter();
  }

  /// Handle a WebSocket message from mitmproxy
  void handleMessage(String message) {
    final flow = MitmFlow.parseFlowMessage(message);
    if (flow != null) {
      addOrUpdateFlow(flow);
    }
  }

  /// Clear all flows
  void clear() {
    state.clear();
    _filteredFlows = [];
  }

  /// Remove a flow by ID
  void removeFlow(String id) {
    state.remove(id);
    _applyFilter();
  }

  /// Get a flow by ID
  MitmFlow? getFlow(String id) {
    return state[id];
  }

  /// Set a filter for the flows
  void setFilter(String filter) {
    _filter = filter;
    _applyFilter();
  }

  /// Apply the current filter to the flows
  void _applyFilter() {
    if (_filter.isEmpty) {
      _filteredFlows = state.values.toList();
      _filteredFlows.sort(
        (a, b) => b.timestampCreated.compareTo(a.timestampCreated),
      );
      return;
    }

    final lowercaseFilter = _filter.toLowerCase();
    _filteredFlows = state.values.where((flow) {
      // Search in request URL
      if (flow.request.url.toLowerCase().contains(lowercaseFilter)) {
        return true;
      }

      // Search in request method
      if (flow.request.method.toLowerCase().contains(lowercaseFilter)) {
        return true;
      }

      // Search in host
      if ((flow.request.prettyHost ?? flow.request.host).toLowerCase().contains(
        lowercaseFilter,
      )) {
        return true;
      }

      // Search in response status (if available)
      if (flow.response != null) {
        if (flow.response!.statusCode.toString().contains(lowercaseFilter)) {
          return true;
        }
      }

      return false;
    }).toList();

    // Sort by timestamp, newest first
    _filteredFlows.sort(
      (a, b) => b.timestampCreated.compareTo(a.timestampCreated),
    );
  }

  /// Get WebSocket flows only
  List<MitmFlow> get webSocketFlows =>
      state.values.where((flow) => flow.isWebSocket).toList()
        ..sort((a, b) => b.timestampCreated.compareTo(a.timestampCreated));

  /// Get HTTP flows only (non-WebSocket)
  List<MitmFlow> get httpFlows =>
      state.values.where((flow) => !flow.isWebSocket).toList()
        ..sort((a, b) => b.timestampCreated.compareTo(a.timestampCreated));
}

final flowsProvider = NotifierProvider<FlowsProvider, Map<String, MitmFlow>>(
  () => FlowsProvider(),
);

final selectedFlowProvider = Provider.family<MitmFlow?, String>((ref, flowId) {
  final flows = ref.watch(flowsProvider);
  return flows[flowId];
});
