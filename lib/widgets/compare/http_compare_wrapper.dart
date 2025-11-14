import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitmui/api/mitmproxy_client.dart';
import 'package:mitmui/utils/ref_extension.dart';
import 'package:mitmui/widgets/compare/compare2.dart';

class HttpCompareWrapper extends ConsumerStatefulWidget {
  const HttpCompareWrapper({super.key, required this.id1, required this.id2});
  final String id1;
  final String id2;
  @override
  ConsumerState<HttpCompareWrapper> createState() => _HttpCompareWrapperState();
}

class _HttpCompareWrapperState extends ConsumerState<HttpCompareWrapper> {
  late final flow1 = ref.flows[widget.id1]!;
  late final flow2 = ref.flows[widget.id2]!;
  @override
  Widget build(BuildContext context) {
    final isRequest = false;
    return HttpCompare(
      lazyLoad: false,
      message1: HttpMessage.fromFlow(flow1, isRequest: isRequest),
      message2: HttpMessage.fromFlow(flow2, isRequest: isRequest),
    );
  }
}
