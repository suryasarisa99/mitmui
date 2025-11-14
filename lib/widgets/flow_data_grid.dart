import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitmui/api/mitmproxy_client.dart';
import 'package:mitmui/dt_table/dt_table.dart';
import 'package:mitmui/dt_table/dt_models.dart';
import 'package:mitmui/global.dart';
import 'package:mitmui/theme.dart';
import 'package:mitmui/utils/extensions.dart';
// import 'package:mitmui/widgets/filter.dart';
import 'package:mitmui/services/websocket_service.dart';
import 'package:mitmui/store/filtered_flows_provider.dart';
import 'package:mitmui/store/flows_provider.dart';
import 'package:mitmui/utils/logger.dart';
import 'package:mitmui/widgets/compare/http_compare_wrapper.dart';
import 'package:super_context_menu/super_context_menu.dart';

import 'flow_data_source.dart';

const _log = Logger("flow_data_grid");

class FlowDataGrid extends ConsumerStatefulWidget {
  final DtController controller;

  const FlowDataGrid({super.key, required this.controller});

  @override
  ConsumerState<FlowDataGrid> createState() => _FlowDataGridState();
}

class _FlowDataGridState extends ConsumerState<FlowDataGrid> {
  late final FlowDataSource _flowDataSource = FlowDataSource(
    initialFlows: ref.read(flowsProvider).values.toList(),
    dtController: widget.controller,
    resumeIntercept: resumeIntercept,
  );

