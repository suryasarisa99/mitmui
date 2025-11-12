import 'package:flutter/material.dart';
import 'package:mitmui/widgets/bottom_panel/items_view.dart';
import 'package:mitmui/widgets/bottom_panel/panel_header.dart';
import 'package:mitmui/widgets/bottom_panel/panel_titles.dart';
import 'package:mitmui/services/code_controller_service.dart';
import 'package:mitmui/widgets/keep_alive.dart';
import 'package:mitmui/widgets/preview_body.dart';
import 'package:mitmui/widgets/resize.dart';

abstract class PanelAbstract extends StatefulWidget {
  const PanelAbstract({
    required this.resizeController,
    required this.id,
    super.key,
  });
  final ResizableController resizeController;
  final String id;

  @override
  State<PanelAbstract> createState();
}

abstract class PanelAbstractState extends State<PanelAbstract>
    with SingleTickerProviderStateMixin {
  // need to implement in subclasses
  int get tabsLen;
  String get title;
  AbstractPanelTitles get panelTitles;
  List<Widget> buildViews();
  int get previewBodyTabIndex; // Add this to specify which tab is preview body

  //declarations
  late final codeControllerService = CodeControllerService(title);
  late TabController tabController = TabController(
    length: tabsLen,
    vsync: this,
  );

  // Key for accessing PreviewBody state
  final GlobalKey<PreviewBodyState> _previewBodyKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Listen to tab changes
    tabController.addListener(_onTabChanged);
    codeControllerService.flowId = widget.id;
  }

  void _onTabChanged() {
    final previewBodyState = _previewBodyKey.currentState;
    if (previewBodyState == null) return;

    // Enable/disable listening based on whether we're on preview body tab
    if (tabController.index == previewBodyTabIndex) {
      previewBodyState.resumeListening();
    } else {
      previewBodyState.pauseListening();
    }
  }

  @override
  void didUpdateWidget(covariant PanelAbstract oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      codeControllerService.flowId = widget.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PanelHeader(
          codeControllerService: codeControllerService,
          resizeController: widget.resizeController,
          tabController: tabController,
          id: widget.id,
          title: title,
          // panelTabsBuilder: (id, t) => panelTitles,
          panelTabs: panelTitles,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8),
            child: TabBarView(
              key: ValueKey(widget.id),
              controller: tabController,
              children: buildViews(),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    tabController.removeListener(_onTabChanged);
    tabController.dispose();
    super.dispose();
  }

  // Helper method to create PreviewBody with key
  Widget buildPreviewBody() {
    return KeepAliveWrapper(
      child: PreviewBody(
        key: _previewBodyKey,
        id: widget.id,
        type: title,
        codeControllerService: codeControllerService,
      ),
    );
  }
}
