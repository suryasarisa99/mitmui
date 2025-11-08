import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mitmui/api/mitmproxy_client.dart';
import 'package:re_editor/re_editor.dart';

class CodeControllerService {
  var codeController = CodeLineEditingController();
  final isModified = ValueNotifier<bool>(false);
  String _savedText = '';
  VoidCallback? _codeListener;
  final String type;
  String flowId = '';

  // constructor
  CodeControllerService(this.type);

  void init(String text) {
    _savedText = text;
    // codeController.text = text;
    codeController = CodeLineEditingController.fromText(text);
    isModified.value = false;
    addListener();
  }

  void addListener() {
    debugPrint("adding listener");
    _codeListener = () {
      final current = codeController.text;
      final dirty = current != _savedText;
      debugPrint("listener called: $dirty");
      if (isModified.value != dirty) isModified.value = dirty;
      if (isModified.value) {
        debugPrint("removing listener");
        codeController.removeListener(_codeListener!);
      }
    };
    codeController.addListener(_codeListener!);
  }

  void dispose() {
    if (_codeListener != null) codeController.removeListener(_codeListener!);
    // _savedText = '';
    // isModified.dispose();
    codeController.dispose();
  }

  void handleSave(String x) {
    _savedText = codeController.text;
    isModified.value = false;
    addListener();
    MitmproxyClient.updateBody(flowId, type: type, body: _savedText);
  }

  void handleCancel() {
    codeController.text = _savedText;
    isModified.value = false;
    addListener();
  }
}
