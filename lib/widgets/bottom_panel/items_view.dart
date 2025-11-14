import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mitmui/store/derrived_flows_provider.dart';
import 'package:mitmui/widgets/bottom_panel/items_widget.dart';


/// Abstract base class for widgets that watch a list of key-value items
/// from a Riverpod provider and display them using [ItemsWidget].
abstract class AbstractItemsView extends ConsumerWidget {
  const AbstractItemsView({
    super.key,
    required this.id,
    required this.title,
    required this.keyValueJoiner,
    required this.linesJoiner,
  });

  final String id;
  final String title;
  final String keyValueJoiner;
  final String linesJoiner;

  /// Subclasses must provide the provider that returns the items list.
  Provider<List<List<String>>?> itemsProvider(String id);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(itemsProvider(id));
    return ItemsWidget(
      items: items ?? [],
      title: title,
      keyValueJoiner: keyValueJoiner,
      linesJoiner: linesJoiner,
    );
  }
}

class ReqHeadersView extends AbstractItemsView {
  const ReqHeadersView({
    super.key,
    required super.id,
    required super.title,
    required super.keyValueJoiner,
    required super.linesJoiner,
  });

  @override
  itemsProvider(String id) {
    return headersProvider(id);
  }
}

class ResHeadersView extends AbstractItemsView {
  const ResHeadersView({
    super.key,
    required super.id,
    required super.title,
    required super.keyValueJoiner,
    required super.linesJoiner,
  });

  @override
  itemsProvider(String id) {
    return responseHeadersProvider(id);
  }
}

class CookiesView extends AbstractItemsView {
  const CookiesView({
    super.key,
    required super.id,
    required super.title,
    required super.keyValueJoiner,
    required super.linesJoiner,
  });

  @override
  itemsProvider(String id) {
    return parsedCookiesProvider(id);
  }
}

class QueryView extends AbstractItemsView {
  const QueryView({
    super.key,
    required super.id,
    required super.title,
    required super.keyValueJoiner,
    required super.linesJoiner,
  });

  @override
  itemsProvider(String id) {
    return parsedQueryProvider(id);
  }
}
