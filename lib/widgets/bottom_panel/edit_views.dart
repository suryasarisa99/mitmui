import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitmui/api/mitmproxy_client.dart';
import 'package:mitmui/store/derrived_flows_provider.dart';
import 'package:mitmui/store/flows_provider.dart';
import 'package:mitmui/utils/query_params_utils.dart';
import 'package:mitmui/utils/ref_extension.dart';
import 'package:mitmui/widgets/bottom_panel/inputs_view.dart';

class EditHeadersView extends ConsumerStatefulWidget {
  final String id;
  const EditHeadersView({super.key, required this.id});

  @override
  ConsumerState<EditHeadersView> createState() => _EditHeadersViewState();
}

class _EditHeadersViewState extends ConsumerState<EditHeadersView> {
  List<List<String>> _items = [];
  List<bool> _enabledItems = [];

  @override
  void initState() {
    super.initState();
    _items = ref.read(headersProvider(widget.id)) ?? [];
    _enabledItems =
        ref.read(flowProvider(widget.id))?.request?.enabledHeaders ??
        List.filled(_items.length, true, growable: true);
  }

  List<List<String>> filterItems() {
    // return _items.where((item) => item[0].isNotEmpty).toList();
    return [
      for (var (i, item) in _items.indexed)
        if (_enabledItems[i] && item[0].isNotEmpty) item,
    ];
  }

  void updateClient() {
    MitmproxyClient.updateHeaders(widget.id, filterItems());
  }

  void onItemChanged(int index, String key, String value) {
    _items[index] = [key, value];
    _enabledItems[index] = true;
    // if (index >= _enabledItems.length) {
    //   _enabledItems.add(true);
    // } else {
    // }
    updateClient();
  }

  void onItemToggled(int index, bool enabled) {
    if (ref.read(flowProvider(widget.id))!.request!.enabledHeaders == null) {
      ref.flowsN.updateEnabledHeaders(widget.id, _enabledItems);
      _enabledItems = ref.flows[widget.id]!.request!.enabledHeaders!;
    }
    _enabledItems[index] = enabled;
    setState(() {});
    updateClient();
  }

  @override
  Widget build(BuildContext context) {
    // final headers = ref.watch(headersProvider(widget.id));

    return InputsView(
      title: "Headers",
      id: widget.id,
      enabled: _enabledItems,
      items: _items,
      onItemToggled: onItemToggled,
      onItemReordered: (a, b) {},
      onItemChanged: onItemChanged,
      onItemAdded: (a, b) {},
      keyValueJoiner: ':',
      linesJoiner: '\n',
    );
  }
}

class EditQueryParams extends ConsumerStatefulWidget {
  final String id;
  const EditQueryParams({super.key, required this.id});

  @override
  ConsumerState<EditQueryParams> createState() => _EditQueryParamsState();
}

class _EditQueryParamsState extends ConsumerState<EditQueryParams> {
  List<List<String>> _items = [];
  List<bool> _enabledItems = [];

  @override
  void initState() {
    super.initState();
    _items = ref.read(parsedQueryProvider(widget.id)) ?? [];
    _enabledItems =
        ref.read(flowProvider(widget.id))?.request?.enabledQueryParams ??
        List.filled(_items.length, true, growable: true);
  }

  String getPath() {
    // return _items.where((item) => item[0].isNotEmpty).toList();
    final filtered = [
      for (var (i, item) in _items.indexed)
        if (_enabledItems[i] && item[0].isNotEmpty) item,
    ];
    return QueryParamsUtils.buildPath(
      ref.flows[widget.id]!.request!.path.split('?')[0],
      filtered,
    );
  }

  void updateClient() {
    MitmproxyClient.updatePath(widget.id, getPath());
  }

  void onItemChanged(int index, String key, String value) {
    _items[index] = [key, value];
    ref.flowsN.updateReq(widget.id, (q) => q.copyWith(path: getPath()));
    updateClient();
  }

  void onItemToggled(int index, bool enabled) {
    _enabledItems[index] = enabled;

    ref.flowsN.updateReq(
      widget.id,
      (q) => q.copyWith(enabledQueryParams: _enabledItems, path: getPath()),
    );

    setState(() {});
    updateClient();
  }

  @override
  Widget build(BuildContext context) {
    // final headers = ref.watch(headersProvider(widget.id));

    return InputsView(
      title: "Query Params",
      id: widget.id,
      enabled: _enabledItems,
      items: _items,
      onItemToggled: onItemToggled,
      onItemReordered: (a, b) {},
      onItemChanged: onItemChanged,
      onItemAdded: (a, b) {},
      keyValueJoiner: ':',
      linesJoiner: '\n',
    );
  }
}
