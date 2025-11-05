enum FilterKey {
  // --- General ---
  all('~all'),
  comment('~comment'),
  marked('~marked'),
  marker('~marker'),
  metadata('~meta'),

  // --- req ---
  url('~u'),
  method('~m'),
  domain('~d'),
  reqHeader('~hq'),
  reqBody('~bq'),
  reqContentType('~tq'),
  reqWithNoRes('~q'),

  // --- res ---
  res('~s'),
  statusCode('~c'),
  asset('~a'),
  resHeader('~hs'),
  resBody('~bs'),
  resContentType('~ts'),

  // --- Combined ---
  header('~h'),
  body('~b'),
  contentType('~t'),

  // --- Connection ---
  sourceAddress('~src'),
  destinationAddress('~dst'),
  error('~e'),

  // --- Replay ---
  replayedFlow('~replay'),
  replayedReq('~replayq'),
  replayedRes('~replays'),

  // --- Protocols ---
  http('~http'),
  tcp('~tcp'),
  udp('~udp'),
  dns('~dns'),
  websocket('~websocket'),

  // --- Custom Filters on url ---
  fileExtension('~u'),
  queryParam('~u'),
  queryKey('~u'),
  queryValue('~u');

  const FilterKey(this.prettyName);
  final String prettyName;
}

enum LogicalOperator { and, or }

enum FilterOperator {
  regex('~'),
  equals('='),
  startsWith('^'),
  endsWith('\$');

  const FilterOperator(this.symbol);
  final String symbol;
}

/// Base class for all nodes in the filter tree.
abstract class FilterNode {
  bool isNegated = false;
  // A unique object for making sure widgets have stable keys during rebuilds.
  final Object key = Object();
}

/// A leaf node representing a single filter condition (e.g., "~u example.com").
class FilterCondition extends FilterNode {
  FilterKey keyType;
  FilterOperator operator;
  String value;

  FilterCondition({
    this.keyType = FilterKey.url,
    this.operator = FilterOperator.regex,
    this.value = '',
  });
}

/// An internal node representing a group of conditions or other groups.
class FilterGroup extends FilterNode {
  List<LogicalOperator> operators;
  List<FilterNode> children;

  FilterGroup({required this.children, List<LogicalOperator>? operators})
    : operators =
          operators ??
          List.filled(
            children.isNotEmpty ? children.length - 1 : 0,
            LogicalOperator.and,
            growable: true,
          );
}
