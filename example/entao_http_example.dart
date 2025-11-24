// ignore_for_file: unused_local_variable

import 'dart:convert';
import 'dart:io';

import 'package:entao_dutil/entao_dutil.dart';
import 'package:entao_http/entao_http.dart';
import 'package:entao_result/entao_result.dart';
import 'package:println/println.dart';

void main() async {
  Result<String> hr = await httpGet("http://localhost:8080/hole/pub/echo".parsedUri, args: ["name" >> "entao"]).text();
  if (hr case Success(value: String v, extra: AnyMap headers)) {
    println(v);
    // {"name":"entao","headers":{"accept-encoding":"gzip","host":"localhost:8080","user-agent":"Dart\/3.8 (dart:io)"}}
    println(headers);
    // {content-type: application/json;charset=utf-8, date: Sat, 22 Nov 2025 07:02:08 GMT, content-length: 112}
  } else if (hr is Failure) {
    println(hr);
  }
}

void exampleGetString(Uri uri) async {
  // Get Text
  Result<String> textGet = await httpGet(uri.appendPath("query"), args: ["pruductId" >> 100]).text(utf8);
  switch (textGet) {
    case Success<String> ok:
      println("Text", ok.value);
      println("Headers", ok.extra);
    case Failure e:
      println("error: ", e);
  }
  // Post
  Result<String> textPost = await httpPost(uri.appendPath("query"), args: ["pruductId" >> 100], headers: {"access_token": "xxxxxx"}).text(utf8);

  // Post Body
  HttpBody body = HttpBody.json("""{"type":"fruit", "name":"Apple"}""");
  Result<String> textPostBody = await httpPost(uri.appendPath("create"), body: body, headers: {"access_token": "xxxxxx"}).text(utf8);

  // Multipart, uplaod files
  FileItem fileImage = FileItem(field: "image", file: File("..path"));
  Result<String> multipartResult = await httpMultipart(uri.appendPath("create"), files: [fileImage], headers: {"access_token": "xxxxxx"}).text(utf8);

  // json
  Result resultJson = await httpGet(uri, args: ["pruductId" >> 100]).json();
  // cast to typed result
  Result<int> intResult = resultJson.casted();
  // list result
  Result<List<int>> listResult = resultJson.mapList((e) => e as int);
  // map value
  switch (resultJson) {
    case Success ok:
      // one model
      Product p = ok.model(Product.new);
      // list model
      List<Product> products = ok.listModel(Product.new);
      break;
    case Failure _:
      break;
  }
}

void exmapleJson(Uri uri) async {
  // json result, return type is Result<dynamic>
  Result jr = await httpGet(uri, args: ["pruductId" >> 100]).json();
  // cast to int result
  Result<int> intResult = jr.casted();
  // to list result
  Result<List<int>> listResult = jr.mapList((e) => e as int);
  // map value
  switch (jr) {
    case Success ok:
      // one model
      Product p = ok.model(Product.new);
      // list model
      List<Product> products = ok.listModel(Product.new);
      break;
    case Failure _:
      break;
  }
}

class Product {
  Map<String, dynamic> model;

  Product(this.model);

  int get id => model["id"];

  String get name => model["name"];
}
