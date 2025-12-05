part of '../entao_http.dart';

extension UriParseExt on String {
  Uri get parsedUri => Uri.parse(this);
}

extension on String {
  dynamic jsonDecode() {
    return json.decode(this);
  }
}

XError _fromException(Object error, StackTrace stackTrace) {
  return XError(_exceptionMessage(error), data: stackTrace, error: error, code: -1);
}

String _exceptionMessage(Object error) {
  switch (error) {
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

extension SocketExceptionDesc on SocketException {
  String get desc => osError?.desc ?? message;
}

/// [0-133]
extension OSErrorDesc on OSError {
  String get desc {
    return "$message ($errorCode)";
  }
}

String _mimeOf(File file) {
  return mimes.lookupMimeType(file.path) ?? 'application/octet-stream';
}

String _fileNameOf(String path) {
  if (path.contains('\\')) return path.substringAfterLast("\\");
  if (path.contains('/')) return path.substringAfterLast("/");
  return path;
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

extension on http.StreamedResponse {
  bool get success => this.statusCode >= 200 && this.statusCode < 300 && (errorCode == null || errorCode == 0);

  Future<Uint8List> readBytes([ProgressCallback? progress]) async {
    if (progress == null) {
      return await this.stream.allBytes();
    } else {
      return await this.stream.progress(total: this.contentLength ?? 1, onProgress: progress).allBytes();
    }
  }

  Future<String> readText([Encoding encoding = utf8]) async {
    Uint8List bytes = await this.stream.allBytes();
    if (bytes.isEmpty) {
      return "";
    } else {
      Encoding en = this.getEncoding(encoding);
      return en.decode(bytes);
    }
  }

  Future<void> download(File toFile, {ProgressCallback? progress}) async {
    IOSink sink = toFile.openWrite();
    try {
      if (progress == null) {
        await this.stream.pipe(sink);
      } else {
        await this.stream.progress(total: this.contentLength ?? 1, onProgress: progress).pipe(sink);
      }
      await sink.flush();
    } finally {
      await sink.close();
    }
  }

  Encoding getEncoding([Encoding defaultEncoding = latin1]) {
    String? name = _contentTypeOfHeaders(headers).parameters['charset'];
    if (name == null) return defaultEncoding;
    return Encoding.getByName(name) ?? defaultEncoding;
  }

  int get _ecode => errorCode ?? 0;

  int? get errorCode => this.headers[E_CODE]?.toInt;

  String? get errorMessage {
    String? s = headers[E_MESSAGE];
    if (s != null) {
      try {
        return Uri.decodeComponent(s);
      } catch (e) {
        return s;
      }
    }
    return s;
  }
}
