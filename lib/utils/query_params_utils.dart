import 'package:mitmui/models/flow.dart';
import 'package:mitmui/utils/parser_utils.dart';

class QueryParamsUtils {
  static List<List<String>> getQueryParamsList(MitmFlow? flow) {
    return ParserUtils.parseQuery(flow?.request?.path);
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
