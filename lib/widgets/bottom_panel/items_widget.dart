import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mitmui/http_docs.dart';

class ItemsWidget extends StatelessWidget {
  const ItemsWidget({
    super.key,
    required this.items,
    required this.title,
    required this.keyValueJoiner,
    required this.linesJoiner,
  });

  final List<List<String>> items;
  final String title;
  final String keyValueJoiner;
  final String linesJoiner;

  @override
  Widget build(BuildContext context) {
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
                children: <Widget>[
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
}
