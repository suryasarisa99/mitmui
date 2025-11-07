import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitmui/api/mitmproxy_client.dart';
import 'package:mitmui/http_docs.dart';
import 'package:mitmui/models/flow.dart' as models;
import 'package:mitmui/models/response_body.dart';
import 'package:mitmui/widgets/input_items.dart';
import 'package:mitmui/widgets/resize.dart';
import 'package:mitmui/utils/statusCode.dart';
import 'package:mitmui/widgets/preview_body.dart';

abstract class DetailsPanel extends ConsumerStatefulWidget {
  final models.MitmFlow? flow;
  final ResizableController resizeController;
  const DetailsPanel({
    required this.resizeController,
    required this.flow,
    super.key,
  });
}

abstract class DetailsPanelState extends ConsumerState<DetailsPanel>
    with TickerProviderStateMixin {
  int get tabsLen;
  List<String> get tabTitles;
  String get title;
  Future<MitmBody>? mitmBodyFuture;

  late TabController tabController;
  bool get isRequest => title == 'Request';
  bool get isResponse => title == 'Response';
  bool get isSinglePanel =>
      widget.resizeController.isChild1Hidden ||
      widget.resizeController.isChild2Hidden;

  void updateData();

  @override
  void initState() {
    super.initState();
    fetchBody();
    updateData();
    tabController = TabController(
      length: tabsLen,
      vsync: this,
      initialIndex: 0, // Default to the first tab
    );
  }

  void fetchBody() {
    final type = title.toLowerCase();
    if (isResponse && widget.flow?.response == null) {
      mitmBodyFuture = null;
    } else {
      mitmBodyFuture = MitmproxyClient.getMitmBody(widget.flow!.id, type);
    }
  }

  @override
  void didUpdateWidget(covariant DetailsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.flow != widget.flow) {
      String? currentTab;
      try {
        currentTab = tabTitles[tabController.index].split(" ")[0];
      } catch (e) {
        currentTab = null;
      }
      updateData();
      if (mitmBodyFuture == null ||
          oldWidget.flow?.id != widget.flow?.id ||
          oldWidget.flow?.request?.timestampStart !=
              widget.flow?.request?.timestampStart) {
        // check timestamps because even flow is same, the request is repeated
        // for more strict require,then check timestampEnd for both request and response as well.
        fetchBody();
      }
      int newIndex = 0; // Default to the first tab
      if (currentTab != null) {
        final foundIndex = tabTitles.indexWhere(
          (title) => title.startsWith(currentTab!),
        );
        if (foundIndex != -1) {
          newIndex = foundIndex;
        }
      }
      tabController.dispose();
      tabController = TabController(
        length: tabsLen,
        vsync: this,
        initialIndex: newIndex, // Set the preserved index
      );
    }
  }

  Widget buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xff161819),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade800, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Request title
          SizedBox(width: 10),
          if (!isSinglePanel)
            Text(
              title,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            )
          else
            _buildToggleButtons(),
          // Flexible(child: _buildToggleButtons()),
          const SizedBox(width: 16),
          // Tab bar for different views
          Expanded(
            child: SizedBox(
              height: 30,
              child: TabBar(
                controller: tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: const Color(0xFFFF7474),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFFFD5A4F),
                labelPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                indicatorPadding: EdgeInsets.symmetric(horizontal: 0.0),
                labelStyle: TextStyle(fontWeight: FontWeight.normal),
                tabs: tabTitles.map((e) => Tab(text: e)).toList(),
              ),
            ),
          ),
          IconButton(
            iconSize: 22,
            splashRadius: 16,
            padding: const EdgeInsets.all(0.0),
            constraints: BoxConstraints(minHeight: 24, minWidth: 24),
            onPressed: () {
              if (isRequest) {
                if (widget.resizeController.isChild2Hidden) {
                  widget.resizeController.showSecondChild();
                } else {
                  widget.resizeController.hideSecondChild();
                }
              } else {
                if (widget.resizeController.isChild1Hidden) {
                  widget.resizeController.showFirstChild();
                } else {
                  widget.resizeController.hideFirstChild();
                }
              }
            },
            icon: Icon(
              isRequest
                  ? (widget.resizeController.isChild1Hidden
                        ? Icons.fullscreen_exit
                        : Icons.fullscreen)
                  : (widget.resizeController.isChild2Hidden
                        ? Icons.fullscreen_exit
                        : Icons.fullscreen),
              color: Colors.grey,
            ),
          ),
          SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildToggleButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Row(
          mainAxisSize: MainAxisSize.min, // Make the row wrap its content
          children: <Widget>[
            _buildToggleButton(
              text: 'Req',
              isSelected: !widget.resizeController.isChild1Hidden,
              onPressed: () {
                widget.resizeController.showFirstChild();
                widget.resizeController.hideSecondChild();
              },
            ),
            _buildToggleButton(
              text: 'Res',
              isSelected: !widget.resizeController.isChild2Hidden,
              onPressed: () {
                widget.resizeController.showSecondChild();
                widget.resizeController.hideFirstChild();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton({
    required String text,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(0),
      child: Container(
        color: isSelected
            ? const Color.fromARGB(205, 238, 76, 26)
            : const Color.fromARGB(197, 66, 66, 66),
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 3.5),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: isSelected ? Colors.white : Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // Headers tab content
  Widget buildItems({
    required List<List<String>> items,
    required String title,
    required String keyValueJoiner,
    required String linesJoiner,
  }) {
    return SelectableRegion(
      selectionControls: MaterialTextSelectionControls(),
      contextMenuBuilder: (context, editableTextState) {
        return AdaptiveTextSelectionToolbar.buttonItems(
          buttonItems: editableTextState.contextMenuButtonItems,
          anchors: editableTextState.contextMenuAnchors,
        );
      },
      child: ListView.builder(
        itemCount: items.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    icon: Icon(Icons.copy, size: 16, color: Colors.grey[400]),
                    tooltip: 'Copy all headers',
                    onPressed: () {
                      final headerText = items
                          .map((h) => '${h[0]}$keyValueJoiner${h[1]}')
                          .join(linesJoiner);
                      Clipboard.setData(ClipboardData(text: headerText));
                    },
                  ),
                ],
              ),
            );
          } else {
            final item = items[index - 1];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 2),
              color: const Color(0xFF23242A),

              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 0.0,
                  horizontal: 8.0,
                ),
                child: Row(
                  children: [
                    if (title.startsWith("Headers")) ...[
                      Tooltip(
                        message: getHeaderDocs(item[0])?.summary ?? '',
                        child: Icon(
                          Icons.info_outline,
                          color: Colors.grey,
                          size: 16,
                        ),
                      ),
                      SizedBox(width: 6),
                    ],
                    SizedBox(
                      width: 200,
                      child: Text(
                        item[0],
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFFAEB9FC),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(child: Text(item[1])),
                    // Expanded(
                    //   child: SelectableText.rich(
                    //     TextSpan(
                    //       style: const TextStyle(fontSize: 14),
                    //       children: [
                    //         TextSpan(
                    //           text: '${item[0]}: ',
                    //           style: const TextStyle(
                    //             fontWeight: FontWeight.w600,
                    //             color: Color(0xFFAEB9FC),
                    //           ),
                    //         ),
                    //         TextSpan(
                    //           text: item[1],
                    //           style: const TextStyle(color: Colors.white),
                    //         ),
                    //       ],
                    //     ),
                    //   ),
                    // ),
                    IconButton(
                      icon: const Icon(
                        Icons.content_copy,
                        size: 14,
                        color: Colors.grey,
                      ),
                      tooltip: 'Copy header',
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(
                            text: '${item[0]}$keyValueJoiner${item[1]}',
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget buildInputItems({
    required List<List<String>> items,
    required String title,
    required String keyValueJoiner,
    required String linesJoiner,
    required Function(int, String, String) onItemChanged,
    required Function(int, bool) onItemToggled,
    required Function(int, int) onItemReordered,
    required Function(List<String>, int) onItemAdded,
    List<bool>? enabledStates,
  }) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              IconButton(
                icon: Icon(Icons.copy, size: 16, color: Colors.grey[400]),
                tooltip: 'Copy all items',
                onPressed: () {
                  final itemText = items
                      .asMap()
                      .entries
                      .where((entry) => enabledStates?[entry.key] ?? true)
                      .map(
                        (entry) =>
                            '${entry.value[0]}$keyValueJoiner${entry.value[1]}',
                      )
                      .join(linesJoiner);
                  Clipboard.setData(ClipboardData(text: itemText));
                },
              ),
            ],
          ),
        ),
        // Items List
        Expanded(
          child: InputItems(
            flowId: widget.flow!.id,
            title: title,
            items: items,
            states: widget.flow?.request?.enabledHeaders,
            onItemToggled: onItemToggled,
            onItemReordered: onItemReordered,
            onItemChanged: onItemChanged,
            onItemAdded: onItemAdded,
          ),
        ),
      ],
    );
  }

  Widget buildRaw() {
    final isReq = isRequest;
    final headers = isReq
        ? widget.flow?.request?.headers ?? []
        : widget.flow?.response?.headers ?? [];
    widget.flow?.request?.headers ?? [];
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 8.0),
      child: FutureBuilder(
        future: mitmBodyFuture,
        builder: (context, snapshot) {
          final List<InlineSpan> headerSpans = [
            // method and path
            if (isReq) ...[
              // method
              TextSpan(
                text: '${widget.flow?.request?.method} ',
                style: TextStyle(fontSize: 16, color: Colors.green),
              ),
              // Url path
              TextSpan(
                text: '${widget.flow?.request?.path}\n',
                style: TextStyle(fontSize: 15, color: Color(0xffA89CF7)),
              ),
            ],

            // http version
            TextSpan(
              text: '${widget.flow?.request?.httpVersion}${isReq ? '\n' : ' '}',
              style: TextStyle(fontSize: 16, color: Colors.grey[200]),
            ),

            // status code
            if (!isReq)
              TextSpan(
                text:
                    '${widget.flow?.response?.statusCode} ${getStatusCodeMessage(widget.flow?.response?.statusCode)}\n',
                style: TextStyle(
                  fontSize: 16,
                  color: getStatusCodeColor(
                    widget.flow?.response?.statusCode ?? 0,
                  ),
                ),
              ),
            // Headers
            ...headers.expand(
              (header) => [
                TextSpan(
                  text: '${header[0]}: ',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xff86BFA3),
                  ),
                ),
                TextSpan(
                  text: '${header[1]}\n',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color.fromARGB(255, 220, 124, 124),
                  ),
                ),
              ],
            ),
          ];

          // Add body content based on Future state
          if (snapshot.connectionState == ConnectionState.waiting) {
            headerSpans.add(
              const TextSpan(
                text: "\nLoading body content...",
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            );
          } else if (snapshot.hasError) {
            headerSpans.add(
              TextSpan(
                text: "\nError loading body: ${snapshot.error}",
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          } else if (snapshot.hasData) {
            // Add a separator between headers and body
            headerSpans.add(
              const TextSpan(
                // text: "\n\n--- Body Content ---\n\n",
                text: "\n\n",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFAEB9FC),
                ),
              ),
            );

            // Add the actual body content
            headerSpans.add(
              TextSpan(
                text: snapshot.data?.text,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontFamily: 'monospace',
                ),
              ),
            );
          }

          return SelectableText.rich(
            TextSpan(children: headerSpans),
            style: const TextStyle(fontSize: 14, color: Colors.white),
          );
        },
      ),
    );
  }

  Widget buildBody() {
    return PreviewBody(
      contentLength: isRequest
          ? widget.flow?.request?.contentLength
          : widget.flow?.response?.contentLength,
      contentType: isRequest
          ? widget.flow?.request?.contentTypeHeader
          : widget.flow?.response?.contentTypeHeader,
      bodyFuture: mitmBodyFuture,
      // dataFuture: mitmDataFuture,
      flowId: widget.flow!.id,
      url: widget.flow!.request?.url ?? '',
    );
  }
}
