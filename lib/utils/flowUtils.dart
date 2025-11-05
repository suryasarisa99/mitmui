import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitmui/models/flow.dart';
import 'package:mitmui/store/flows_provider.dart';

MitmFlow? getFlowByRowId(String? rowId, WidgetRef ref) {
  int? flowId = int.tryParse(rowId ?? '');
  if (flowId == null) return null;
  final flow = ref.read(flowsProvider.notifier).flows[flowId];
  return flow;
}
