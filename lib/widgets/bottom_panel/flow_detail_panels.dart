import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:mitmui/api/mitmproxy_client.dart';
import 'package:mitmui/models/flow.dart';
import 'package:mitmui/store/flows_provider.dart';
import 'package:mitmui/utils/logger.dart';
import 'package:mitmui/widgets/bottom_panel/flow_detail_panel_abstract.dart';

const _log = Logger("flow_detail_panels");

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
    print("======Request Detail Panel Updated======");

    queryParams = getQueryParamsList();
    cookies = getCookiesList();
    headers = widget.flow?.request?.headers ?? [];
    print("Headers count: ${headers.length}: ${headers.first}");

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
    debugPrint("rebuilding request details panel");
    return Column(
      children: [
        buildHeader(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8),
            child: TabBarView(
              controller: tabController,
              children: [
                if (headers.isNotEmpty) buildHeaders(),
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

  // void addHeader() {
  //   final flowsNotifier = ref.read(flowsProvider.notifier);
  //   final newHeader = ['New-Header', ''];
  //   headers.add(newHeader);
  //   flowsNotifier.addHeader(widget.flow!.id, newHeader[0], newHeader[1]);
  //   MitmproxyClient.updateHeaders(widget.flow!.id, headers);
  // }

  List<List<String>> getFilteredHeaders() {
    final enabledHeaders = widget.flow?.request?.enabledHeaders;
    if (enabledHeaders == null) return headers;
    // only keep checked and header with non empty key
    List<List<String>> filteredItems = [
      for (final (i, header) in headers.indexed)
        if (enabledHeaders[i] && header[0].isNotEmpty) header,
    ];
    return filteredItems;
  }

  Widget buildHeaders() {
    return buildInputItems(
      title: 'Headers',
      items: headers,
      enabledStates: widget.flow?.request?.enabledHeaders,
      keyValueJoiner: ': ',
      linesJoiner: '\n',
      onItemAdded: (item, index) {
        ref.read(flowsProvider.notifier).addHeader(widget.flow!.id, item, true);
      },
      onItemChanged: (index, key, value) {
        if (index < headers.length) {
          headers[index] = [key, value];
          ref
              .read(flowsProvider.notifier)
              .updateHeader(widget.flow!.id, index, key, value);

          MitmproxyClient.updateHeaders(widget.flow!.id, getFilteredHeaders());
        } else {
          headers.add([key, value]);
        }
      },
      onItemToggled: (index, v) {
        var enabledHeaders = widget.flow!.request!.enabledHeaders;
        enabledHeaders[index] = v;
        ref
            .read(flowsProvider.notifier)
            .addOrUpdateFlow(
              widget.flow!.copyWith(enabledHeaders: enabledHeaders),
            );
        MitmproxyClient.updateHeaders(widget.flow!.id, getFilteredHeaders());
      },
      onItemReordered: (oldIndex, newIndex) {
        if (oldIndex < newIndex) {
          newIndex -= 1;
        }
        final item = headers.removeAt(oldIndex);
        headers.insert(newIndex, item);
        MitmproxyClient.updateHeaders(widget.flow!.id, getFilteredHeaders());
        ref
            .read(flowsProvider.notifier)
            .addOrUpdateFlow(widget.flow!.copyWith(headers: headers));
      },
    );
  }

  List<List<String>> getCookiesList() {
    final cookiesList = getHeadersByName(
      widget.flow?.request?.headers ?? [],
      'cookie',
    );
    if (cookiesList.isEmpty) return [];
    return cookiesList.expand((cookies) {
      final trimmedCookies = cookies.endsWith(';')
          ? cookies.substring(0, cookies.length - 1)
          : cookies;
      final splited = trimmedCookies.split(';').map((cookie) {
        final parts = cookie.split('=');
        return [parts[0].trim(), parts.length > 1 ? parts[1].trim() : ''];
      });
      return splited;
    }).toList();
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
      if (cookies.isNotEmpty) 'Set-Cookies (${cookies.length})',
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
        if (widget.flow?.response == null)
          Expanded(child: const Center(child: CircularProgressIndicator()))
        else
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
                      title: 'Set-Cookies',
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
    final cookieHeader = getHeadersByName(
      widget.flow?.response?.headers ?? [],
      'set-cookie',
    );
    if (cookieHeader.isEmpty) return [];
    return cookieHeader.map((cookie) {
      final parts = cookie.split(';').first.split('=');
      return [parts[0].trim(), parts.length > 1 ? parts[1].trim() : ''];
    }).toList();
  }
}
