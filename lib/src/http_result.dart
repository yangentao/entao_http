part of '../entao_http.dart';

class HttpResult {
  static const String E_CODE = "e_code";
  static const String E_MESSAGE = "e_message";
  static const String X_TOTAL = "x_total";
  static const String X_OFFSET = "x_offset";

  final http.StreamedResponse? rawResponse;
  final dynamic error;

  //request(readBytes = true)时有效.
  Uint8List? bodyBytes;

  HttpResult(this.rawResponse, [this.error]);

  http.BaseRequest? get request => rawResponse?.request;

  late final bool success = httpOK && (headerCode == null || headerCode == 0);
  late final int code = _code();
  late final String message = _message();

  late final int? headerCode = headers[E_CODE]?.toInt;
  late final String? headerMessage = headers[E_MESSAGE];

  late final bool httpOK = httpCode != null && httpCode! >= 200 && httpCode! < 300;

  late final int? httpCode = rawResponse?.statusCode;

  late final String? httpReason = rawResponse?.reasonPhrase;

  late final Map<String, String> headers = rawResponse?.headers ?? {};

  late final bool isRedirect = rawResponse?.isRedirect ?? false;

  late final bool persistentConnection = rawResponse?.persistentConnection ?? false;

  late final int? contentLength = rawResponse?.contentLength;

  late final String? contentType = headers['content-type'];

  late final bool isJson = contentType?.contains("json") ?? false;

  late final http.ByteStream stream = rawResponse?.stream ?? fatal("NO http response!");

  late final String? bodyText = bodyBytes == null ? null : _encodingOfHeaders(headers).decode(bodyBytes!);

  late final int? offsetX = success ? headers[X_OFFSET]?.toInt : null;

  late final int? totalX = success ? headers[X_TOTAL]?.toInt : null;

  late final String? token = headers["access_token"] ?? headers["token"];

  late final dynamic bodyJson = _decodeJson();

  late final AnyList? bodyList = bodyJson;
  late final AnyMap? bodyMap = bodyJson;
  late final int? bodyInt = bodyText?.toInt;
  late final double? bodyDouble = bodyText?.toDouble;
  late final bool? bodyBool = (bodyText == "true" || bodyText == "1") ? true : (bodyText == "false" || bodyText == "0" ? false : null);

  @Deprecated("JsonResult is deprecated")
  late final JsonResult jsonResult = success && isJson ? JsonResult.from(bodyText ?? "{}") : JsonResult.from("{}");

  dynamic _decodeJson() {
    if (success) {
      assert(isJson);
      if (bodyText != null) {
        return json.decode(bodyText!);
      }
    }
    return null;
  }

  int _code() {
    switch (error) {
      case null:
        return headerCode ?? httpCode ?? -1;
      case OSError oe:
        return oe.errorCode;
      case SocketException se:
        return se.osError?.errorCode ?? -1;
      default:
        return -1;
    }
  }

  String _message() {
    switch (error) {
      case null:
        if (httpOK) {
          return (headerCode == null || headerCode == 0) ? "OK" : (headerMessage ?? "Error code=$headerCode");
        }
        switch (httpCode) {
          case 401:
            return "401 未认证";
          case 403:
            return "403 没有权限";
          case 404:
            return "404 客户端错误";
          default:
            return "$httpCode $httpReason";
        }
      case OSError oe:
        return oe.desc;
      case SocketException se:
        return se.desc;
      case HttpException he:
        return he.message;
      case http.ClientException ce:
        return ce.message;
      case IOException ie:
        return ie.toString();
      case Exception ee:
        return ee.toString();
      default:
        return error.toString();
    }
  }

  ItemsResult<T> table<T>(T Function(Map<String, dynamic>) maper) {
    AnyList? al = bodyList;
    if (success && al != null) {
      List<T> items = _dataTableFromList(rows: al as List<List<dynamic>>, maper: maper);
      return ItemsResult<T>.success(items, rawValue: this, offset: offsetX, total: totalX);
    }
    return ItemsResult<T>.failed(code: code, message: message, rawError: error);
  }

  ItemsResult<T> list<T>([T Function(dynamic)? maper]) {
    AnyList? al = bodyList;
    if (success && al != null) {
      List<T> items = al.mapList((e) => maper == null ? e : maper(e));
      return ItemsResult<T>.success(items, rawValue: this, offset: offsetX, total: totalX);
    }
    return ItemsResult<T>.failed(code: code, message: message, rawError: error);
  }

  ItemsResult<T> listModel<T>(T Function(Map<String, dynamic>) maper) {
    AnyList? al = bodyList;
    if (success && al != null) {
      List<T> items = al.mapList((e) => maper(e as Map<String, dynamic>));
      return ItemsResult<T>.success(items, rawValue: this, offset: offsetX, total: totalX);
    }
    return ItemsResult<T>.failed(code: code, message: message, rawError: error);
  }

  SingleResult<T> data<T>(T Function(String) maper) {
    String? text = bodyText;
    if (success && text != null) return SingleResult<T>.success(maper(text), rawValue: this);
    return SingleResult<T>.failed(code: code, message: message, rawError: error);
  }

  SingleResult<T> dataModel<T>(T Function(Map<String, dynamic>) maper) {
    AnyMap? map = bodyMap;
    if (success && map != null) return SingleResult<T>.success(maper(map), rawValue: this);
    return SingleResult<T>.failed(code: code, message: message, rawError: error);
  }
}

//  ["id", "name", "score"]
//  [1000, "Tom", 90]
//  [1001, "Jerry", 80]
/// 第一行是列名, 第二行开始是数据, 类似csv格式
List<T> _dataTableFromList<T>({required List<List<dynamic>> rows, required T Function(Map<String, dynamic>) maper}) {
  if (rows.length <= 1) return [];
  List<String> rowKey = rows.first.mapList((e) => e as String);
  List<T> models = [];
  for (int i = 1; i < rows.length; ++i) {
    Map<String, dynamic> map = {};
    List<dynamic> row = rows[i];
    for (int c = 0; c < rowKey.length; ++c) {
      map[rowKey[c]] = row[c];
    }
    models.add(maper(map));
  }
  return models;
}
