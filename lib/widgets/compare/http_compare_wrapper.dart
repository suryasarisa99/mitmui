import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitmui/api/mitmproxy_client.dart';
import 'package:mitmui/models/http_compare_message.dart';
import 'package:mitmui/theme.dart';
import 'package:mitmui/utils/ref_extension.dart';
import 'package:mitmui/widgets/compare/http_compare.dart';

class HttpCompareWrapper extends ConsumerStatefulWidget {
  const HttpCompareWrapper({
    super.key,
    required this.id1,
    required this.id2,
    this.isRequest = true,
  });
  final String id1;
  final String id2;
  final bool isRequest;
  @override
  ConsumerState<HttpCompareWrapper> createState() => _HttpCompareWrapperState();
}

class _HttpCompareWrapperState extends ConsumerState<HttpCompareWrapper> {
  late final flow1 = ref.flows[widget.id1]!;
  late final flow2 = ref.flows[widget.id2]!;
  late var isRequest = widget.isRequest;

  @override
  Widget build(BuildContext context) {
    final type = isRequest ? 'request' : 'response';
    final theme = AppTheme.from(Theme.brightnessOf(context));
    return Container(
      color: theme.surface,
      child: Column(
        mainAxisSize: .min,
        children: [
          Padding(
            padding: const .all(3.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      isRequest = !isRequest;
                    });
                  },
                  icon: Icon(isRequest ? Icons.swap_horiz : Icons.swap_vert),
                  label: Text(isRequest ? 'Request' : 'Response'),
                ),
                Spacer(),
                IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: Icon(Icons.close),
                ),
              ],
            ),
          ),
          Divider(height: 1),
          Flexible(
            child: FutureBuilder(
              future: Future.wait([
                MitmproxyClient.getMitmBody(flow1.id, type),
                MitmproxyClient.getMitmBody(flow2.id, type),
              ]),
              builder: (context, asyncSnapshot) {
                if (asyncSnapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (asyncSnapshot.hasData == false) {
                  return const Center(child: Text("No Data"));
                }

                return HttpCompare(
                  lazyLoad: false,
                  message1: HttpCompareMessage.fromFlow(
                    flow1,
                    isRequest: isRequest,
                    body: asyncSnapshot.data![0].text,
                  ),
                  message2: HttpCompareMessage.fromFlow(
                    flow2,
                    isRequest: isRequest,
                    body: asyncSnapshot.data![1].text,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
