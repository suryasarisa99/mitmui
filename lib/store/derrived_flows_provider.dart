// derrived flow provider
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitmui/models/flow.dart';
import 'package:mitmui/store/flows_provider.dart';
import 'package:mitmui/utils/parser_utils.dart';
import 'package:mitmui/utils/query_params_utils.dart';

// derived providers
// family is used to pass index parameter

final flowProvider = Provider.family<MitmFlow?, String>((ref, index) {
  return ref.watch(flowsProvider.select((flows) => flows[index]));
});

final rawQueryProvider = Provider.family<String?, String>((ref, index) {
  return ref.watch(flowProvider(index).select((flow) => flow?.request?.path));
});

final rawCookiesProvider = Provider.family<String?, String>((ref, index) {
  return ref.watch(
    flowProvider(index).select((flow) => flow?.request?.cookies),
  );
});

final headersProvider = Provider.family<List<List<String>>?, String>((
  ref,
  index,
) {
  return ref.watch(
    flowProvider(index).select((flow) => flow?.request?.headers),
  );
});
final responseHeadersProvider = Provider.family<List<List<String>>?, String>((
  ref,
  index,
) {
  return ref.watch(
    flowProvider(index).select((flow) => flow?.response?.headers),
  );
});

final parsedQueryProvider = Provider.family<List<List<String>>, String>((
  ref,
  index,
) {
  final raw = ref.watch(rawQueryProvider(index)) ?? '';
  return ParserUtils.parseQuery(raw);
});

final parsedCookiesProvider = Provider.family<List<List<String>>, String>((
  ref,
  index,
) {
  final raw = ref.watch(rawCookiesProvider(index)) ?? '';
  return ParserUtils.parseCookies(raw);
});
