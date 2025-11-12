import 'package:mitmui/api/mitmproxy_client.dart';
import 'package:mitmui/models/response_body.dart';

class MitmBodyService {
  final String type;
  String id;
  Future<MitmBody>? body;
  MitmBodyService({required this.id, required this.type});

  Future<MitmBody> reloadBody() async {
    body = null;
    final response = MitmproxyClient.getMitmBody(id, type);
    body = response;
    return response;
  }

  Future<MitmBody> getMitmBody() async {
    return body ?? await reloadBody();
  }

  void update(String id) {
    this.id = id;
    body = null;
  }
}
