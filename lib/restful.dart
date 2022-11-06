import 'dart:async';
import 'dart:convert' as convert;

import 'package:jaguar/serve/server.dart';
import 'package:rabbit_mq/database.dart';

Future<void> initialize() async {
  final server = Jaguar();

  server
    ..get('/persons', (context) async {
      final persons = await getPersons();
      return _Response.ok(persons);
    })
    ..get('/persons/:id', (context) async {
      final id = context.pathParams.get('id').toString();
      final person = await getPerson(id);
      return _Response.ok(person);
    });

  await server.serve();
}

FutureOr<List<Map<String, dynamic>>> getPersons() async {
  final persons = await Database.instance.getPersons();
  return persons.map((e) => e.toMap()).toList();
}

FutureOr<Map<String, dynamic>> getPerson(String id) async {
  final person = await Database.instance.getPerson(id);
  return person?.toMap() ?? {};
}

class _Response {
  static dynamic ok(dynamic data) => convert.jsonEncode(data ?? {});
}
