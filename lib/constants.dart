const host = 'jackal.rmq.cloudamqp.com';
const username = 'lnixlvfr:lnixlvfr';
const password = 'eRX8pkRaL99ai9FmgIlKLcjP_hjyb_Vw';

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
}
