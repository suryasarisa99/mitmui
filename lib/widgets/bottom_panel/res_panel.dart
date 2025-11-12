import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitmui/store/derrived_flows_provider.dart';
import 'package:mitmui/widgets/bottom_panel/items_view.dart';
import 'package:mitmui/widgets/bottom_panel/panel_abstract.dart';
import 'package:mitmui/widgets/bottom_panel/panel_titles.dart';

class ResPanelTitles extends AbstractPanelTitles {
  const ResPanelTitles({
    super.key,
    required super.id,
    required super.tabController,
  });

  @override
  List<String> buildTabLabels(WidgetRef ref, String id) {
    final headerCount = ref.watch(
      responseHeadersProvider(id).select((l) => l?.length ?? 0),
    );

    return [
      "Headers ($headerCount)",
      // "Set-Cookies ($cookieCount)",
      "Body",
      // "Raw",
    ];
  }
}

class ResponsePanel extends PanelAbstract {
  const ResponsePanel({
    required super.resizeController,
    required super.id,
    super.key,
  });

  @override
  PanelAbstractState createState() => _ResponsePanelState();
}

class _ResponsePanelState extends PanelAbstractState {
  @override
  get tabsLen => 4;

  @override
  get title => "response";

  @override
  get panelTitles =>
      ResPanelTitles(id: widget.id, tabController: tabController);

  @override
  int get previewBodyTabIndex => 3; // Preview body is at index 3

  @override
  List<Widget> buildViews() {
    return [
      ResHeadersView(
        id: widget.id,
        title: "Headers",
        keyValueJoiner: ":",
        linesJoiner: "\n",
      ),
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
