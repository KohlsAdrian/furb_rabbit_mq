import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:rabbit_mq/constants.dart';

import 'database.dart';

final client = MqttServerClient(host, '');
int pongCount = 0;

Future<void> run(String identifier) async {
  /// A websocket URL must start with ws:// or wss:// or Dart will throw an exception, consult your websocket MQTT broker
  /// for details.
  /// To use websockets add the following lines -:
  /// client.useWebSocket = true;
  /// client.port = 80;  ( or whatever your WS port is)
  /// There is also an alternate websocket implementation for specialist use, see useAlternateWebSocketImplementation
  /// Note do not set the secure flag if you are using wss, the secure flags is for TCP sockets only.
  /// You can also supply your own websocket protocol list or disable this feature using the websocketProtocols
  /// setter, read the API docs for further details here, the vast majority of brokers will support the client default
  /// list so in most cases you can ignore this.
  /// Set logging on if needed, defaults to off
  /// client.logging(on: false);

  /// Set the correct MQTT protocol for mosquito
  client.setProtocolV311();

  /// If you intend to use a keep alive you must set it here otherwise keep alive will be disabled.
  client.keepAlivePeriod = 20;

  /// The connection timeout period can be set if needed, the default is 5 seconds.
  client.connectTimeoutPeriod = 2000; // milliseconds

  /// Add the unsolicited disconnection callback
  client.onDisconnected = onDisconnected;

  /// Add the successful connection callback
  client.onConnected = onConnected;

  /// Add a subscribed callback, there is also an unsubscribed callback if you need it.
  /// You can add these before connection or change them dynamically after connection if
  /// you wish. There is also an onSubscribeFail callback for failed subscriptions, these
  /// can fail either because you have tried to subscribe to an invalid topic or the broker
  /// rejects the subscribe request.
  client.onSubscribed = onSubscribed;

  /// Set a ping received callback if needed, called whenever a ping response(pong) is received
  /// from the broker.
  /// client.pongCallback = pong;

  /// Create a connection message to use or use the default one. The default one sets the
  /// client identifier, any supplied username/password and clean session,
  /// an example of a specific one below.
  final connMess = MqttConnectMessage()
      .withClientIdentifier(identifier)
      .startClean() // Non persistent session for testing
      .withWillQos(MqttQos.atLeastOnce);

  client.connectionMessage = connMess;

  /// Connect the client, any errors here are communicated by raising of the appropriate exception. Note
  /// in some circumstances the broker will just disconnect us, see the spec about this, we however will
  /// never send malformed messages.
  try {
    await client.connect(username, password);
  } on NoConnectionException catch (_) {
    // Raised by the client when connection fails.

    client.disconnect();
  } on SocketException catch (_) {
    // Raised by the socket layer

    client.disconnect();
  }

  /// Check we are connected
  if (client.connectionStatus!.state == MqttConnectionState.connected) {
  } else {
    /// Use status here rather than state if you also want the broker return code.
    client.disconnect();
  }

  /// Ok, lets try a subscription
  for (final topic in MqttTopics.values) {
    subscribe(topic.name);
  }

  /// The client has a change notifier object(see the Observable class) which we then listen to to get
  /// notifications of published updates to each subscribed topic.
  client.updates?.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
    final recMess = c![0].payload as MqttPublishMessage;
    final pt =
        MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

    /// The above may seem a little convoluted for users only interested in the
    /// payload, some users however may be interested in the received publish message,
    /// lets not constrain ourselves yet until the package has been in the wild
    /// for a while.
    /// The payload is a byte buffer, this will be specific to the topic

    print(pt);
  });

  /// If needed you can listen for published messages that have completed the publishing
  /// handshake which is Qos dependant. Any message received on this stream has completed its
  /// publishing handshake with the broker.
  client.published?.listen((MqttPublishMessage message) {
    final topic = message.variableHeader?.topicName;
    final data = utf8.decode(message.payload.message);
    if (data.isNotEmpty) {
      try {
        final jsonObject = jsonDecode(data);
        if (MqttTopics.values.map((e) => e.name).contains(topic)) {
          Database.instance.insertMessage(jsonObject, topic!);
        }
      } catch (e) {
        print(e.toString());
      }
    }
  });
}

Future<void> sleep() async {
  /// Ok, we will now sleep a while, in this gap you will see ping request/response
  /// messages being exchanged by the keep alive mechanism.

  await MqttUtilities.asyncSleep(60);
}

Future<void> disconnect() async {
  /// Wait for the unsubscribe message from the broker if you wish.
  await MqttUtilities.asyncSleep(2);

  client.disconnect();
}

void usubscribe(String topic) {
  /// Finally, unsubscribe and exit gracefully

  client.unsubscribe(topic);
}

void subscribe(String topic) {
  /// Lets publish to our topic
  /// Use the payload builder rather than a raw buffer
  /// Our known topic to publish to
  final pubTopic = topic;
  final builder = MqttClientPayloadBuilder();

  /// Subscribe to it

  client.subscribe(pubTopic, MqttQos.exactlyOnce);

  /// Publish it

  client.publishMessage(pubTopic, MqttQos.exactlyOnce, builder.payload!);
}

/// The subscribed callback
void onSubscribed(String topic) {
  log('Subscribed to $topic');
}

/// The unsolicited disconnect callback
void onDisconnected() {}

/// The successful connect callback
void onConnected() {}

/// Pong callback
void pong() {
  pongCount++;
}
