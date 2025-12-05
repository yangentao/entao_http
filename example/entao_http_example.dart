// ignore_for_file: unused_local_variable

import 'dart:convert';
import 'dart:io';

import 'package:entao_dutil/entao_dutil.dart';
import 'package:entao_http/entao_http.dart';
import 'package:println/println.dart';

void main() async {
  XResult<String> hr = await httpGet("http://localhost:8080/hole/pub/echo".parsedUri, args: ["name" >> "entao"]).text();
  println(hr);
}

void exampleGetString(Uri uri) async {
  // Get Text
  XResult<String> textGet = await httpGet(uri.appendPath("query"), args: ["pruductId" >> 100]).text(utf8);
  print(textGet);
  // Post
  XResult<String> textPost = await httpPost(uri.appendPath("query"), args: ["pruductId" >> 100], headers: {"access_token": "xxxxxx"}).text(utf8);

  // Post Body
  HttpBody body = HttpBody.json("""{"type":"fruit", "name":"Apple"}""");
  XResult<String> textPostBody = await httpPost(uri.appendPath("create"), body: body, headers: {"access_token": "xxxxxx"}).text(utf8);

  // Multipart, uplaod files
  FileItem fileImage = FileItem(field: "image", file: File("..path"));
  XResult<String> multipartResult = await httpMultipart(uri.appendPath("create"), files: [fileImage], headers: {"access_token": "xxxxxx"}).text(utf8);

  // json
  XResult resultJson = await httpGet(uri, args: ["pruductId" >> 100]).json();
  // cast to typed result
  XResult<int> intResult = resultJson.casted();
  // list result
  XResult<List<int>> listResult = resultJson.mapList((e) => e as int);
  // map value
  if (resultJson.success) {
    Product p = resultJson.model(Product.new);
    // list model
    List<Product> products = resultJson.listModel(Product.new);
  }
}

void exmapleJson(Uri uri) async {
  // json result, return type is Result<dynamic>
  XResult jr = await httpGet(uri, args: ["pruductId" >> 100]).json();
  // cast to int result
  XResult<int> intResult = jr.casted();
  // to list result
  XResult<List<int>> listResult = jr.mapList((e) => e as int);
  if (jr.success) {
    Product p = jr.model(Product.new);
    // list model
    List<Product> products = jr.listModel(Product.new);
  }
}

class Product {
  Map<String, dynamic> model;

  Product(this.model);

  int get id => model["id"];

  String get name => model["name"];
}
