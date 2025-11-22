part of '../entao_http.dart';

Future<HttpResult> httpDownload(Uri url, {List<LabelValue>? args, Map<String, String>? headers, required File toFile, ProgressCallback? progress}) {
  return HttpGet(url).argPairs(args).headers(headers).download(toFile: toFile, onProgress: progress);
}

Future<HttpResult> httpGet(Uri url, {List<LabelValue>? args, Map<String, String>? headers}) {
  return HttpGet(url).argPairs(args).headers(headers).request();
}

Future<HttpResult> httpPost(Uri url, {List<LabelValue>? args, Map<String, String>? headers}) {
  return HttpPost(url).argPairs(args).headers(headers).request();
}

Future<HttpResult> httpMultipart(Uri url, {List<FileItem>? files, List<LabelValue>? args, Map<String, String>? headers}) {
  return HttpMultipart(url).headers(headers).argPairs(args ?? []).files(files).request();
}

abstract class BaseHttp {
  final Uri uri;
  final String method;
  final Map<String, String> _headers = {};
  final Map<String, String> arguments = {};

  BaseHttp(this.method, this.uri);

  http.BaseRequest prepareRequest();

  Future<HttpResult> request({bool readBytes = true}) async {
    var req = prepareRequest();
    try {
      http.StreamedResponse resp = await req.send();
      HttpResult hr = HttpResult(resp);
      if (readBytes) {
        hr.bodyBytes = await hr.stream.allBytes();
      }
      return hr;
    } catch (e, st) {
      println(e);
      println(st);
      return HttpResult(null, e);
    }
  }

  Future<HttpResult> download({required File toFile, ProgressCallback? onProgress}) async {
    var req = prepareRequest();
    try {
      HttpResult hr = HttpResult(await req.send());
      if (hr.httpOK) {
        IOSink sink = toFile.openWrite();
        if (onProgress == null) {
          await hr.stream.pipe(sink);
        } else {
          await hr.stream.progress(total: hr.contentLength ?? 1, onProgress: onProgress).pipe(sink);
        }
        await sink.flush();
        await sink.close();
      }
      return hr;
    } catch (e, st) {
      println(e);
      println(st);
      return HttpResult(null, e);
    }
  }
}

extension BaseHttpExt<T extends BaseHttp> on T {
  T headers(Map<String, String>? headers) {
    if (headers != null) this._headers.addAll(headers);
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
    request.headers.addAll(_headers);
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
    request.headers.addAll(_headers);
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
    request.headers.addAll(_headers);
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

String _mimeOf(File file) {
  return mimes.lookupMimeType(file.path) ?? 'application/octet-stream';
}

String _fileNameOf(String path) {
  if (path.contains('\\')) return path.substringAfterLast("\\");
  if (path.contains('/')) return path.substringAfterLast("/");
  return path;
}

extension SocketExceptionDesc on SocketException {
  String get desc => osError?.desc ?? message;
}

/// [0-133]
extension OSErrorDesc on OSError {
  String get desc {
    return "$message ($errorCode)";
  }
}

Encoding _encodingOfHeaders(Map<String, String> headers) => _encodingOfCharset(_contentTypeOfHeaders(headers).parameters['charset']);

/// Returns the [MediaType] object for the given headers's content-type.
///
/// Defaults to `application/octet-stream`.
MediaType _contentTypeOfHeaders(Map<String, String> headers) {
  var contentType = headers['content-type'];
  if (contentType != null) return MediaType.parse(contentType);
  return MediaType('application', 'octet-stream');
}

Encoding _encodingOfCharset(String? charset, [Encoding fallback = latin1]) {
  if (charset == null) return fallback;
  return Encoding.getByName(charset) ?? fallback;
}
