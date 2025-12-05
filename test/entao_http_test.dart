import 'package:entao_dutil/entao_dutil.dart';
import 'package:entao_http/entao_http.dart';
import 'package:println/println.dart';
import 'package:test/test.dart';

void main() {
  test('echo', () async {
    XResult<String> hr = await httpGet("http://localhost:8080/hole/pub/echo".parsedUri, args: ["name" >> "entao"]).text();
    println(hr);
  });
}
