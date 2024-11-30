import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'mqtt_controller.dart';
import 'mqtt_settings.dart'; // Pastikan untuk mengimpor file mqtt_settings.dart

class PlayPage extends StatefulWidget {
  final MqttController mqttController;

  const PlayPage({super.key, required this.mqttController});

  @override
  _PlayPageState createState() => _PlayPageState();
}

class _PlayPageState extends State<PlayPage> {
  bool isCommandInProgress = false;
  double hpValue = 1.0; // Nilai awal HP (1.0 = 100%)

  @override
  void initState() {
    super.initState();
    // Mengunci orientasi ke landscape saat berada di PlayPage
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    super.dispose();
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
          // Ikon tank
          const Icon(
            Icons.local_shipping, // Ikon tank bawaan Flutter
            color: Colors.green,
            size: 30,
          ),
          const SizedBox(width: 10),
          // Bar HP
          Expanded(
            child: LinearProgressIndicator(
              value: hpValue, // Nilai HP (0.0 hingga 1.0)
              backgroundColor: Colors.red[200],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              minHeight: screenWidth * 0.02, // Tinggi bar responsif
            ),
          ),
          const SizedBox(width: 10),
          // Teks persentase HP
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
    final smallButtonSize = screenWidth * 0.05;
    final buttonSpacing = screenWidth * 0.02;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          color: Colors.red,
          icon: const Icon(Icons.arrow_back),
          iconSize: 40.0,
          onPressed: () {
            Navigator.pop(context); // Kembali ke halaman sebelumnya
          },
        ),
        actions: [
          // Tombol pengaturan di sebelah kanan AppBar
          Padding(
            padding: const EdgeInsets.only(
                right: 16.0), 
            child: IconButton(
              icon: const Icon(
                Icons.settings,
                color: Colors.red,
              ),
              iconSize: 40.0,
              onPressed: () async {
                // Menampilkan dialog pengaturan MQTT
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
          // Bar HP di bagian atas layar
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: buildHpBar(context),
          ),

          // Kontrol maju dan mundur di kiri bawah
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

          // Kontrol kiri dan kanan di kanan bawah
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

          // Tombol "tembak" di kanan atas
          Positioned(
            top: screenHeight * 0.25,
            right: screenWidth * 0.15,
            child: buildControlButton(
              icon: Icons.radio_button_checked,
              activeColor: Colors.red,
              topic: '/control/tembak',
              size: smallButtonSize,
            ),
          ),

          // Tombol geser kiri dan kanan di kiri atas
          Positioned(
            top: screenHeight * 0.25,
            left: screenWidth * 0.09,
            child: Row(
              children: [
                buildControlButton(
                  icon: Icons.arrow_left,
                  activeColor: Colors.blue,
                  topic: '/control/geser_kiri',
                  size: smallButtonSize,
                ),
                SizedBox(width: buttonSpacing),
                buildControlButton(
                  icon: Icons.arrow_right,
                  activeColor: Colors.blue,
                  topic: '/control/geser_kanan',
                  size: smallButtonSize,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
