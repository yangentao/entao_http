import 'package:entao_dutil/entao_dutil.dart';
import 'package:entao_http/entao_http.dart';
import 'package:println/println.dart';
import 'package:test/test.dart';

void main() {
  test('echo', () async {
    HttpResult hr = await httpGet(Uri.parse("http://localhost:8080/hole/pub/echo"), args: ["name" >> "entao", "age" >> 44], headers: {"locale": "zh_CN"});
    println(hr.code, hr.message);
    // 200 OK
    println(hr.bodyText);
    // {"age":"44","name":"entao","headers":{"accept-encoding":"gzip","host":"localhost:8080","locale":"zh_CN","user-agent":"Dart\/3.8 (dart:io)"}}
  });
}
