import 'dart:async';
import 'dart:convert' as convert;

import 'package:http/http.dart' as http;
import 'package:jaguar/jaguar.dart';
import 'package:jaguar/serve/server.dart';
import 'package:rabbit_mq/constants.dart';
import 'package:rabbit_mq/database.dart';
import 'package:rabbit_mq/jwt.dart';

Future<void> initialize() async {
  final server = Jaguar(
    address: 'localhost',
    port: 8080,
    multiThread: true,
  );

  server
    /* test purposes only
    ..get('/persons', (context) async {
      final persons = await getPersons();
      return _Response.ok(persons);
    })
    ..get('/persons/:id', (context) async {
      final id = context.pathParams.get('id').toString();
      final person = await getPerson(id);
      return _Response.ok(person);
    }) */
    ..get('/persons/me', (context) {
      final jwt = context.headers.value('authorization') ?? '';
      if (!Jwt.instance.validateUser(jwt)) {
        return _Response.ok({'error': 'invalid JWT'});
      }
      final person = getPersonByJwt(jwt);
      return _Response.ok(person);
    })
    ..post('/persons', (context) async {
      final body = await context.bodyAsJsonMap();
      final name = body['name'] ?? '';
      final email = body['email'];
      final password = body['password'];
      final type = body['type'] ?? '';
      final ok = createPerson(name, email, password, type);
      return _Response.ok(ok);
    })
    ..post('/login', (context) async {
      final body = await context.bodyAsJsonMap();
      final email = body['email'];
      final password = body['password'];
      final jwt = login(email, password);
      return _Response.ok({'jwt': jwt});
    })
    ..get('/topics', (context) {
      final topics = MqttTopics.values.map((e) => e.name).toList();
      return _Response.ok(topics);
    })
    ..get('/topics/me', (context) {
      final jwt = context.headers.value('authorization') ?? '';
      if (!Jwt.instance.validateUser(jwt)) {
        return _Response.ok({'error': 'invalid JWT'});
      }
      final topics = getPersonTopics(jwt);
      return _Response.ok(topics);
    })
    ..patch('/topics', (context) async {
      final jwt = context.headers.value('authorization') ?? '';
      if (!Jwt.instance.validateUser(jwt)) {
        return _Response.ok({'error': 'invalid JWT'});
      }
      final body = (await context.bodyAsJsonList());
      final topics = body?.map((e) => e.toString()).toList();
      final success = updateTopics(topics ?? [], jwt);
      return _Response.ok({'success': success});
    })
    ..get('/messages', (context) {
      final jwt = context.headers.value('authorization') ?? '';
      if (!Jwt.instance.validateUser(jwt)) {
        return _Response.ok({'error': 'invalid JWT'});
      }
      final messages = getMessages(jwt);
      return _Response.ok(messages);
    })
    ..post('/message', (context) async {
      final jwt = context.headers.value('authorization') ?? '';
      if (!Jwt.instance.validateUser(jwt)) {
        return _Response.ok({'error': 'invalid JWT'});
      }
      final body = await context.bodyAsJsonMap();

      final message = body['message'] ?? '';
      final type = body['type'] ?? '';
      final dateStart = body['date_start'] ?? '';
      final dateEnd = body['date_end'] ?? '';
      final success = await createMessage(
        message: message,
        type: type,
        dateStart: dateStart,
        dateEnd: dateEnd,
      );
      return _Response.ok({'success': success});
    });

  await server.serve(logRequests: true);
}

List<dynamic> getMessages(String? jwt) {
  final messages = Database.instance.getMessages(jwt);
  return messages;
}

Future<bool> createMessage({
  required String message,
  required String type,
  required String dateStart,
  required String dateEnd,
}) async {
  MqttTopics? topic;
  switch (type) {
    case 'event':
      topic = MqttTopics.event;
      break;
    case 'rest':
      topic = MqttTopics.rest;
      break;
    case 'test':
      topic = MqttTopics.test;
      break;
  }
  if (topic == null) return false;

  final response = await http.post(
    Uri.parse('http://localhost:15672/api/exchanges/%2F/publish'),
    headers: {'Authorization': '$username:$password'},
    body: {
      'routing_key': topic.name,
      'properties': {},
      'payload_encoding': 'string',
      'payload': convert.jsonEncode(
        {
          'message': message,
          'dateStart': dateStart.toDateTime.toIso8601String(),
          'dateEnd': dateEnd.toDateTime.toIso8601String(),
          'type': topic.name,
        },
      ),
    },
  );
  return response.statusCode >= 200 && response.statusCode <= 400;
}

bool updateTopics(List<String> topics, String jwt) {
  final mTopics = topics.map((topic) {
    switch (topic) {
      case 'event':
        return MqttTopics.event;
      case 'rest':
        return MqttTopics.rest;
      case 'test':
        return MqttTopics.test;
    }
    return null;
  }).where((element) => element != null);
  final topicsList = mTopics.map((e) => e?.name).toList();
  final jsonArrayTopics = convert.jsonEncode(topicsList);
  final success = Database.instance.updateTopics(jsonArrayTopics, jwt);
  return success;
}

List<String> getPersonTopics(String jwt) {
  final topics = Database.instance.getPersonTopics(jwt);
  return topics.map((e) => e.name).toList();
}

Map<String, dynamic> getPersonByJwt(String jwt) {
  final person = Database.instance.getPersonJwt(jwt);
  return person?.toMap() ?? {};
}

List<Map<String, dynamic>> getPersons() {
  final persons = Database.instance.getPersons();
  return persons.map((e) => e.toMap()).toList();
}

Map<String, dynamic> getPerson(String id) {
  final person = Database.instance.getPerson(id);
  return person?.toMap() ?? {};
}

bool createPerson(
  String name,
  String email,
  String password,
  String type,
) {
  PersonType personType = PersonType.student;
  switch (type) {
    case 'teacher':
      personType = PersonType.teacher;
      break;
    case 'parent':
      personType = PersonType.parent;
      break;
    case 'headship':
      personType = PersonType.headship;
      break;
  }
  final ok = Database.instance.createPerson(
    name,
    email,
    password,
    personType,
  );
  return ok;
}

String? login(String email, String password) =>
    Database.instance.login(email, password);

class _Response {
  static dynamic ok(dynamic data) => convert.jsonEncode(data ?? {});
}
