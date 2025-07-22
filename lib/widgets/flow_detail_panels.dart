import 'package:flutter/material.dart';
import 'package:mitmui/widgets/flow_detail_panel_abstract.dart';

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
