import 'package:entao_http/entao_http.dart';
import 'package:entao_result/entao_result.dart';
import 'package:println/println.dart';
import 'package:test/test.dart';

void main() {
  test('int', () async {
    Success r = Success(12);
    println(r.value);
    expect(r.value, equals(12));
  });

  test('int_to_string', () async {
    Success r = Success(223);
    String s = r.transform((int n) => n.toString());
    println(s);
    expect(s, equals("223"));
  });

  test('List<int>', () async {
    Success r = Success([1, 2, 3]);
    List<int> ls = r.list();
    println(ls);
    expect(ls, equals([1, 2, 3]));
  });
  test('List<int> to List<String>', () async {
    Success r = Success([4, 5, 6]);
    List<String> ls = r.listValue((int n) => n.toString());
    println(ls);
    expect(ls, equals(["4", "5", "6"]));
  });
}
