library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:entao_dutil/entao_dutil.dart';
import 'package:entao_result/entao_result.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart' as mimes;
import 'package:println/println.dart';

part 'src/http_impl.dart';
part 'src/http_result.dart';
part 'src/utils.dart';

extension SuccessTransformEx on Success {
  ///  ["id", "name", "score"]
  ///  [1000, "Tom", 90]
  ///  [1001, "Jerry", 80]
  /// like csv format, first line is column names , rest is data
  List<T> table<T>(T Function(Map<String, dynamic>) maper) {
    return transform((List<List<dynamic>> rows) {
      return _dataTableFromList(rows: rows, maper: maper);
    });
  }

  R model<R>(R Function(AnyMap) mapper) {
    return transform(mapper);
  }

  List<R> listModel<R>(R Function(AnyMap) mapper) {
    return transform((List<AnyMap> ls) {
      return ls.mapList(mapper);
    });
  }

  List<R> listValue<R, T>(R Function(T) mapper) {
    return transform((List<T> ls) {
      return ls.mapList(mapper);
    });
  }

  List<R> list<R>() {
    return transform((List<R> ls) => ls);
  }

  R transform<R, T>(R Function(T) maper) {
    if (this case Success(value: T v)) {
      return maper(v);
    }
    errorHare("Bad type");
  }
}

// header error code/message, message is url encoded
const String E_CODE = "e_code";
const String E_MESSAGE = "e_message";

Future<Result<String>> httpGet(Uri url, {List<LabelValue>? args, Map<String, String>? headers, Encoding responseEncoding = utf8}) {
  return HttpGet(url).argPairs(args).headers(headers).requestText(responseEncoding);
}

Future<Result<String>> httpPost(Uri url, {List<LabelValue>? args, Map<String, String>? headers, Encoding responseEncoding = utf8}) {
  return HttpPost(url).argPairs(args).headers(headers).requestText(responseEncoding);
}

Future<Result<String>> httpMultipart(Uri url, {List<FileItem>? files, List<LabelValue>? args, Map<String, String>? headers, Encoding responseEncoding = utf8}) {
  return HttpMultipart(url).headers(headers).argPairs(args ?? []).files(files).requestText(responseEncoding);
}

/// if return Success, Success.value alway is true.
Future<Result<bool>> httpDownload(Uri url, {List<LabelValue>? args, Map<String, String>? headers, required File toFile, ProgressCallback? progress}) {
  return HttpGet(url).argPairs(args).headers(headers).download(toFile: toFile, progress: progress);
}

// used for small bytes, large bytes use httpDownlaod()
Future<Result<Uint8List>> httpGetBinary(Uri url, {List<LabelValue>? args, Map<String, String>? headers, ProgressCallback? progress}) {
  return HttpGet(url).argPairs(args).headers(headers).requestBytes(progress);
}
