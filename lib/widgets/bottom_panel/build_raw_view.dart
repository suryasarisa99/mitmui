import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitmui/models/response_body.dart';
import 'package:mitmui/store/derrived_flows_provider.dart';
import 'package:mitmui/utils/statusCode.dart';

class BuildRawView extends ConsumerWidget {
  const BuildRawView({
    super.key,
    required this.isRequest,
    // required this.widget,
    required this.mitmBodyFuture,
    required this.id,
  });

  final bool isRequest;
  // final DetailsPanel widget;
  final Future<MitmBody>? mitmBodyFuture;
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flow = ref.watch(flowProvider(id));
    final isReq = isRequest;
    final headers = isReq
        ? flow?.request?.headers ?? []
        : flow?.response?.headers ?? [];
    flow?.request?.headers ?? [];
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
                text: '${flow?.request?.method} ',
                style: TextStyle(fontSize: 16, color: Colors.green),
              ),
              // Url path
              TextSpan(
                text: '${flow?.request?.path}\n',
                style: TextStyle(fontSize: 15, color: Color(0xffA89CF7)),
              ),
            ],

            // http version
            TextSpan(
              text: '${flow?.request?.httpVersion}${isReq ? '\n' : ' '}',
              style: TextStyle(fontSize: 16, color: Colors.grey[200]),
            ),

            // status code
            if (!isReq)
              TextSpan(
                text:
                    '${flow?.response?.statusCode} ${getStatusCodeMessage(flow?.response?.statusCode)}\n',
                style: TextStyle(
                  fontSize: 16,
                  color: getStatusCodeColor(flow?.response?.statusCode ?? 0),
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
}
