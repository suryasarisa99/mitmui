import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitmui/store/derrived_flows_provider.dart';
import 'package:mitmui/widgets/bottom_panel/edit_views.dart';
import 'package:mitmui/widgets/bottom_panel/items_view.dart';
import 'package:mitmui/widgets/bottom_panel/panel_abstract.dart';
import 'package:mitmui/widgets/bottom_panel/panel_titles.dart';

class ReqPanelTitles extends AbstractPanelTitles {
  const ReqPanelTitles({
    super.key,
    required super.id,
    required super.tabController,
  });

  @override
  List<String> buildTabLabels(WidgetRef ref, String id) {
    final headerCount = ref.watch(
      headersProvider(id).select((l) => l?.length ?? 0),
    );
    final queryCount = ref.watch(
      parsedQueryProvider(id).select((l) => l.length),
    );
    final cookieCount = ref.watch(
      parsedCookiesProvider(id).select((l) => l.length),
    );

    return [
      "Headers ($headerCount)",
      "Query ($queryCount)",
      "Cookies ($cookieCount)",
      "Body",
      // "Raw",
    ];
  }
}

class RequestPanel extends PanelAbstract {
  const RequestPanel({
    required super.resizeController,
    required super.id,
    super.key,
  });

  @override
  PanelAbstractState createState() => _RequestPanelState();
}

class _RequestPanelState extends PanelAbstractState {
  @override
  get tabsLen => 4;

  @override
  get title => "request";

  @override
  get panelTitles =>
      ReqPanelTitles(id: widget.id, tabController: tabController);

  @override
  int get previewBodyTabIndex => 3; // Preview body is at index 3

  @override
  List<Widget> buildViews() {
    return [
      // ReqHeadersView(
      //   id: widget.id,
      //   title: "Headers",
      //   keyValueJoiner: ":",
      //   linesJoiner: "\n",
      // ),
      EditHeadersView(id: widget.id),
      // QueryView(
      //   id: widget.id,
      //   title: "Query",
      //   keyValueJoiner: "=",
      //   linesJoiner: "&",
      // ),
      EditQueryParams(id: widget.id),
      CookiesView(
        id: widget.id,
        title: "Cookies",
        keyValueJoiner: "=",
        linesJoiner: "; ",
      ),
      buildPreviewBody(), // Use helper method
    ];
  }
}
