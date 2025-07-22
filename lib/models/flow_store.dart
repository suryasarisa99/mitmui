// flow_store.dart
import 'package:flutter/foundation.dart';
import 'flow.dart' as models;

/// Manages a collection of flows with notification capabilities
class FlowStore extends ChangeNotifier {
  final Map<String, models.Flow> _flows = {};
  List<models.Flow> _filteredFlows = [];
  String _filter = '';

  FlowStore();

  /// Get all flows as a list
  List<models.Flow> get flows => _flows.values.toList();

  /// Get filtered flows
  List<models.Flow> get filteredFlows => _filteredFlows;

  /// Get the current filter text
  String get filter => _filter;

  /// Get count of all flows
  int get count => _flows.length;

  /// Get count of filtered flows
  int get filteredCount => _filteredFlows.length;

  /// Add or update a flow in the store
  void addOrUpdateFlow(models.Flow flow) {
    _flows[flow.id] = flow;
    _applyFilter();
    notifyListeners();
  }

  void addMultiple(List<models.Flow> flows) {
    for (final flow in flows) {
      _flows[flow.id] = flow;
    }
    _applyFilter();
    notifyListeners();
  }

  /// Handle a WebSocket message from mitmproxy
  void handleMessage(String message) {
    final flow = models.Flow.parseFlowMessage(message);
    if (flow != null) {
      addOrUpdateFlow(flow);
    }
  }

  /// Clear all flows
  void clear() {
    _flows.clear();
    _filteredFlows = [];
    notifyListeners();
  }

  /// Remove a flow by ID
  void removeFlow(String id) {
    _flows.remove(id);
    _applyFilter();
    notifyListeners();
  }

  /// Get a flow by ID
  models.Flow? getFlow(String id) {
    return _flows[id];
  }

  /// Set a filter for the flows
  void setFilter(String filter) {
    _filter = filter;
    _applyFilter();
    notifyListeners();
  }

  /// Apply the current filter to the flows
  void _applyFilter() {
    if (_filter.isEmpty) {
      _filteredFlows = _flows.values.toList();
      _filteredFlows.sort(
        (a, b) => b.timestampCreated.compareTo(a.timestampCreated),
      );
      return;
    }

    final lowercaseFilter = _filter.toLowerCase();
    _filteredFlows = _flows.values.where((flow) {
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
  List<models.Flow> get webSocketFlows =>
      _flows.values.where((flow) => flow.isWebSocket).toList()
        ..sort((a, b) => b.timestampCreated.compareTo(a.timestampCreated));

  /// Get HTTP flows only (non-WebSocket)
  List<models.Flow> get httpFlows =>
      _flows.values.where((flow) => !flow.isWebSocket).toList()
        ..sort((a, b) => b.timestampCreated.compareTo(a.timestampCreated));
}
