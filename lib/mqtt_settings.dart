import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'mqtt_controller.dart';

class MqttSettings extends StatefulWidget {
  final MqttController mqttController;

  MqttSettings({required this.mqttController});

  @override
  _MqttSettingsState createState() => _MqttSettingsState();
}

class _MqttSettingsState extends State<MqttSettings> {
  final TextEditingController ipController = TextEditingController();
  final TextEditingController portController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    ipController.dispose();
    portController.dispose();
    super.dispose();
  }

  bool isValidIp(String ip) {
    final ipRegex = RegExp(
      r'^((25[0-5]|2[0-4][0-9]|[0-1]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[0-1]?[0-9][0-9]?)$',
    );
    return ipRegex.hasMatch(ip);
  }

  void connectMQTT() async {
    setState(() {
      isLoading = true;
    });

    String serverIp = ipController.text.trim();
    int port = int.tryParse(portController.text.trim()) ?? 0;

    // Validasi IP dan Port
    if (!isValidIp(serverIp) || port <= 0 || port > 65535) {
      Fluttertoast.showToast(
        msg: 'Masukkan IP Address dan Port yang valid!',
        backgroundColor: Colors.red,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      setState(() {
        isLoading = false;
      });
      return;
    }

    bool success = await widget.mqttController.connect(serverIp, port);

    setState(() {
      isLoading = false;
    });

    if (success) {
      Fluttertoast.showToast(
        msg: 'Connected to $serverIp:$port',
        backgroundColor: Colors.green,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );

      // Tutup dialog setelah berhasil
      Navigator.pop(context);
    } else {
      Fluttertoast.showToast(
        msg: 'Failed to connect to $serverIp:$port',
        backgroundColor: Colors.red,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.red, // Warna utama dialog
          borderRadius: BorderRadius.circular(12),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'MQTT Settings',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // Warna teks kontras dengan latar
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: ipController,
                decoration: InputDecoration(
                  labelText: 'IP Address',
                  labelStyle: TextStyle(color: Colors.white),
                  hintText: '192.168.1.1',
                  hintStyle: TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white24, // Warna input field
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: portController,
                decoration: InputDecoration(
                  labelText: 'Port',
                  labelStyle: TextStyle(color: Colors.white),
                  hintText: '1883',
                  hintStyle: TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white24, // Warna input field
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              if (isLoading)
                const CircularProgressIndicator()
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.red,
                      ),
                      onPressed: connectMQTT,
                      child: const Text('Connect'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

void showCustomDialog(BuildContext context, MqttController mqttController) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    pageBuilder: (context, _, __) {
      return MqttSettings(mqttController: mqttController);
    },
    transitionBuilder: (_, anim1, __, child) {
      return Transform.scale(
        scale: anim1.value,
        child: child,
      );
    },
  );
}
