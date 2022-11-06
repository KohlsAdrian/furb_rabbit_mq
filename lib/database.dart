import 'dart:developer';

import 'package:rabbit_mq/constants.dart';
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

  Future<List<PersonModel>> getPersons() async => await _getPerson();
  Future<PersonModel?> getPerson(String? id) async => await _getPerson(id);

  Future<PersonModel?> createPerson(
    String name,
    String email,
    String password,
    List<PersonType> types,
  ) async {
    final mTypes = types
        .map((e) => e.name)
        .toList()
        .toString()
        .replaceAll('[', '')
        .replaceAll(']', '')
        .replaceAll(' ', '');
    final query = 'INSERT INTO person (name, email, pswd, type) '
        'VALUES (\'$name\', \'$email\', \'$password\', \'$mTypes\', )';
    final result = _query(query);
    if (result != null) {}
  }

  Future<dynamic> _getPerson([String? id]) async {
    List<PersonModel> persons = [];
    final columns = id == null ? 'id, name' : 'id, name, type, email, topics';
    final query = 'SELECT $columns '
        'FROM person '
        '${id != null ? 'WHERE id LIKE \'$id\'' : ''}';
    final result = _query(query);
    if (result != null) {
      final rows = result.rows;
      persons = rows.map((row) {
        final topics = id == null ? <String>[] : row[4] as List<String>;
        return PersonModel(
          id: row[0].toString(),
          name: row[1].toString(),
          type: id != null ? row[2].toString() : null,
          email: id != null ? row[3].toString() : null,
          topics: topics,
        );
      }).toList();
      if (id != null) {
        return persons.isNotEmpty ? persons.first : null;
      }
    }
    return persons;
  }
}
