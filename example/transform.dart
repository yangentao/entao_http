import 'package:entao_dutil/entao_dutil.dart';
import 'package:entao_http/entao_http.dart';
import 'package:entao_result/entao_result.dart';
import 'package:println/println.dart';

void main() async {
  Success<String> r = Success("123");
  int? n = r.transform((String s) {
    return s.toInt;
  });
  println(n);
}
