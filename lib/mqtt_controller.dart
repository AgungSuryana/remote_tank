import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:flutter/foundation.dart';
import 'package:fluttertoast/fluttertoast.dart'; // Menambahkan import untuk ScaffoldMessenger

class MqttController {
  MqttServerClient? client; // Ubah menjadi nullable
  final ValueNotifier<bool> connectionStatus = ValueNotifier(false);

  // Fungsi untuk menghubungkan ke broker MQTT
  Future<bool> connect(String serverIp, int port) async {
    if (connectionStatus.value) {
      disconnect(); // Putuskan koneksi sebelumnya jika ada
    }

    client = MqttServerClient.withPort(serverIp, 'flutter_client', port);
    client?.logging(on: true); // Aktifkan log untuk debugging
    client?.keepAlivePeriod = 20; // Menjaga koneksi tetap hidup
    client?.onDisconnected = onDisconnected;
    client?.autoReconnect = true; // Otomatis reconnect jika terputus

    // Pesan koneksi
    final connMessage = MqttConnectMessage()
        .withClientIdentifier('flutter_client')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    client?.connectionMessage = connMessage;

    try {
      // ignore: avoid_print
      print('Connecting to MQTT broker...');
      await client?.connect();
    } catch (e) {
      // ignore: avoid_print
      print('Connection failed: $e');
      disconnect(); // Pastikan koneksi dilepas jika gagal
      return false;
    }

    if (client?.connectionStatus?.state == MqttConnectionState.connected) {
      // ignore: avoid_print
      print('Connected to MQTT broker');
      connectionStatus.value = true;
      return true; // Berhasil
    } else {
      // ignore: avoid_print
      print('Connection failed with state: ${client?.connectionStatus?.state}');
      disconnect();
      return false; // Gagal
    }
  }

  // Callback saat terputus dari broker MQTT
  void onDisconnected() {
    connectionStatus.value = false;
    // ignore: avoid_print
    print('Disconnected from MQTT broker');
  }

  // Fungsi untuk memutuskan koneksi dengan broker MQTT
  void disconnect() {
    if (connectionStatus.value && client != null) {
      client?.disconnect();
      connectionStatus.value = false;
      // ignore: avoid_print
      print('Disconnected');
    }
  }

  // Fungsi untuk mengirimkan pesan ke topic MQTT
  Future<void> publishMessage(
      String topic, String message, BuildContext context) async {
    if (client == null) {
      print("Client is not initialized yet.");
      Fluttertoast.showToast(
        msg: "anda belum terhubung",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return;
    }

    if (client?.connectionStatus?.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(message);
      try {
        client?.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
        // ignore: avoid_print
        print("Message published to topic $topic: $message");
      } catch (e) {
        // ignore: avoid_print
        print("Failed to publish message: $e");
      }
    } else {
      // ignore: avoid_print
      print("Cannot publish, client is not connected");
      Fluttertoast.showToast(
        msg: "Tidak dapat mengirim pesan, koneksi tidak ada",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  // Fungsi untuk subscribe ke topic
  Future<void> subscribe(String topic) async {
    if (client == null) {
      print("Client is not initialized yet.");
      return;
    }

    if (client?.connectionStatus?.state == MqttConnectionState.connected) {
      try {
        client?.subscribe(topic, MqttQos.atLeastOnce);
        // ignore: avoid_print
        print("Subscribed to topic $topic");
      } catch (e) {
        // ignore: avoid_print
        print("Failed to subscribe to topic $topic: $e");
      }
    } else {
      // ignore: avoid_print
      print("Cannot subscribe, client is not connected");
    }
  }

  // Fungsi untuk unsubscribe dari topic
  Future<void> unsubscribe(String topic) async {
    if (client == null) {
      print("Client is not initialized yet.");
      return;
    }

    if (client?.connectionStatus?.state == MqttConnectionState.connected) {
      try {
        client?.unsubscribe(topic);
        // ignore: avoid_print
        print("Unsubscribed from topic $topic");
      } catch (e) {
        // ignore: avoid_print
        print("Failed to unsubscribe from topic $topic: $e");
      }
    } else {
      // ignore: avoid_print
      print("Cannot unsubscribe, client is not connected");
    }
  }

  // Fungsi untuk mendengarkan pesan dari topic
  void listenToMessages(Function(String topic, String message) onMessage) {
    client?.updates
        ?.listen((List<MqttReceivedMessage<MqttMessage?>>? messages) {
      final recMessage = messages?[0].payload as MqttPublishMessage;
      final payload =
          MqttPublishPayload.bytesToStringAsString(recMessage.payload.message);

      // Menampilkan pesan yang diterima di log (untuk debugging)
      print('Message received on topic ${messages?[0].topic}: $payload');

      // Memanggil callback onMessage dengan topic dan pesan yang diterima
      onMessage(messages![0].topic, payload);
    });
  }
}
