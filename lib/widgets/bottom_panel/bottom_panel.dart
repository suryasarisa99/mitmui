import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitmui/dt_table/dt_table.dart';
import 'package:mitmui/theme.dart';
import 'package:mitmui/utils/logger.dart';
import 'package:mitmui/widgets/bottom_panel/flow_detail_url.dart';
import 'package:mitmui/widgets/bottom_panel/panel_abstract.dart';
import 'package:mitmui/widgets/bottom_panel/req_panel.dart';
import 'package:mitmui/widgets/bottom_panel/res_panel.dart';
import 'package:mitmui/widgets/resize.dart';

const _log = Logger("bottom_panel");

class BottomPanel extends ConsumerStatefulWidget {
  const BottomPanel({
    required this.dtController,
    required this.flowId,
    super.key,
  });
  final DtController dtController;
  final ValueNotifier<String?> flowId;

  @override
  ConsumerState<BottomPanel> createState() => _BottomPanelState();
}

class _BottomPanelState extends ConsumerState<BottomPanel> {
  late String? flowId = widget.flowId.value;
  final resizeController = ResizableController();

  @override
  void initState() {
    super.initState();
    widget.flowId.addListener(flowIdListener);
  }

  void flowIdListener() {
    setState(() {
      flowId = widget.flowId.value;
    });
  }

  @override
  void dispose() {
    widget.flowId.removeListener(flowIdListener);
    super.dispose();
  }

  void onOpenInNewWindow(String id) async {}

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.from(Theme.brightnessOf(context));
    if (flowId == null) {
      return const SizedBox.shrink();
    }
    return Container(
      color: theme.surface,
      // color: Colors.red,
      width: double.infinity,
      child: Column(
        children: [
          FlowDetailURL(
            id: flowId!,
            onOpenInNewWindow: () => onOpenInNewWindow(flowId!),
          ),
          Expanded(
            child: ResizableContainer(
              controller: resizeController,
              axis: Axis.horizontal,
              dividerColor: Colors.grey[800]!,
              onDragDividerWidth: 2,
              onDragDividerColor: const Color.fromARGB(255, 105, 93, 92),
              child1: RequestPanel(
                resizeController: resizeController,
                id: flowId!,
              ),
              child2: ResponsePanel(
                resizeController: resizeController,
                id: flowId!,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// class BottomPanelAsFullScreen extends StatefulWidget {
//   final Map<String, dynamic> args;
//   const BottomPanelAsFullScreen({required this.args, super.key});

//   @override
//   State<BottomPanelAsFullScreen> createState() =>
//       _BottomPanelAsFullScreenState();
// }

// class _BottomPanelAsFullScreenState extends State<BottomPanelAsFullScreen> {
//   late final MitmFlow selectedFlow;

//   @override
//   void initState() {
//     super.initState();
//     _log.info('Selected flow: ${widget.args['args2']}');
//     selectedFlow = MitmFlow.fromJson(jsonDecode(widget.args['args2']['flow']));
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         FlowDetailURL(
//           scheme: selectedFlow.request?.scheme ?? '',
//           host: selectedFlow.request?.prettyHost ?? '',
//           path: selectedFlow.request?.path ?? '',
//           statusCode: selectedFlow.response?.statusCode ?? 0,
//           method: selectedFlow.request?.method ?? '',
//           onOpenInNewWindow: () => {},
//         ),
//         Expanded(
//           child: ResizableContainer(
//             axis: Axis.horizontal,
//             child1: RequestDetailsPanel(
//               flow: selectedFlow,
//               resizeController: ResizableController(),
//             ),
//             child2: ResponseDetailsPanel(
//               flow: selectedFlow,
//               resizeController: ResizableController(),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
