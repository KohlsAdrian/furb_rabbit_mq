import 'package:rabbit_mq/mqtt.dart' as mqtt;
import 'package:rabbit_mq/restful.dart' as restful;

void main(List<String> arguments) {
  mqtt.run('dart_backend');
  restful.initialize();
}
