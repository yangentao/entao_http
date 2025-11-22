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
