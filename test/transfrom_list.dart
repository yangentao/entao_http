import 'package:entao_http/entao_http.dart';
import 'package:entao_result/entao_result.dart';
import 'package:println/println.dart';
import 'package:test/test.dart';

void main() {
  test('value', () async {
    Success r = Success(12);
    println(r.value);
    expect(r.value, equals(12));
  });

  test('transform', () async {
    Success r = Success(223);
    String s = r.transform((int n) => n.toString());
    println(s);
    expect(s, equals("223"));
  });

  test('list', () async {
    Success r = Success([1, 2, 3]);
    List<int> ls = r.list();
    println(ls);
    expect(ls, equals([1, 2, 3]));
  });
  test('listValue', () async {
    Success r = Success([4, 5, 6]);
    List<String> ls = r.listValue((int n) => n.toString());
    println(ls);
    expect(ls, equals(["4", "5", "6"]));
  });

  test('model', () async {
    Success r = Success({"id": 9, "name": "entao"});
    Person p = r.model(Person.new);
    println(p);
    expect(p.id, equals(9));
    expect(p.name, equals("entao"));
  });

  test('listModel', () async {
    Success r = Success([
      {"id": 9, "name": "entao"},
      {"id": 10, "name": "yang"}
    ]);
    List<Person> ps = r.listModel(Person.new);
    println(ps);
    expect(ps[0].id, equals(9));
    expect(ps[0].name, equals("entao"));
    expect(ps[1].id, equals(10));
    expect(ps[1].name, equals("yang"));
  });
  test('table', () async {
    Success r = Success([
      ["id", "name"],
      [9, "entao"],
      [10, "yang"],
    ]);
    List<Person> ps = r.table(Person.new);
    println(ps);
    expect(ps[0].id, equals(9));
    expect(ps[0].name, equals("entao"));
    expect(ps[1].id, equals(10));
    expect(ps[1].name, equals("yang"));
  });
}

class Person {
  Map<String, dynamic> model;

  Person(this.model);

  int get id => model["id"];

  String get name => model["name"];

  @override
  String toString() {
    return model.toString();
  }
}
