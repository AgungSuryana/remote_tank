import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:flutter/foundation.dart';

class MqttController {
  late MqttServerClient client;
  final ValueNotifier<bool> connectionStatus = ValueNotifier(false);

  // Inisialisasi client MQTT
  MqttController();

  // Fungsi untuk menghubungkan ke broker MQTT
  Future<bool> connect(String serverIp, int port) async {
    if (connectionStatus.value) {
      disconnect(); // Putuskan koneksi sebelumnya jika ada
    }

    client = MqttServerClient.withPort(serverIp, 'flutter_client', port);
    client.logging(on: true); // Aktifkan log untuk debugging
    client.keepAlivePeriod = 20; // Menjaga koneksi tetap hidup
    client.onDisconnected = onDisconnected;
    client.autoReconnect = true; // Otomatis reconnect jika terputus

    // Pesan koneksi
    final connMessage = MqttConnectMessage()
        .withClientIdentifier('flutter_client')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    client.connectionMessage = connMessage;

    try {
      print('Connecting to MQTT broker...');
      await client.connect();
    } catch (e) {
      print('Connection failed: $e');
      disconnect(); // Pastikan koneksi dilepas jika gagal
      return false;
    }

    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      print('Connected to MQTT broker');
      connectionStatus.value = true;
      return true; // Berhasil
    } else {
      print('Connection failed with state: ${client.connectionStatus?.state}');
      disconnect();
      return false; // Gagal
    }
  }

  // Callback saat terputus dari broker MQTT
  void onDisconnected() {
    connectionStatus.value = false;
    print('Disconnected from MQTT broker');
  }

  // Fungsi untuk memutuskan koneksi dengan broker MQTT
  void disconnect() {
    if (connectionStatus.value) {
      client.disconnect();
      connectionStatus.value = false;
      print('Disconnected');
    }
  }

  // Fungsi untuk mengirimkan pesan ke topic MQTT
  Future<void> publishMessage(String topic, String message) async {
    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(message);
      try {
        client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
        print("Message published to topic $topic: $message");
      } catch (e) {
        print("Failed to publish message: $e");
      }
    } else {
      print("Cannot publish, client is not connected");
    }
  }

  // Fungsi untuk subscribe ke topic
  Future<void> subscribe(String topic) async {
    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      try {
        client.subscribe(topic, MqttQos.atLeastOnce);
        print("Subscribed to topic $topic");
      } catch (e) {
        print("Failed to subscribe to topic $topic: $e");
      }
    } else {
      print("Cannot subscribe, client is not connected");
    }
  }

  // Fungsi untuk unsubscribe dari topic
  Future<void> unsubscribe(String topic) async {
    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      try {
        client.unsubscribe(topic);
        print("Unsubscribed from topic $topic");
      } catch (e) {
        print("Failed to unsubscribe from topic $topic: $e");
      }
    } else {
      print("Cannot unsubscribe, client is not connected");
    }
  }

  // Fungsi untuk mendengarkan pesan dari topic
  void listenToMessages(Function(String topic, String message) onMessage) {
    client.updates?.listen((List<MqttReceivedMessage<MqttMessage?>>? messages) {
      final recMessage = messages?[0].payload as MqttPublishMessage;
      final payload =
          MqttPublishPayload.bytesToStringAsString(recMessage.payload.message);

      print('Message received on topic ${messages?[0].topic}: $payload');
      onMessage(messages![0].topic, payload);
    });
  }
}