  String mitmFilter = '';
  @override
  void initState() {
    super.initState();
    ref.listenManual(flowsProvider, (oldFlows, newFlows) {
      int flowsAdded = newFlows.length - (oldFlows?.length ?? 0);
      if (mitmFilter.isEmpty) {
        _flowDataSource.handleFlows(newFlows.values.toList());
      }
      if (flowsAdded > 0) {}
    });

    filterManager.addListener(() {
      // trigger set filter in websocket service
      final webSocketService = ref.read(websocketServiceProvider);
      mitmFilter = filterManager.mitmproxyString;
      debugPrint("filter: $mitmFilter");
      if (mitmFilter.isNotEmpty) {
        webSocketService.updateFilter(mitmFilter);
      } else {
        // reset filter and show all flows
        webSocketService.updateFilter(mitmFilter);
        _flowDataSource.handleFlows(ref.read(flowsProvider).values.toList());
      }
    });
    ref.listenManual(filteredFlowsProvider, (_, newIds) {
      final filteredFlows = ref
          .read(flowsProvider.notifier)
          .getFlowsByIds(newIds);
      _flowDataSource.handleFlows(filteredFlows);
    });
    interceptManager.addListener(() {
      MitmproxyClient.interceptFlow(interceptManager.mitmproxyString);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Store column widths
  final Map<String, double> _columnWidths = {
    'id': 44,
    'url': 1180,
    'method': 80,
    'status': 60,
    'type': 150,
    'time': 100,
    'duration': 100,
    'reqLen': 100,
    'resLen': 100,
  };

  @override
  Widget build(BuildContext context) {
    // print("rebuilding FlowDataGrid");
    // MediaQuery.sizeOf(context).width;
    final theme = AppTheme.from(Theme.brightnessOf(context));
    final headerCells = [
      (title: "ID", key: 'id'),
      (title: "URL", key: 'url'),
      (title: "Method", key: 'method'),
      (title: "Status", key: 'status'),
      (title: "Type", key: 'type'),
      (title: "Time", key: 'time'),
      (title: "Duration", key: 'duration'),
      (title: "Req", key: 'reqLen'),
      (title: "Res", key: 'resLen'),
    ];
    return Container(
      color: theme.surface,
      child: DtTable(
        source: _flowDataSource,
        controller: widget.controller,
        // tableWidth: MediaQuery.sizeOf(context).width,
        tableWidth: double.infinity,
        headerHeight: 24,
        rowHeight: 32,
        menuProvider: buildContextMenu,
        onKeyEvent: handleKeyEvent,
        headerColumns: [
          for (final header in headerCells)
            DtColumn(
              key: header.key,
              title: header.title,
              fontSize: 12,
              initialWidth: _columnWidths[header.key]!,
              isNumeric: header.key == 'id' || header.key == 'status',
              isExpand: header.key == 'url',
              // maxWidth: 1200,
            ),
        ],
      ),
    );
  }

  Menu buildContextMenu(MenuRequest e) {
    final currSelId = widget.controller.focusedRowId;
    final selectedIds = widget.controller.selectedRowIds;
    final multiple = selectedIds.length > 1;
    final flow = ref.read(flowsProvider)[currSelId];
    if (flow == null) {
      _log.error("No flows available for context menu");
      return Menu(children: []);
    }
    final interceptedState = flow.interceptedState;
    final isIntercepted = flow.intercepted;
    final cantResume = multiple || !isIntercepted || interceptedState == 'none';
    final modifiedIds = selectedIds.where(
      (id) => ref.read(flowsProvider)[id]?.modified == true,
    );
    return Menu(
      children: [
        MenuAction(
          activator: SingleActivator(LogicalKeyboardKey.keyC, meta: true),
          callback: () => copyUrls(selectedIds),
          title: 'Copy Url${multiple ? 's' : ''}',
        ),
        MenuAction(
          activator: SingleActivator(
            LogicalKeyboardKey.keyC,
            meta: true,
            alt: true,
          ),
          // attributes: MenuActionAttributes(disabled: multiple),
          callback: () => copyExports(selectedIds),
          title: 'Copy Curl',
        ),
        Menu(
          children: [
            ...[
              (label: "Httpie", exportType: RequestExport.httpie),
              (label: "Raw", exportType: RequestExport.raw),
              (label: "Raw Request", exportType: RequestExport.rawRequest),
              (label: "Raw Response", exportType: RequestExport.rawResponse),
            ].map((item) {
              return MenuAction(
                // attributes: MenuActionAttributes(disabled: multiple),
                // callback: () => copyExport(currSelId!, item.exportType),
                callback: () => copyExports(selectedIds, item.exportType),
                title: 'Copy ${item.label}',
              );
            }),
          ],
          title: "Copy As",
        ),
        MenuSeparator(),
        MenuAction(
          attributes: MenuActionAttributes(disabled: cantResume),
          // activator: SingleActivator(LogicalKeyboardKey.enter, meta: true),
          callback: () => resumeIntercept(currSelId!, interceptedState),
          title: "Resume Intercept",
        ),
        MenuAction(
          activator: SingleActivator(LogicalKeyboardKey.enter, meta: true),
          callback: () => repeatRequests(selectedIds),
          title: "Repeat",
        ),
        MenuAction(
          callback: () => duplicateFlows(selectedIds),
          title: "Duplicate",
        ),
        MenuAction(
          attributes: MenuActionAttributes(disabled: modifiedIds.isEmpty),
          activator: SingleActivator(LogicalKeyboardKey.backspace, meta: true),
          callback: () => revertChanges(modifiedIds),
          title: "Revert Changes",
        ),
        Menu(
          children: [
            ...[
              (mark: MarkCircle.red, key: LogicalKeyboardKey.digit1),
              (mark: MarkCircle.orange, key: LogicalKeyboardKey.digit2),
              (mark: MarkCircle.yellow, key: LogicalKeyboardKey.digit3),
              (mark: MarkCircle.green, key: LogicalKeyboardKey.digit4),
              (mark: MarkCircle.blue, key: LogicalKeyboardKey.digit5),
              (mark: MarkCircle.purple, key: LogicalKeyboardKey.digit6),
              (mark: MarkCircle.brown, key: LogicalKeyboardKey.digit7),
            ].mapIndexed((i, item) {
              return MenuAction(
                activator: SingleActivator(item.key, meta: true),
                callback: () => markSelected(selectedIds, item.mark),
                title: item.mark.name,
              );
            }),
            MenuSeparator(),
            MenuAction(
              activator: SingleActivator(LogicalKeyboardKey.digit0, meta: true),
              callback: () => markSelected(selectedIds, MarkCircle.unMark),
              title: "Un Mark",
            ),
          ],
          title: "Mark",
        ),
        MenuAction(
          attributes: MenuActionAttributes(disabled: selectedIds.length != 2),
          callback: () => compare(selectedIds),
          title: "Compare Selected",
        ),
        MenuAction(
          activator: SingleActivator(LogicalKeyboardKey.delete),
          callback: () => deleteSelected(selectedIds),
          title: "Delete",
        ),

        // MenuSeparator(),
      ],
    );
  }

  bool handleKeyEvent(KeyEvent keyEvent) {
    final hk = HardwareKeyboard.instance;
    final isMeta = hk.isMetaPressed;
    final isAlt = hk.isAltPressed;
    final k = keyEvent.logicalKey;
    final flowId = widget.controller.focusedRowId;
    if (flowId == null) return false;
    final selectedIds = widget.controller.selectedRowIds;
    _log.info("Key event: ${keyEvent.logicalKey.debugName}");
    if (isMeta && isAlt && k == LogicalKeyboardKey.keyC) {
      copyExports(selectedIds);
      return true;
    } else if (isMeta && k == LogicalKeyboardKey.keyC) {
      copyUrls(selectedIds);
      return true;
    } else if (k == LogicalKeyboardKey.delete) {
      deleteSelected(selectedIds);
      return true;
    } else if (isMeta && k == LogicalKeyboardKey.enter) {
      repeatRequests(selectedIds);
      return true;
    } else if (k == LogicalKeyboardKey.backspace) {
      revertChanges(selectedIds);
      return true;
    } else if (isMeta && k == LogicalKeyboardKey.keyD) {
      duplicateFlows(selectedIds);
      return true;
    }
    // for mark : cmd + digit1, digit2,...
    else if (isMeta && k == LogicalKeyboardKey.digit1) {
      markSelected(selectedIds, MarkCircle.red);
      return true;
    } else if (isMeta && k == LogicalKeyboardKey.digit2) {
      markSelected(selectedIds, MarkCircle.orange);
      return true;
    } else if (isMeta && k == LogicalKeyboardKey.digit3) {
      markSelected(selectedIds, MarkCircle.yellow);
      return true;
    } else if (isMeta && k == LogicalKeyboardKey.digit4) {
      markSelected(selectedIds, MarkCircle.green);
      return true;
    } else if (isMeta && k == LogicalKeyboardKey.digit5) {
      markSelected(selectedIds, MarkCircle.blue);
      return true;
    } else if (isMeta && k == LogicalKeyboardKey.digit6) {
      markSelected(selectedIds, MarkCircle.purple);
      return true;
    } else if (isMeta && k == LogicalKeyboardKey.digit7) {
      markSelected(selectedIds, MarkCircle.brown);
      return true;
    } else if (isMeta && k == LogicalKeyboardKey.digit0) {
      markSelected(selectedIds, MarkCircle.unMark);
      return true;
    }
    return false; // Let the grid handle other key events
  }

  void deleteSelected(Set<String> selectedIds) {
    final firstSelectedIndex = _flowDataSource.getIndexByRowId(
      selectedIds.first,
    );

    // remove from state and mitm backend
    ref.read(flowsProvider.notifier).removeFlows(selectedIds);
    for (final id in selectedIds) {
      MitmproxyClient.deleteFlow(id);
    }

    if (_flowDataSource.effectiveRows.isEmpty) {
      widget.controller.clearSelection();
      widget.controller.updateFocusedRow(null);
      return;
    }

    // set selected to same index after deletion, or last if index out of range(if not items after deletion)
    final newFirstFlowId =
        _flowDataSource.effectiveRows.length > firstSelectedIndex
        ? _flowDataSource.effectiveRows[firstSelectedIndex].id
        : _flowDataSource
              .effectiveRows[_flowDataSource.effectiveRows.length - 1]
              .id;
    widget.controller.updateFocusedRow(newFirstFlowId);
    widget.controller.setSelectedRows({newFirstFlowId});
  }

  void repeatRequests(Set<String> selectedIds) {
    for (final id in selectedIds) {
      MitmproxyClient.replay(id);
    }
  }

  void markSelected(Set<String> selectedIds, MarkCircle mark) {
    for (final id in selectedIds) {
      _log.info("Marking flow $id as ${mark.name}");
      MitmproxyClient.markFlow(id, mark);
    }
  }

  void copyUrls(Set<String> selectedIds) {
    final urls = selectedIds
        .map((id) => ref.read(flowsProvider)[id]?.url)
        .whereType<String>()
        .join('\n\n');
    _log.info("copyUrls: $urls");
    Clipboard.setData(ClipboardData(text: urls));
  }

  void copyExport(String id, [RequestExport exportType = RequestExport.curl]) {
    MitmproxyClient.getExportReq(id, exportType).then((result) {
      Clipboard.setData(ClipboardData(text: result));
    });
  }

  void copyExports(
    Set<String> id, [
    RequestExport exportType = RequestExport.curl,
  ]) async {
    final futures = id.map((flowId) {
      return MitmproxyClient.getExportReq(flowId, exportType);
    });
    final String str = (await Future.wait(futures)).join('\n\n\n');
    _log.info("copyExports: $str");
    Clipboard.setData(ClipboardData(text: str));
  }

  void revertChanges(Iterable<String> selectedIds) {
    for (final id in selectedIds) {
      MitmproxyClient.revertChanges(id);
    }
  }

  void duplicateFlows(Set<String> selectedIds) {
    for (final id in selectedIds) {
      MitmproxyClient.duplicateFlow(id);
    }
  }

  void resumeIntercept(String flowId, String oldState) {
    ref.read(flowsProvider.notifier).updateFlowState(flowId, oldState);
    MitmproxyClient.resumeIntercept(flowId);
  }

  void compare(Set<String> selectedIds) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: HttpCompareWrapper(
            id1: selectedIds.first,
            id2: selectedIds.last,
          ),
        );
      },
    );
  }
}
