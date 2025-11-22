import 'package:entao_dutil/entao_dutil.dart';
import 'package:entao_http/entao_http.dart';
import 'package:entao_result/entao_result.dart';
import 'package:println/println.dart';

void main() async {
  Result<String> hr = await httpGet("http://localhost:8080/hole/pub/echo".parsedUri, args: ["name" >> "entao"]);
  if (hr case Success(value: String v, extra: AnyMap map )) {
    println(v);
    // {"name":"entao","headers":{"accept-encoding":"gzip","host":"localhost:8080","user-agent":"Dart\/3.8 (dart:io)"}}
    println(map);
    // {content-type: application/json;charset=utf-8, date: Sat, 22 Nov 2025 07:02:08 GMT, content-length: 112}
  } else if (hr is Failure) {
    println(hr);
  }
}
