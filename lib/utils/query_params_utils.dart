import 'package:mitmui/models/flow.dart';

class QueryParamsUtils {
  static List<List<String>> getQueryParamsList(MitmFlow? flow) {
    final pathList = flow?.request?.path.split('?') ?? [];
    if (pathList.length < 2) return [];
    final queryParams = pathList[1];
    if (queryParams.isEmpty) return [];
    return queryParams.split('&').map((e) {
      final parts = e.split('=');
      final key = Uri.decodeComponent(parts[0]);
      final value = parts.length > 1 ? Uri.decodeComponent(parts[1]) : '';
      return [key, value];
    }).toList();
  }

  static String buildQueryParamsString(List<List<String>> queryParams) {
    // all enabled
    final allParams = <String>[];
    for (final param in queryParams) {
      if (param[0].isNotEmpty) {
        final key = Uri.encodeComponent(param[0]);
        final value = Uri.encodeComponent(param[1]);
        allParams.add('$key=$value');
      }
    }
    return allParams.join('&');
  }

  static String buildPath(String basePath, List<List<String>> queryParams) {
    final queryString = buildQueryParamsString(queryParams);
    if (queryString.isEmpty) {
      return basePath;
    } else {
      return '$basePath?$queryString';
    }
  }
}
