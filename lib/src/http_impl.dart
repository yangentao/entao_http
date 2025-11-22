part of '../entao_http.dart';

abstract class BaseHttp {
  final Uri uri;
  final String method;
  final Map<String, String> headerMap = {};
  final Map<String, String> arguments = {};

  BaseHttp(this.method, this.uri);

  http.BaseRequest prepareRequest();

  Future<http.StreamedResponse> requestStream() async {
    var req = prepareRequest();
    return await req.send();
  }

  Future<Result<T>> _request<T>(Future<Result<T>> Function(http.StreamedResponse) onRead) async {
    try {
      var req = prepareRequest();
      http.StreamedResponse response = await req.send();
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
  List<int>? _bodyBytes;
  String? contentType;

  HttpPost(Uri uri) : super("POST", uri);

  HttpPost bodyXML(String body) {
    return bodyText(body, contentType: "application/xml", encoding: utf8);
  }

  HttpPost bodyJson(String body) {
    return bodyText(body, contentType: "application/json", encoding: utf8);
  }

  HttpPost bodyTextPlain(String body) {
    return bodyText(body, contentType: "text/plain; charset=utf-8", encoding: utf8);
  }

  HttpPost bodyText(String body, {String? contentType, Encoding? encoding}) {
    if (encoding != null) {
      this.encoding = encoding;
    } else if (contentType != null) {
      MediaType m = MediaType.parse(contentType);
      String? ch = m.parameters["charset"]?.toLowerCase();
      if (ch != null) {
        if (ch != "utf8" || ch != "utf-8") {
          var e = Encoding.getByName(ch);
          if (e != null) this.encoding = e;
        }
      }
    }
    this.contentType = contentType ?? "text/plain; charset=${this.encoding.name}";
    _bodyBytes = this.encoding.encode(body);
    return this;
  }

  HttpPost bodyBytes(List<int> body) {
    _bodyBytes = body;
    return this;
  }

  @override
  http.BaseRequest prepareRequest() {
    bool hasBody = _bodyBytes != null;
    var request = http.Request(method, hasBody ? uri.appendedParams(arguments) : uri);
    request.headers.addAll(headerMap);
    if (_bodyBytes != null) {
      request.contentType = contentType ?? "application/octet-stream";
      request.bodyBytes = _bodyBytes!;
    } else {
      /// bodyFields 自动设置 request.contentType = "application/x-www-form-urlencoded";
      request.encoding = encoding;
      request.bodyFields = arguments;
    }
    return request;
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
