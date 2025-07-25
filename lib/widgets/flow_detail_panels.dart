import 'dart:convert';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitmui/dt_table/dt_table.dart';
import 'package:mitmui/dt_table/dt_models.dart';
import 'package:mitmui/models/flow.dart';
import 'package:mitmui/store/flows_provider.dart';
import 'package:mitmui/utils/logger.dart';
import 'package:mitmui/widgets/flow_detail_panel_abstract.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:mitmui/widgets/flow_detail_url.dart';

const _log = Logger("flow_detail_panels");

class BottomPannelAsFullScreen extends StatefulWidget {
  final Map<String, dynamic> args;
  const BottomPannelAsFullScreen({required this.args, super.key});

  @override
  State<BottomPannelAsFullScreen> createState() =>
      _BottomPannelAsFullScreenState();
}

class _BottomPannelAsFullScreenState extends State<BottomPannelAsFullScreen> {
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
          scheme: selectedFlow.request.scheme,
          host: selectedFlow.request.prettyHost ?? '',
          path: selectedFlow.request.path,
          statusCode: selectedFlow.response?.statusCode ?? 0,
          method: selectedFlow.request.method,
        ),
        Expanded(
          child: ResizableContainer(
            children: [
              // selected flow request summary
              ResizableChild(
                divider: ResizableDivider(
                  thickness: 1.0,
                  padding: 18,
                  color: const Color.fromARGB(255, 56, 57, 63),
                ),
                child: RequestDetailsPanel(flow: selectedFlow),
              ),
              // selected flow response summary
              ResizableChild(child: ResponseDetailsPanel(flow: selectedFlow)),
            ],
            direction: Axis.horizontal,
          ),
        ),
      ],
    );
  }
}

class BottomPannel extends ConsumerStatefulWidget {
  const BottomPannel({required this.dtController, super.key});
  final DtController dtController;

  @override
  ConsumerState<BottomPannel> createState() => _BottomPannelState();
}

class _BottomPannelState extends ConsumerState<BottomPannel> {
  String? flowId;

  @override
  void initState() {
    super.initState();
    widget.dtController.addSpecificListener(_listener);
  }

  void _listener(DtControllerChange change) {
    if (change.type == ChangeType.focusedRow) {
      int? flowRowId = int.tryParse(widget.dtController.focusedRowId ?? '');
      if (flowRowId != null) {
        setState(() {
          flowId = ref.read(flowsProvider.notifier).flows[flowRowId].id;
        });
      }
    }
  }

  @override
  void dispose() {
    // widget.dataGridController.removeSpecificListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print("Building BottomPannel with flowId: $flowId");
    if (flowId == null) {
      return const SizedBox.shrink();
    }
    // final selectedFlow = ref.watch(selectedFlowProvider(flowId!));
    final selectedFlow = ref.watch(
      flowsProvider.select((flows) => flows[flowId!]),
    );
    // final selectedFlow = ref.watch(flowsProvider)[flowId!];
    if (selectedFlow == null) {
      _log.error('Selected flow not found for ID: $flowId');
      return Container(
        width: double.infinity,
        height: 50,
        child: Center(child: Text('Flow not found for ID: $flowId')),
      );
    }
    _log.success('Selected flow: ${selectedFlow.id}');
    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 40,
            child: TextButton(
              onPressed: () async {
                final window = await DesktopMultiWindow.createWindow(
                  jsonEncode({
                    'args1': 'Sub window',
                    'args2': {'flow': jsonEncode(selectedFlow.toJson())},
                  }),
                );
                window
                  ..setFrame(const Offset(0, 0) & const Size(1280, 720))
                  ..center()
                  ..setTitle('Another window')
                  ..show();
              },
              child: Text("sep"),
            ),
          ),
          SizedBox(width: 8.0),
          FlowDetailURL(
            scheme: selectedFlow.request.scheme,
            host: selectedFlow.request.prettyHost ?? '',
            path: selectedFlow.request.path,
            statusCode: selectedFlow.response?.statusCode ?? 0,
            method: selectedFlow.request.method,
          ),
          Expanded(
            child: ResizableContainer(
              children: [
                // selected flow request summary
                ResizableChild(
                  divider: ResizableDivider(
                    thickness: 1.0,
                    padding: 18,
                    color: const Color.fromARGB(255, 56, 57, 63),
                  ),
                  child: RequestDetailsPanel(flow: selectedFlow),
                ),
                // selected flow response summary
                ResizableChild(child: ResponseDetailsPanel(flow: selectedFlow)),
              ],
              direction: Axis.horizontal,
            ),
          ),
        ],
      ),
    );
  }
}

