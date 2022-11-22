import 'package:intl/intl.dart' as intl;

const host = 'localhost';
const username = 'adriankohls';
const password = 'kohls123';

enum MqttTopics { event, test, rest }

enum PersonType { teacher, student, parent, headship }

extension StringExtension on String {
  PersonType? get toPersonType => _toPersonType(this);
  PersonType? _toPersonType(String? value) {
    PersonType? personType;
    switch (value) {
      case 'teacher':
        personType = PersonType.teacher;
        break;
      case 'student':
        personType = PersonType.student;
        break;
      case 'parent':
        personType = PersonType.parent;
        break;
      case 'headship':
        personType = PersonType.headship;
        break;
    }
    return personType;
  }

  MqttTopics? get toTopicEnum => _toTopicEnum(this);
  MqttTopics? _toTopicEnum(String? value) {
    MqttTopics? topic;
    switch (value) {
      case 'event':
        topic = MqttTopics.event;
        break;
      case 'test':
        topic = MqttTopics.test;
        break;
      case 'rest':
        topic = MqttTopics.rest;
        break;
      default:
    }
    return topic;
  }

  DateTime get toDateTime => _toDateTime(this);
  DateTime _toDateTime(String value) {
    final parsed = value.replaceAll('T', ' ');
    return intl.DateFormat('yyyy-MM-dd HH:mm:ss').parse(parsed);
  }
}
