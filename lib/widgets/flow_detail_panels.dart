import 'dart:convert';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitmui/dt_table/dt_table.dart';
import 'package:mitmui/dt_table/dt_models.dart';
import 'package:mitmui/models/flow.dart';
import 'package:mitmui/widgets/resize.dart';
import 'package:mitmui/store/flows_provider.dart';
import 'package:mitmui/theme.dart';
import 'package:mitmui/utils/logger.dart';
import 'package:mitmui/widgets/flow_detail_panel_abstract.dart';
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

class BottomPannel extends ConsumerStatefulWidget {
  const BottomPannel({required this.dtController, super.key});
  final DtController dtController;

  @override
  ConsumerState<BottomPannel> createState() => _BottomPannelState();
}

class _BottomPannelState extends ConsumerState<BottomPannel> {
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
    return SizedBox(
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

class RequestDetailsPanel extends DetailsPanel {
  const RequestDetailsPanel({
    required super.resizeController,
    super.flow,
    super.key,
  });

  @override
  DetailsPanelState createState() => _RequestDetailsPanelState();
}

class _RequestDetailsPanelState extends DetailsPanelState {
  @override
  String title = 'Request';
  @override
  late List<String> tabTitles;
  @override
  late int tabsLen;

  late List<List<String>> queryParams;
  late List<List<String>> cookies;
  late List<List<String>> headers;

  @override
  void updateData() {
    queryParams = getQueryParamsList();
    cookies = getCookiesList();
    headers = widget.flow?.request?.headers ?? [];

    tabTitles = [
      if (headers.isNotEmpty) 'Headers (${headers.length})',
      if (queryParams.isNotEmpty) 'Query (${queryParams.length})',
      if (cookies.isNotEmpty) 'Cookies (${cookies.length})',
      'Body',
      'Raw',
    ];
    tabsLen = tabTitles.length;
  }

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
                if (headers.isNotEmpty)
                  buildItems(
                    items: headers,
                    title: 'Headers',
                    keyValueJoiner: ': ',
                    linesJoiner: '\n',
                  ),
                if (queryParams.isNotEmpty)
                  buildItems(
                    items: queryParams,
                    title: 'Query Parameters',
                    keyValueJoiner: '=',
                    linesJoiner: '&',
                  ),
                if (cookies.isNotEmpty)
                  buildItems(
                    items: cookies,
                    title: 'Cookies',
                    keyValueJoiner: '=',
                    linesJoiner: '; ',
                  ),
                buildBody(),
                buildRaw(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<List<String>> getCookiesList() {
    final cookieHeader = widget.flow?.request?.getHeader('cookie');
    if (cookieHeader == null || cookieHeader.isEmpty) return [];
    return (cookieHeader.endsWith(';')
            ? cookieHeader.substring(0, cookieHeader.length - 1)
            : cookieHeader)
        .split(';')
        .map((cookie) {
          final parts = cookie.split('=');
          return [parts[0].trim(), parts.length > 1 ? parts[1].trim() : ''];
        })
        .toList();
  }

  List<List<String>> getQueryParamsList() {
    final pathList = widget.flow?.request?.path.split('?') ?? [];
    if (pathList.length < 2) return [];
    final queryParams = pathList[1];
    if (queryParams.isEmpty) [];
    return queryParams.split('&').map((e) {
      final parts = e.split('=');
      return [parts[0], parts.length > 1 ? parts[1] : ''];
    }).toList();
  }
}

class ResponseDetailsPanel extends DetailsPanel {
  const ResponseDetailsPanel({
    required super.resizeController,
    super.flow,
    super.key,
  });

  @override
  DetailsPanelState createState() => _ResponseDetailsPanelState();
}

class _ResponseDetailsPanelState extends DetailsPanelState {
  @override
  String title = 'Response';
  @override
  late List<String> tabTitles;
  @override
  late int tabsLen;

  late List<List<String>> cookies;
  late List<List<String>> headers;

  @override
  updateData() {
    cookies = getCookiesList();
    headers = widget.flow?.response?.headers ?? [];

    tabTitles = [
      if (headers.isNotEmpty) 'Headers (${headers.length})',
      if (cookies.isNotEmpty) 'Cookies (${cookies.length})',
      'Body',
      'Raw',
    ];
    tabsLen = tabTitles.length;
  }

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
                if (headers.isNotEmpty)
                  buildItems(
                    items: headers,
                    title: 'Headers',
                    keyValueJoiner: ': ',
                    linesJoiner: '\n',
                  ),
                if (cookies.isNotEmpty)
                  buildItems(
                    items: cookies,
                    title: 'Cookies',
                    keyValueJoiner: '=',
                    linesJoiner: '; ',
                  ),
                buildBody(),
                buildRaw(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<List<String>> getCookiesList() {
    final cookieHeader = widget.flow?.response?.getHeader('set-cookie');
    if (cookieHeader == null || cookieHeader.isEmpty) return [];
    return cookieHeader.split(';').map((cookie) {
      final parts = cookie.split('=');
      return [parts[0].trim(), parts.length > 1 ? parts[1].trim() : ''];
    }).toList();
  }
}
