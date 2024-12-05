import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'mqtt_controller.dart';
import 'mqtt_settings.dart';

class PlayPage extends StatefulWidget {
  final MqttController mqttController;

  const PlayPage({super.key, required this.mqttController});

  @override
  _PlayPageState createState() => _PlayPageState();
}

class _PlayPageState extends State<PlayPage> {
  bool isCommandInProgress = false;
  double hpValue = 1.0; // Nilai awal HP (1.0 = 100%)
  double volumeValue = 20.0; // Nilai awal volume (0 - 30)

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);

    // Subscribe ke topik getaran MQTT
    widget.mqttController.subscribe("esp32/vibration");
    widget.mqttController.listenToMessages((String topic, String message) {
      if (topic == "esp32/vibration") {
        handleVibration(message);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    widget.mqttController.unsubscribe("esp32/vibration");
  }

  void handleVibration(String message) {
    print('Message received: $message'); // Debug log
    final vibrationValue = int.tryParse(message) ?? 0;

    // Kurangi HP berdasarkan nilai getaran
    setState(() {
      if (vibrationValue >= 2500) {
        hpValue = (hpValue - 0.3).clamp(0.0, 1.0); // Kurangi 30%
      } else if (vibrationValue >= 2000) {
        hpValue = (hpValue - 0.2).clamp(0.0, 1.0); // Kurangi 20%
      } else if (vibrationValue >= 1000) {
        hpValue = (hpValue - 0.15).clamp(0.0, 1.0); // Kurangi 15%
      } else if (vibrationValue >= 500) {
        hpValue = (hpValue - 0.05).clamp(0.0, 1.0); // Kurangi 5%
      }

      // Jika HP mencapai 0
      if (hpValue <= 0.0) {
        showGameOverDialog();
      }
    });
  }

  void showGameOverDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Game Over"),
          content: const Text("HP Anda telah habis!"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Tutup dialog
                Navigator.pop(context); // Kembali ke halaman sebelumnya
              },
              child: const Text("Keluar"),
            ),
          ],
        );
      },
    );
  }

  Future<void> sendCommand(String topic, String message) async {
    if (isCommandInProgress) return;

    setState(() {
      isCommandInProgress = true;
    });

    try {
      await widget.mqttController.publishMessage(topic, message);
    } catch (e) {
      print('Error sending MQTT command: $e');
    } finally {
      setState(() {
        isCommandInProgress = false;
      });
    }
  }

  Widget buildControlButton({
    required IconData icon,
    required Color activeColor,
    required String topic,
    required double size,
  }) {
    return GestureDetector(
      onTapDown: (_) => sendCommand(topic, '1'),
      onTapUp: (_) => sendCommand(topic, '0'),
      child: CircleAvatar(
        radius: size,
        backgroundColor: isCommandInProgress ? Colors.grey : activeColor,
        child: Icon(
          icon,
          color: Colors.white,
          size: size * 0.6,
        ),
      ),
    );
  }

  Widget buildHpBar(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(
            Icons.local_shipping,
            color: Colors.green,
            size: 30,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: LinearProgressIndicator(
              value: hpValue,
              backgroundColor: Colors.red[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              minHeight: screenWidth * 0.02,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${(hpValue * 100).toInt()}%',
            style: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final buttonSize = screenWidth * 0.07;
    final smallButtonSize = screenWidth * 0.03;
    final buttonSpacing = screenWidth * 0.02;
    final buttontembak = screenWidth * 0.05;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          color: Colors.red,
          icon: const Icon(Icons.arrow_back),
          iconSize: 40.0,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: const Icon(
                Icons.settings,
                color: Colors.red,
              ),
              iconSize: 40.0,
              onPressed: () async {
                await showDialog(
                  context: context,
                  barrierDismissible: true,
                  builder: (context) => Center(
                    child: Material(
                      color: Colors.transparent,
                      child:
                          MqttSettings(mqttController: widget.mqttController),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: buildHpBar(context),
          ),
          Positioned(
            bottom: screenHeight * 0.05,
            left: screenWidth * 0.05,
            child: Row(
              children: [
                buildControlButton(
                  icon: Icons.arrow_upward,
                  activeColor: Colors.blue,
                  topic: '/control/maju',
                  size: buttonSize,
                ),
                SizedBox(width: buttonSpacing),
                buildControlButton(
                  icon: Icons.arrow_downward,
                  activeColor: Colors.blue,
                  topic: '/control/mundur',
                  size: buttonSize,
                ),
              ],
            ),
          ),
          Positioned(
            bottom: screenHeight * 0.05,
            right: screenWidth * 0.05,
            child: Row(
              children: [
                buildControlButton(
                  icon: Icons.arrow_back,
                  activeColor: Colors.blue,
                  topic: '/control/kiri',
                  size: buttonSize,
                ),
                SizedBox(width: buttonSpacing),
                buildControlButton(
                  icon: Icons.arrow_forward,
                  activeColor: Colors.blue,
                  topic: '/control/kanan',
                  size: buttonSize,
                ),
              ],
            ),
          ),
          Positioned(
            top: screenHeight * 0.30,
            right: screenWidth * 0.16,
            child: buildControlButton(
              icon: Icons.radio_button_checked,
              activeColor: Colors.red,
              topic: '/control/tembak',
              size: buttontembak,
            ),
          ),
          // Tombol Musik Berbaris Horizontal
          Positioned(
            top: screenHeight * 0.35,
            left: screenWidth * 0.07,
            child: Row(
              children: [
                buildControlButton(
                  icon: Icons.music_note,
                  activeColor: Colors.green,
                  topic: '/control/play_music_1',
                  size: smallButtonSize,
                ),
                SizedBox(width: buttonSpacing),
                buildControlButton(
                  icon: Icons.music_note,
                  activeColor: Colors.green,
                  topic: '/control/play_music_2',
                  size: smallButtonSize,
                ),
                SizedBox(width: buttonSpacing),
                buildControlButton(
                  icon: Icons.music_note,
                  activeColor: Colors.green,
                  topic: '/control/play_music_3',
                  size: smallButtonSize,
                ),
                SizedBox(width: buttonSpacing),
                buildControlButton(
                  icon: Icons.music_note,
                  activeColor: Colors.green,
                  topic: '/control/play_music_4',
                  size: smallButtonSize,
                ),
                SizedBox(width: buttonSpacing),
                buildControlButton(
                  icon: Icons.music_note,
                  activeColor: Colors.green,
                  topic: '/control/play_music_5',
                  size: smallButtonSize,
                ),
              ],
            ),
          ),
          Positioned(
            top: screenHeight * 0.55, // Posisi vertikal di bawah tombol musik
            left: screenWidth * 0.47, // Menyelarakan dengan tombol musik
            child: buildControlButton(
              icon: Icons.stop, // Ikon untuk tombol stop
              activeColor: Colors.red,
              topic: '/control/stop_music',
              size: smallButtonSize,
            ),
          ),
          // Slider Volume
          Positioned(
            top: screenHeight * 0.70, // Posisi di bawah tombol stop
            left: screenWidth * 0.35, // Mengatur posisi lebih ke tengah
            child: Column(
              children: [
                SizedBox(
                  width: screenWidth * 0.3, // Lebar slider dibuat lebih pendek
                  child: Slider(
                    value: volumeValue,
                    min: 0,
                    max: 30,
                    divisions: 30,
                    label: volumeValue.toInt().toString(),
                    onChanged: (value) {
                      setState(() {
                        volumeValue = value;
                      });
                    },
                    onChangeEnd: (value) {
                      sendCommand('/control/volume', value.toInt().toString());
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
