import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:mitmui/api/mitmproxy_client.dart';
import 'package:mitmui/models/flow.dart';
import 'package:mitmui/store/flows_provider.dart';
import 'package:mitmui/utils/logger.dart';
import 'package:mitmui/utils/query_params_utils.dart';
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
    debugPrint("======Request Detail Panel Updated======");

    queryParams = getQueryParamsList();
    cookies = getCookiesList();
    headers = widget.flow?.request?.headers ?? [];

    tabTitles = [
      // if (headers.isNotEmpty) 'Headers (${headers.length})',
      // if (queryParams.isNotEmpty) 'Query (${queryParams.length})',
      // if (cookies.isNotEmpty) 'Cookies (${cookies.length})',
      'Headers (${headers.length})',
      'Query (${queryParams.length})',
      'Cookies (${cookies.length})',
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
                // if (headers.isNotEmpty)
                buildEditableHeaders(),
                // buildItems(
                //   items: queryParams,
                //   title: 'Query Parameters',
                //   keyValueJoiner: '=',
                //   linesJoiner: '&',
                // ),
                buildEditableQueryParams(),
                // if (cookies.isNotEmpty)
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

  List<List<String>> getFilteredHeaders([List<bool>? e]) {
    final enabled = e ?? widget.flow?.request?.enabledHeaders;
    // only keep checked and header with non empty key
    if (enabled == null) {
      return headers.where((header) => header[0].isNotEmpty).toList();
    } else {
      return [
        for (final (i, header) in headers.indexed)
          if (enabled[i] && header[0].isNotEmpty) header,
      ];
    }
  }

  List<List<String>> getFilteredQueryParams([List<bool>? e]) {
    // final enabled =
    //     widget.flow?.request?.enabledQueryParams ??
    //     List.filled(queryParams.length, true);
    final enabled = e ?? widget.flow?.request?.enabledQueryParams;
    // if (enabledQueryParams == null) return queryParams;
    // only keep checked and query param with non empty key
    if (enabled == null) {
      return queryParams.where((param) => param[0].isNotEmpty).toList();
    }
    return [
      for (final (i, param) in queryParams.indexed)
        if (enabled[i] && param[0].isNotEmpty) param,
    ];
  }

  void updateReq(HttpRequest Function(HttpRequest req) update) {
    ref
        .watch(flowsProvider.notifier)
        .addOrUpdateFlow(widget.flow!.copyWithRequest(update));
  }

  Widget buildEditableQueryParams() {
    debugPrint(
      "rebuilding editable query params: ${widget.flow?.request?.enabledQueryParams}",
    );
    final enabled =
        widget.flow?.request?.enabledQueryParams ??
        List.filled(queryParams.length, true, growable: true);
    return buildInputItems(
      title: 'Query Parameters',
      items: queryParams,
      enabledStates: enabled,
      keyValueJoiner: '=',
      linesJoiner: '&',
      onItemAdded: (item, index) {},
      onItemChanged: (index, key, value) {
        if (index < queryParams.length) {
          queryParams[index] = [key, value];
        }
        final params = QueryParamsUtils.buildQueryParamsString(
          getFilteredQueryParams(),
        );
        final path =
            widget.flow!.request!.path.split('?')[0] +
            (params.isNotEmpty ? '?$params' : '');
        debugPrint("updated path: $path");
        updateReq((r) => r.copyWith(path: path));
        MitmproxyClient.updatePath(widget.flow!.id, path);
      },
      onItemToggled: (index, v) {
        var enabled = widget.flow!.request!.enabledQueryParams;
        enabled ??= List.filled(queryParams.length, true, growable: true);
        enabled[index] = v;
        updateReq((r) => r.copyWith(enabledQueryParams: enabled));
        MitmproxyClient.updatePath(
          widget.flow!.id,
          QueryParamsUtils.buildPath(
            widget.flow!.request!.path.split('?')[0],
            getFilteredQueryParams(enabled),
          ),
        );
      },
      onItemReordered: (oldIndex, newIndex) {},
    );
  }

  Widget buildEditableHeaders() {
    final enabledHeaders =
        widget.flow?.request?.enabledHeaders ??
        List.filled(headers.length, true, growable: true);

    return buildInputItems(
      title: 'Headers',
      items: headers,
      enabledStates: enabledHeaders,
      keyValueJoiner: ': ',
      linesJoiner: '\n',
      onItemAdded: (item, index) {
        debugPrint("header added: $item at index $index");
        // ref.read(flowsProvider.notifier).addHeader(widget.flow!.id, item, true);
      },
      onItemChanged: (index, key, value) {
        debugPrint(
          "header changed at index $index: $key: $value | len ${headers.length} ${enabledHeaders.length}",
        );
        if (index < headers.length) {
          headers[index] = [key, value];
        }
        ref
            .read(flowsProvider.notifier)
            .updateHeader(widget.flow!.id, index, key, value);

        MitmproxyClient.updateHeaders(widget.flow!.id, getFilteredHeaders());
      },
      onItemToggled: (index, v) {
        var enabledHeaders = widget.flow!.request!.enabledHeaders;
        enabledHeaders ??= List.filled(headers.length, true, growable: true);
        enabledHeaders[index] = v;
        debugPrint("enabledHeaders: $enabledHeaders");
        updateReq((r) => r.copyWith(enabledHeaders: enabledHeaders));
        MitmproxyClient.updateHeaders(
          widget.flow!.id,
          getFilteredHeaders(enabledHeaders),
        );
      },
      onItemReordered: (oldIndex, newIndex) {
        if (oldIndex < newIndex) {
          newIndex -= 1;
        }
        final item = headers.removeAt(oldIndex);
        headers.insert(newIndex, item);
        MitmproxyClient.updateHeaders(widget.flow!.id, getFilteredHeaders());
        updateReq((r) => r.copyWith(headers: headers));
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
    return QueryParamsUtils.getQueryParamsList(widget.flow);
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