class RequestDetailsPanel extends DetailsPanel {
  const RequestDetailsPanel({super.flow, super.key});

  @override
  DetailsPanelState createState() => _RequestDetailsPanelState();
}

class _RequestDetailsPanelState extends DetailsPanelState {
  @override
  String title = 'Request';
  @override
  List<String> tabTitles = [
    'Headers',
    'Query Params',
    'Cookies',
    'Body',
    'raw',
  ];
  @override
  late int tabsLen = tabTitles.length;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        buildHeader(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8),
            child: TabBarView(
              controller: tabController,
              children: [
                buildHeaders(),
                buildQueryParams(),
                buildCookies(),
                buildBody(),
                buildRaw(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget buildHeaders() {
    final headers = widget.flow?.request.headers ?? [];
    return buildItems(
      items: headers,
      title: 'Headers',
      keyValueJoiner: ': ',
      linesJoiner: '\n',
    );
  }

  Widget buildQueryParams() {
    final pathList = widget.flow?.request.path.split('?') ?? [];
    if (pathList.length < 2) {
      return SizedBox.shrink();
    }
    final queryParams = pathList[1];
    if (queryParams.isEmpty) return SizedBox.shrink();
    final params = queryParams.split('&').map((e) {
      final parts = e.split('=');
      return [parts[0], parts.length > 1 ? parts[1] : ''];
    }).toList();
    return buildItems(
      items: params,
      title: 'Query Parameters',
      keyValueJoiner: '=',
      linesJoiner: '&',
    );
  }

  Widget buildCookies() {
    final cookieHeader = widget.flow?.request.headers.firstWhere(
      (header) => header[0].toLowerCase() == 'cookie',
      orElse: () => ['cookie', ''],
    )[1];
    if (cookieHeader == null || cookieHeader.isEmpty) {
      return SizedBox.shrink();
    }
    final cookies = cookieHeader.split(';').map((cookie) {
      final parts = cookie.split('=');
      return [parts[0].trim(), parts.length > 1 ? parts[1].trim() : ''];
    }).toList();
    return buildItems(
      items: cookies,
      title: 'Cookies',
      keyValueJoiner: '=',
      linesJoiner: '; ',
    );
  }
}

class ResponseDetailsPanel extends DetailsPanel {
  const ResponseDetailsPanel({super.flow, super.key});

  @override
  DetailsPanelState createState() => _ResponseDetailsPanelState();
}

class _ResponseDetailsPanelState extends DetailsPanelState {
  @override
  String title = 'Response';
  @override
  List<String> tabTitles = ['Headers', 'Cookies', 'Body', 'Raw'];
  @override
  late int tabsLen = tabTitles.length;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        buildHeader(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0),
            child: TabBarView(
              controller: tabController,
              children: [
                buildHeaders(),
                buildCookies(),
                buildBody(),
                buildRaw(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget buildHeaders() {
    final headers = widget.flow?.response?.headers ?? [];
    return buildItems(
      items: headers,
      title: 'Headers',
      keyValueJoiner: ': ',
      linesJoiner: '\n',
    );
  }

  Widget buildCookies() {
    final cookieHeader = widget.flow?.response?.headers.firstWhere(
      (header) => header[0].toLowerCase() == 'set-cookie',
      orElse: () => ['set-cookie', ''],
    )[1];
    if (cookieHeader == null || cookieHeader.isEmpty) {
      return SizedBox.shrink();
    }
    final cookies = cookieHeader.split(';').map((cookie) {
      final parts = cookie.split('=');
      return [parts[0].trim(), parts.length > 1 ? parts[1].trim() : ''];
    }).toList();
    return buildItems(
      items: cookies,
      title: 'Cookies',
      keyValueJoiner: '=',
      linesJoiner: '; ',
    );
  }
}
