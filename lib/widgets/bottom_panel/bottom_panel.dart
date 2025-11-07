import 'dart:convert';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitmui/dt_table/dt_models.dart';
import 'package:mitmui/dt_table/dt_table.dart';
import 'package:mitmui/models/flow.dart';
import 'package:mitmui/store/flows_provider.dart';
import 'package:mitmui/theme.dart';
import 'package:mitmui/utils/logger.dart';
import 'package:mitmui/widgets/bottom_panel/flow_detail_panels.dart';
import 'package:mitmui/widgets/bottom_panel/flow_detail_url.dart';
import 'package:mitmui/widgets/resize.dart';

const _log = Logger("bottom_panel");

class BottomPanel extends ConsumerStatefulWidget {
  const BottomPanel({required this.dtController, super.key});
  final DtController dtController;

  @override
  ConsumerState<BottomPanel> createState() => _BottomPanelState();
}

class _BottomPanelState extends ConsumerState<BottomPanel> {
  String? flowId;
  final resizeController = ResizableController();

  @override
  void initState() {
    super.initState();
    widget.dtController.addSpecificListener(_listener);
  }

  void _listener(DtControllerChange change) {
    if (change.type == ChangeType.focusedRow) {
      String? rowId = widget.dtController.focusedRowId;
      if (rowId != null && rowId != flowId) {
        final x = ref.read(flowsProvider)[rowId];
        if (x == null) return;
        setState(() {
          flowId = x.id;
        });
      }
    }
  }

  @override
  void dispose() {
    // widget.dataGridController.removeSpecificListener();
    super.dispose();
  }

  void onOpenInNewWindow(MitmFlow flow) async {
    final window = await DesktopMultiWindow.createWindow(
      jsonEncode({
        'args1': 'Sub window',
        'args2': {'flow': jsonEncode(flow.toJson())},
      }),
    );
    window
      ..setFrame(const Offset(0, 0) & const Size(1280, 720))
      ..center()
      ..setTitle('Another window')
      ..show();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.from(Theme.brightnessOf(context));
    if (flowId == null) {
      return const SizedBox.shrink();
    }
    // final selectedFlow = ref.watch(selectedFlowProvider(flowId!));
    final selectedFlow = ref.watch(
      flowsProvider.select((flows) => flows[flowId!]),
    );
    // final selectedFlow = ref.watch(flowsProvider)[flowId!];
    if (selectedFlow == null) {
      return const SizedBox.shrink();
    }
    _log.success("rebuilding flow details for ${selectedFlow.id}");
    return Container(
      color: theme.surface,
      // color: Colors.red,
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FlowDetailURL(
            scheme: selectedFlow.request?.scheme ?? '',
            host: selectedFlow.request?.prettyHost ?? '',
            path: selectedFlow.request?.path ?? '',
            statusCode: selectedFlow.response?.statusCode ?? 0,
            method: selectedFlow.request?.method ?? '',
            onOpenInNewWindow: () => onOpenInNewWindow(selectedFlow),
          ),
          if (selectedFlow.request != null)
            Expanded(
              child: ResizableContainer(
                controller: resizeController,
                axis: Axis.horizontal,
                dividerColor: Colors.grey[800]!,
                onDragDividerWidth: 2,
                onDragDividerColor: const Color.fromARGB(255, 105, 93, 92),
                child1: RequestDetailsPanel(
                  flow: selectedFlow,
                  resizeController: resizeController,
                ),
                child2: ResponseDetailsPanel(
                  flow: selectedFlow,
                  resizeController: resizeController,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class BottomPanelAsFullScreen extends StatefulWidget {
  final Map<String, dynamic> args;
  const BottomPanelAsFullScreen({required this.args, super.key});

  @override
  State<BottomPanelAsFullScreen> createState() =>
      _BottomPanelAsFullScreenState();
}

class _BottomPanelAsFullScreenState extends State<BottomPanelAsFullScreen> {
  late final MitmFlow selectedFlow;

  @override
  void initState() {
    super.initState();
    _log.info('Selected flow: ${widget.args['args2']}');
    selectedFlow = MitmFlow.fromJson(jsonDecode(widget.args['args2']['flow']));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FlowDetailURL(
          scheme: selectedFlow.request?.scheme ?? '',
          host: selectedFlow.request?.prettyHost ?? '',
          path: selectedFlow.request?.path ?? '',
          statusCode: selectedFlow.response?.statusCode ?? 0,
          method: selectedFlow.request?.method ?? '',
          onOpenInNewWindow: () => {},
        ),
        Expanded(
          child: ResizableContainer(
            axis: Axis.horizontal,
            child1: RequestDetailsPanel(
              flow: selectedFlow,
              resizeController: ResizableController(),
            ),
            child2: ResponseDetailsPanel(
              flow: selectedFlow,
              resizeController: ResizableController(),
            ),
          ),
        ),
      ],
    );
  }
}
