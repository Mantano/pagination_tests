import 'dart:convert';

import 'package:fimber/fimber.dart';

class JsApi {
  final Function _jsLoader;

  JsApi(this._jsLoader);

  void loadJS(String jScript) {
    Fimber.d("loadJS: $jScript");
    _jsLoader("javascript:(function(){$jScript})()");
  }

  void initPagination() {
    loadJS("initPagination()");
  }
}
