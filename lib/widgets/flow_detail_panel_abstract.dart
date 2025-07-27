import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mitmui/api/mitmproxy_client.dart';
import 'package:mitmui/models/flow.dart' as models;
import 'package:mitmui/models/response_body.dart';
import 'package:mitmui/utils/statusCode.dart';
import 'package:mitmui/widgets/preview_body.dart';

abstract class DetailsPanel extends StatefulWidget {
  final models.MitmFlow? flow;

  const DetailsPanel({required this.flow, super.key});
}

abstract class DetailsPanelState extends State<DetailsPanel>
    with SingleTickerProviderStateMixin {
  int get tabsLen;
  List<String> get tabTitles;
  String get title;
  late Future<MitmBody> mitmBodyFuture;
  // late Future<String> mitmDataFuture;

  late TabController tabController = TabController(
    length: tabsLen,
    vsync: this,
  );
  bool get isRequest => title == 'Request';
  bool get isResponse => title == 'Response';

  @override
  void initState() {
    super.initState();

    // Initialize futures for body and data
    final type = title.toLowerCase();
    mitmBodyFuture = MitmproxyClient.getMitmBody(widget.flow!.id, type);
    // mitmDataFuture = MitmproxyClient.getMitmContent(widget.flow!.id, type);
  }

  @override
  void didUpdateWidget(covariant DetailsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.flow?.id != widget.flow?.id) {
      // Reset futures when flow changes
      final type = title.toLowerCase();
      mitmBodyFuture = MitmproxyClient.getMitmBody(widget.flow!.id, type);
      // mitmDataFuture = MitmproxyClient.getMitmContent(widget.flow!.id, type);
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
          Text(
            title,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
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
        ],
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
    return ListView.builder(
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
                  icon: const Icon(Icons.copy, size: 16),
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
                vertical: 4.0,
                horizontal: 8.0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText.rich(
                      TextSpan(
                        style: const TextStyle(fontSize: 14),
                        children: [
                          TextSpan(
                            text: '${item[0]}: ',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFAEB9FC),
                            ),
                          ),
                          TextSpan(
                            text: item[1],
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.content_copy, size: 14),
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
    );
  }

  Widget buildRaw() {
    final isReq = isRequest;
    final headers = isReq
        ? widget.flow?.request.headers ?? []
        : widget.flow?.response?.headers ?? [];
    widget.flow?.request.headers ?? [];
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
                text: '${widget.flow?.request.method} ',
                style: TextStyle(fontSize: 16, color: Colors.green),
              ),
              // Url path
              TextSpan(
                text: '${widget.flow?.request.path}\n',
                style: TextStyle(fontSize: 15, color: Color(0xffA89CF7)),
              ),
            ],

            // http version
            TextSpan(
              text: '${widget.flow?.request.httpVersion}${isReq ? '\n' : ' '}',
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
                text: "\n\n--- Body Content ---\n\n",
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
          ? widget.flow?.request.contentLength
          : widget.flow?.response?.contentLength,
      contentType: isRequest
          ? widget.flow?.request.contentTypeHeader
          : widget.flow?.response?.contentTypeHeader,
      bodyFuture: mitmBodyFuture,
      // dataFuture: mitmDataFuture,
      flowId: widget.flow!.id,
      url: widget.flow!.request.url,
    );
  }
}
