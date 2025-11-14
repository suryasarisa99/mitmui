
import 'package:mitmui/models/flow.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Manages a collection of flows with notification capabilities
class FlowsProvider extends Notifier<Map<String, MitmFlow>> {
  List<MitmFlow> _filteredFlows = [];
  final String _filter = '';
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
    // _applyFilter();
  }

  void addAll(List<MitmFlow> flows) {
    // for (final flow in flows) {
    //   state[flow.id] = flow;
    // }
    state = {...state, for (final flow in flows) flow.id: flow};
    // _applyFilter();
  }

  // 2 , 3, 1
  // when we first intercept flow: 3,3 3,3
  void handleMessage(Map<String, dynamic> message) {
    final MitmFlow? prvFlow = state[message['id']];
    final bool isIntercepted = message['intercepted'] ?? false;
    final interceptedState = prvFlow?.interceptedState;

    // log(
    //   "req headers (${prvFlow?.request?.headers.length}): ${prvFlow?.request?.headers}",
    // );
    if (interceptedState == 'none' && isIntercepted) {
      // print("add/update: condition: 1");
      addOrUpdateFlow(
        MitmFlow.fromJson(
          message,
          interceptedState: "server_block",
          headers: prvFlow?.request?.headers,
          enabledHeaders: prvFlow?.request?.enabledHeaders,
          enabledQueryParams: prvFlow?.request?.enabledQueryParams,
          path: prvFlow?.request?.path,
        ),
      );
    } else if (prvFlow == null) {
      // print("add/update: condition: 2");
      addOrUpdateFlow(MitmFlow.fromJson(message));
    } else {
      // print("add/update: condition: 3 ${prvFlow.interceptedState}");
      addOrUpdateFlow(
        MitmFlow.fromJson(
          message,
          interceptedState: prvFlow.interceptedState,
          headers: prvFlow.request?.headers,
          enabledHeaders: prvFlow.request?.enabledHeaders,
          enabledQueryParams: prvFlow.request?.enabledQueryParams,
          path: prvFlow.request?.path,
        ),
      );
    }
  }

  void updateFlowState(String flowId, String oldState) {
    final flow = state[flowId];
    if (flow != null) {
      final newState = switch (oldState) {
        'server_block' => 'client_block',
        'client_block' => 'none',
        _ => 'none',
      };
      print("Updating flow $flowId state from $oldState to $newState");
      state = {...state, flowId: flow.copyWith(interceptedState: newState)};
    }
  }

  void updateReq(String flowId, HttpRequest Function(HttpRequest) newRequest) {
    final flow = state[flowId];
    if (flow != null) {
      state = {
        ...state,
        flowId: flow.copyWith(request: newRequest(flow.request!)),
      };
    }
  }

  void addHeader(String flowId, List<String> header, bool status) {
    updateReq(flowId, (req) {
      final headers = req.headers..add(header);
      final enabledHeaders = req.enabledHeaders != null
          ? (List<bool>.from(req.enabledHeaders!)..add(status))
          : null;
      return req.copyWith(headers: headers, enabledHeaders: enabledHeaders);
    });
  }

  void updateEnabledHeaders(String flowId, List<bool> enabledHeaders) {
    updateReq(flowId, (req) => req.copyWith(enabledHeaders: enabledHeaders));
  }

  void updateHeader(String flowId, int index, String key, String value) {
    updateReq(flowId, (req) {
      final headers = req.headers;
      headers[index] = [key, value];
      return req.copyWith(headers: headers);
    });
  }

  /// Clear all flows
  void clear() {
    state.clear();
    _filteredFlows = [];
  }

  /// Remove a flow by ID
  void removeFlow(String id) {
    // state.remove(id);
    state = Map.of(state)..remove(id);
    // _applyFilter();
  }

  void removeFlows(Iterable<String> ids) {
    // for (final id in ids) {
    //   state.remove(id);
    // }
    state = Map.of(state)..removeWhere((key, value) => ids.contains(key));
    // _applyFilter();
  }

  /// Get a flow by ID
  MitmFlow? getFlow(String id) {
    return state[id];
  }

  List<MitmFlow> getFlowsByIds(Set<String> ids) {
    return ids.map((id) => state[id]).whereType<MitmFlow>().toList();
  }
}

final flowsProvider = NotifierProvider<FlowsProvider, Map<String, MitmFlow>>(
  () => FlowsProvider(),
);

final selectedFlowProvider = Provider.family<MitmFlow?, String>((ref, flowId) {
  final flows = ref.watch(flowsProvider);
  return flows[flowId];
});
