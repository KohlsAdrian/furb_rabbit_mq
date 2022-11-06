import 'dart:developer';
import 'package:rabbit_mq/constants.dart';
import 'package:rabbit_mq/jwt.dart';
import 'package:rabbit_mq/models/person.dart';
import 'package:sqlite3/sqlite3.dart';

class Database {
  Database._();
  static final instance = Database._();

  ResultSet? _query(String query) {
    final database = sqlite3.open('furb.db');
    try {
      log(query);
      return database.select(query);
    } catch (e) {
      log(e.toString());
    } finally {
      database.dispose();
    }

    return null;
  }

  List<PersonModel> getPersons() => _getPerson();
  PersonModel? getPerson(String? id) => _getPerson(id);
  PersonModel? getPersonJwt(String token) => _getPersonJwt(token);

  bool updateTopics(
    String topics,
    String jwt,
  ) {
    return false;
  }

  String? login(String email, String password) {
    String query = 'SELECT id FROM person '
        'WHERE email LIKE \'$email\' '
        'AND pswd LIKE \'$password\'';
    ResultSet? result = _query(query);
    if (result != null && result.rows.isNotEmpty) {
      final id = result.rows[0][0];
      final token = Jwt.instance.token(email);
      query = 'UPDATE person '
          'SET jwt = \'$token\' '
          'WHERE id = \'$id\'';
      _query(query);
      result = _query('SELECT jwt FROM person WHERE id = \'$id\'');
      if (result != null && result.rows.isNotEmpty) {
        final jwt = result.rows[0][0];
        return jwt.toString();
      }
    }
    return null;
  }

  bool createPerson(
    String name,
    String email,
    String password,
    PersonType personType,
  ) {
    final personTypeName = personType.name;
    final query = 'INSERT INTO person (name, email, pswd, type) '
        'VALUES (\'$name\', \'$email\', \'$password\', \'$personTypeName\')';
    _query(query);
    final result = _query('SELECT id FROM person WHERE email LIKE \'$email\'');
    return result != null && result.isNotEmpty;
  }

  dynamic _getPerson([String? id]) {
    List<PersonModel> persons = [];
    final columns = id == null ? 'id, name' : 'id, name, type, email, topics';
    final query = 'SELECT $columns '
        'FROM person '
        '${id != null ? 'WHERE id == \'$id\'' : ''}';
    final result = _query(query);
    if (result != null) {
      final rows = result.rows;
      persons = rows.map((row) {
        String? topics = id == null ? null : (row[4] as String);
        final listTopics = topics == null ? <String>[] : topics.split(',');
        return PersonModel(
          id: row[0].toString(),
          name: row[1].toString(),
          type: id != null ? row[2].toString() : null,
          email: id != null ? row[3].toString() : null,
          topics: listTopics,
        );
      }).toList();
      if (id != null) {
        return persons.isNotEmpty ? persons.first : null;
      }
    }
    return persons;
  }

  dynamic _getPersonJwt(String token) {
    List<PersonModel> persons = [];
    final query = 'SELECT id, name, type, email, topics '
        'FROM person '
        'WHERE jwt == \'$token\'';
    final result = _query(query);
    if (result != null) {
      final rows = result.rows;
      persons = rows.map((row) {
        String? topics = row[4] as String;
        final listTopics = topics.split(',');
        return PersonModel(
          id: row[0].toString(),
          name: row[1].toString(),
          type: row[2].toString(),
          email: row[3].toString(),
          topics: listTopics,
        );
      }).toList();
      if (persons.isNotEmpty) {
        return persons.first;
      }
    }
    return null;
  }
}