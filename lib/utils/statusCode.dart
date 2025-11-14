import 'package:flutter/material.dart';

Color getStatusCodeColor(int? statusCode) {
  if (statusCode == null) return Colors.grey;

  if (statusCode >= 200 && statusCode < 300) {
    return const .fromARGB(255, 106, 245, 111);
  } else if (statusCode >= 300 && statusCode < 400) {
    return Colors.blue;
  } else if (statusCode >= 400 && statusCode < 500) {
    return Colors.orange;
  } else if (statusCode >= 500) {
    return Colors.red;
  }
  return Colors.grey;
}

Color getMethodColor(String? method) {
  switch (method) {
    case 'GET':
      return const Color(0xFF28FF57);
    case 'POST':
      return const Color(0xFFFF53F4);
    case 'PUT':
      return const Color(0xFFFF6E26);
    case 'DELETE':
      return const Color(0xFFFF1100);
    case 'PATCH':
      return const Color(0xFFF8FF29);
    case 'HEAD':
      return Colors.grey;
    case 'OPTIONS':
      return const Color(0xFF75D3FF);
    default:
      return const Color(0xFFFFFFFF);
  }
}

String getStatusCodeMessage(int? statusCode) {
  if (statusCode == null) return 'Unknown';

  switch (statusCode) {
    case 200:
      return 'OK';
    case 201:
      return 'Created';
    case 204:
      return 'No Content';
    case 301:
      return 'Moved Permanently';
    case 302:
      return 'Found';
    case 400:
      return 'Bad Request';
    case 401:
      return 'Unauthorized';
    case 403:
      return 'Forbidden';
    case 404:
      return 'Not Found';
    case 500:
      return 'Internal Server Error';
    case 999:
      return 'Internal Error';
    default:
      if (statusCode >= 200 && statusCode < 300) {
        return 'Success';
      } else if (statusCode >= 300 && statusCode < 400) {
        return 'Redirection';
      } else if (statusCode >= 400 && statusCode < 500) {
        return 'Client Error';
      } else if (statusCode >= 500) {
        return 'Server Error';
      }
      return 'Unknown Status';
  }
}
