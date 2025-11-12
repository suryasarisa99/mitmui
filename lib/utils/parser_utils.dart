import 'package:flutter/material.dart';

class ParserUtils {
  ParserUtils._();

  static List<List<String>> parseQuery(String? raw) {
    debugPrint('parsing query');
    final pathList = raw?.split('?') ?? [];
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

  // static List<List<String>> parseCookies(String raw) {
  //   debugPrint('parsing cookies');
  //   final cookieList = raw.split(';');
  //   return cookieList.map((e) {
  //     final parts = e.split('=');
  //     final key = Uri.decodeComponent(parts[0]);
  //     final value = parts.length > 1 ? Uri.decodeComponent(parts[1]) : '';
  //     return [key, value];
  //   }).toList();
  // }
  static List<List<String>> parseCookies(String raw) {
    debugPrint('parsing cookies');
    final cookieList = raw
        .split(';')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return cookieList.map((e) {
      final parts = e.split('=');
      final key = Uri.decodeComponent(parts[0]);
      final value = parts.length > 1
          ? Uri.decodeComponent(parts.sublist(1).join('='))
          : '';
      return [key, value];
    }).toList();
  }

  static List<CookieData> parseSetCookie(String raw) {
    final lines = raw
        .split(RegExp(r'(?<=\r\n)|(?<=\n)|(?<=,)'))
        .where((l) => l.trim().isNotEmpty);
    final cookies = <CookieData>[];

    for (final line in lines) {
      final parts = line
          .split(';')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (parts.isEmpty) continue;

      // First part: name=value
      final nameValue = parts.first.split('=');
      if (nameValue.length < 2) continue;
      final name = nameValue[0];
      final value = nameValue.sublist(1).join('=');

      final attributes = <String, String>{};
      for (final attr in parts.skip(1)) {
        final kv = attr.split('=');
        if (kv.length == 2) {
          attributes[kv[0].toLowerCase()] = kv[1];
        } else {
          attributes[kv[0].toLowerCase()] =
              ''; // flag attributes like Secure, HttpOnly
        }
      }

      cookies.add(CookieData(name, value, attributes));
    }

    return cookies;
  }
}

class CookieData {
  final String name;
  final String value;
  final Map<String, String> attributes;

  CookieData(this.name, this.value, this.attributes);

  @override
  String toString() => 'Cookie(name: $name, value: $value, attrs: $attributes)';
}
