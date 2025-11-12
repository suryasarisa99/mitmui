import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitmui/models/flow.dart';
import 'package:mitmui/store/flows_provider.dart';

extension FlowRefX on WidgetRef {
  FlowsProvider get flowsN => read(flowsProvider.notifier);
  Map<String, MitmFlow> get flows => read(flowsProvider);
  // void updateHeader(List<String> headers) {
  //   read(flowsProvider.notifier).updateHeader(headers);
  // }
}
