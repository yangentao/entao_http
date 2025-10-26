import 'package:entao_http/entao_http.dart';
import 'package:println/println.dart';
import 'package:test/test.dart';

void main() {
  test('echo', () async {
    HttpX hx = HttpX(
      before: (uri, params, headers) {
        headers["entao"] = "yang";
      },
    );
    HttpResult hr = await hx.get("http://localhost:8080/hole/pub/echo", name: "entao", age: 44, $locale: "zh_CN", $lang: "eng");
    println(hr.httpOK, hr.httpCode, hr.message);
    println(hr.bodyText);
  });
}
