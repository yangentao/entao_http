part of 'http_impl.dart';

class HttpX {
  final void Function(Uri uri, Map<String, String> params, Map<String, String> headers)? before;

  HttpX({this.before});

  void _interceptor(Uri uri, Map<String, String> params, Map<String, String> headers) {
    before?.call(uri, params, headers);
  }

  late dynamic get = AnyCall<Future<HttpResult>>(
    callback: (ls, map) {
      Uri uri = _findUri(ls);
      var params = _findParams(map);
      var headers = _findHeaders(map);
      _interceptor(uri, params, headers);
      return HttpGet(uri).args(params).headers(headers).request();
    },
  );
  late dynamic post = AnyCall<Future<HttpResult>>(
    callback: (ls, map) {
      Uri uri = _findUri(ls);
      var params = _findParams(map);
      var headers = _findHeaders(map);
      return HttpPost(uri).args(params).headers(headers).request();
    },
  );
}

Uri _findUri(List<dynamic> ls) {
  dynamic firstArg = ls.first;
  if (firstArg is Uri) {
    return firstArg;
  } else if (firstArg is String) {
    return Uri.parse(firstArg);
  } else {
    error("First argument MUST be Uri");
  }
}

Map<String, String> _findParams(Map<String, dynamic> argMap) {
  Map<String, String> argmap = {};
  for (MapEntry<String, dynamic> e in argMap.entries) {
    if (e.value != null) {
      if (!e.key.startsWith("\$")) {
        argmap[e.key] = e.value.toString();
      }
    }
  }
  return argmap;
}

Map<String, String> _findHeaders(Map<String, dynamic> argMap) {
  Map<String, String> headerMap = {};
  for (MapEntry<String, dynamic> e in argMap.entries) {
    if (e.value != null) {
      if (e.key.startsWith("\$")) {
        headerMap[e.key.substring(1)] = e.value.toString();
      }
    }
  }
  return headerMap;
}
