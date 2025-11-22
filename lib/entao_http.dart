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
part 'src/utils.dart';

/// header error code/message, message is url encoded
const String E_CODE = "e_code";
const String E_MESSAGE = "e_message";

HttpResult httpGet(Uri url, {List<LabelValue>? args, Map<String, String>? headers}) {
  return HttpGet(url).argPairs(args).headers(headers).result;
}

HttpResult httpPost(Uri url, {List<LabelValue>? args, Map<String, String>? headers}) {
  return HttpPost(url).argPairs(args).headers(headers).result;
}

HttpResult httpMultipart(Uri url, {List<LabelValue>? args, Map<String, String>? headers, List<FileItem>? files}) {
  return HttpMultipart(url).headers(headers).argPairs(args ?? []).files(files).result;
}
