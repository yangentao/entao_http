part of '../entao_http.dart';

class HttpResult {
  final BaseHttp _http;

  HttpResult._(this._http);

  Future<Result> json() async {
    Result<String> r = await _http.requestText(utf8);
    switch (r) {
      case Success<String> ok:
        return Success(ok.value.jsonDecode(), extra: ok.extra);
      case Failure e:
        return e;
    }
  }

  Future<Result<String>> xml([Encoding encoding = utf8]) async {
    return await _http.requestText(encoding);
  }

  Future<Result<String>> text([Encoding encoding = utf8]) async {
    return await _http.requestText(encoding);
  }

  Future<Result<Uint8List>> binary([ProgressCallback? progress]) async {
    return await _http.requestBytes(progress);
  }

  /// Success.value always true
  Future<Result<bool>> save({required File toFile, ProgressCallback? progress}) async {
    return await _http.download(toFile: toFile, progress: progress);
  }
}

abstract class BaseHttp {
  final Uri uri;
  final String method;
  final Map<String, String> headerMap = {};
  final Map<String, String> arguments = {};

  BaseHttp(this.method, this.uri);

  http.BaseRequest prepareRequest();

  HttpResult get result => HttpResult._(this);

  Future<http.StreamedResponse> requestStream() async {
    var req = prepareRequest();
    return await req.send();
  }

  Future<Result<T>> _request<T>(Future<Result<T>> Function(http.StreamedResponse) onRead) async {
    try {
      http.StreamedResponse response = await requestStream();
      if (response.success) {
        return await onRead(response);
      } else {
        return Failure(response.errorMessage ?? response.reasonPhrase ?? "Request failed", code: response.errorCode ?? response.statusCode);
      }
    } catch (e, st) {
      println(e);
      println(st);
      return _fromException(e, st);
    }
  }

  Future<Result<String>> requestText([Encoding encoding = utf8]) async {
    return _request((response) async {
      return Success(await response.readText(encoding), extra: response.headers);
    });
  }

  Future<Result<Uint8List>> requestBytes([ProgressCallback? progress]) async {
    return _request((response) async {
      return Success(await response.readBytes(progress), extra: response.headers);
    });
  }

  Future<Result<bool>> download({required File toFile, ProgressCallback? progress}) async {
    return _request((response) async {
      response.download(toFile, progress: progress);
      return Success(true);
    });
  }
}

extension BaseHttpExt<T extends BaseHttp> on T {
  T headers(Map<String, String>? headers) {
    if (headers != null) this.headerMap.addAll(headers);
    return this;
  }

  T args(Map<String, dynamic>? args) {
    argPairs(args?.entries.toList());
    return this;
  }

  T argList(List<(String key, dynamic value)>? args) {
    if (args != null) {
      for (var (String key, dynamic value) in args) {
        if (value != null) {
          arguments[key] = value.toString();
        }
      }
    }
    return this;
  }

  T argPairs(List<LabelValue>? args) {
    if (args != null) {
      for (var a in args) {
        if (a.value != null) {
          arguments[a.label] = a.value.toString();
        }
      }
    }
    return this;
  }
}

class HttpGet extends BaseHttp {
  HttpGet(Uri uri) : super("GET", uri);

  @override
  http.BaseRequest prepareRequest() {
    var request = http.Request(method, uri.appendedParams(arguments));
    request.headers.addAll(headerMap);
    return request;
  }
}

class HttpPost extends BaseHttp {
  Encoding encoding = utf8;
  HttpBody? _body;

  HttpPost(Uri uri) : super("POST", uri);

  HttpPost body(HttpBody? body) {
    if (body != null) this._body = body;
    return this;
  }

  @override
  http.BaseRequest prepareRequest() {
    if (_body == null) {
      /// bodyFields 自动设置 request.contentType = "application/x-www-form-urlencoded";
      var request = http.Request(method, uri);
      request.headers.addAll(headerMap);
      request.encoding = encoding;
      request.bodyFields = arguments;
      return request;
    } else {
      HttpBody body = _body!;
      var request = http.Request(method, uri.appendedParams(arguments));
      request.headers.addAll(headerMap);
      request.contentType = body._contentType;
      request.bodyBytes = body._bytes;
      return request;
    }
  }
}

extension on http.Request {
  // ignore: unused_element
  String? get contentType => headers['Content-Type'];

  set contentType(String? value) => value == null ? headers.remove('Content-Type') : headers['Content-Type'] = value;
}

class HttpMultipart extends BaseHttp {
  final List<FileItem> _files = [];

  HttpMultipart(Uri uri) : super("POST", uri);

  HttpMultipart files(List<FileItem>? files) {
    if (files != null) _files.addAll(files);
    return this;
  }

  @override
  http.BaseRequest prepareRequest() {
    var request = http.MultipartRequest(method, uri);
    request.headers.addAll(headerMap);
    request.fields.addAll(arguments);
    request.files.addAll(_fileItemsToMultipartFile(_files));
    return request;
  }
}

List<http.MultipartFile> _fileItemsToMultipartFile(List<FileItem> files) {
  List<http.MultipartFile> list = [];
  for (FileItem item in files) {
    Stream<List<int>> stream = item.file.openRead();
    if (item.progress != null) {
      stream = stream.progress(total: item.fileLength, onProgress: item.progress!);
    }
    list << http.MultipartFile(item.field, stream, item.fileLength, filename: item.filename, contentType: MediaType.parse(item.mime));
  }
  return list;
}

class FileItem {
  final String field;
  final File file;
  final String filename;
  final String mime;
  final ProgressCallback? progress;

  late final int fileLength = file.lengthSync();

  FileItem({required this.field, required this.file, String? filename, String? mime, this.progress})
      : mime = mime ?? _mimeOf(file),
        filename = filename ?? _fileNameOf(file.path);
}

class HttpBody {
  final List<int> _bytes;
  final String _contentType;

  HttpBody._(this._bytes, this._contentType);

  static HttpBody binary(List<int> buffer, [String? contentType]) => HttpBody._(buffer, contentType ?? "application/octet-stream");

  static HttpBody xml(String text) => HttpBody._(text.utf8Bytes(), "application/xml");

  static HttpBody json(String text) => HttpBody._(text.utf8Bytes(), "application/json");

  static HttpBody text(String body, {String? contentType, Encoding encoding = utf8}) {
    Encoding enc = _parseContentTypeEncoding(contentType) ?? encoding;
    return HttpBody._(enc.encode(body), contentType ?? "text/plain; charset=${enc.name}");
  }
}

Encoding? _parseContentTypeEncoding(String? contentType) {
  if (contentType == null) return null;
  MediaType m = MediaType.parse(contentType);
  String? ch = m.parameters["charset"]?.toLowerCase();
  if (ch == null) return null;
  return Encoding.getByName(ch);
}
