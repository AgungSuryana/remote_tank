import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'mqtt_controller.dart';
import 'mqtt_settings.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  String vibrationText = "0";
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);

    // Mulai polling data dari API secara periodik
    _startPolling();
  }

  @override
  void dispose() {
    _timer?.cancel(); // Hentikan polling saat widget dihapus
    super.dispose();
  }

  void _startPolling() {
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      await _fetchVibrationData();
    });
  }

  Future<void> _fetchVibrationData() async {
    try {
      final response = await http
          .get(Uri.parse('https://backend-tank.vercel.app/api/piezzo'));

      if (response.statusCode == 200) {
        print('Raw response: ${response.body}'); // Debug respons mentah

        final data = json.decode(response.body);
        print('Decoded data: $data'); // Debug hasil decode

        // Pastikan ada elemen dalam array 'data'
        if (data['data'] != null && data['data'].isNotEmpty) {
          final firstItem = data['data'][0]; // Ambil elemen pertama dari array
          final vibrationValue =
              firstItem['vibrationLevel'] ?? 0; // Ambil vibrationLevel
          print(
              'Extracted vibration value: $vibrationValue'); // Debug nilai getaran

          // Menghindari perubahan HP jika polling pertama
          if (isFirstPoll) {
            setState(() {
              isFirstPoll = false; // Tandai polling pertama selesai
              lastVibrationValue =
                  vibrationValue; // Simpan nilai getaran pertama
            });
            return; // Jangan langsung update HP pada polling pertama
          }

          // Jika ada perubahan signifikan, baru lakukan pembaruan HP
          if (_isSignificantChange(vibrationValue)) {
            handleVibration(vibrationValue.toString());
            setState(() {
              lastVibrationValue =
                  vibrationValue; // Simpan nilai getaran terakhir
            });
          }
        } else {
          print('No vibration data available.');
        }
      } else {
        print('Failed to fetch data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching vibration data: $e');
    }
  }

  bool _isSignificantChange(int vibrationValue) {
    // Threshold perubahan dalam persentase
    const double percentageThreshold = 0.001; // 1% dari nilai sebelumnya

    // Threshold perubahan dalam nilai absolut
    const int absoluteThreshold = 1; // Minimal perubahan absolut 50

    // Perubahan absolut antara nilai getaran sekarang dan sebelumnya
    final int change = (vibrationValue - lastVibrationValue).abs();

    // Periksa apakah perubahan memenuhi salah satu dari dua kriteria
    return change >= lastVibrationValue * percentageThreshold ||
        change >= absoluteThreshold;
  }

  void handleVibration(String message) {
    print('Message received: $message'); // Debug log
    final vibrationValue = int.tryParse(message) ?? 0;
    print('Parsed vibration value: $vibrationValue'); // Debug log

    // Kurangi HP berdasarkan nilai getaran
    setState(() {
      vibrationText = message; // Simpan nilai getaran untuk ditampilkan
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

// Variabel untuk menyimpan nilai getaran terakhir
  int lastVibrationValue = 0;
  bool isFirstPoll = true; // Flag untuk mendeteksi polling pertama

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
      await widget.mqttController.publishMessage(topic, message, context);
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

    // Menentukan panjang yang lebih pendek untuk HP bar
    final barWidth = screenWidth * 0.6; // 50% dari lebar layar

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.center, // Menyusun elemen di tengah
        children: [
          Image.asset(
            'assets/icon.png', // Ganti dengan path gambar Anda
            width: 40, // Tentukan ukuran gambar sesuai kebutuhan
            height: 40, // Tentukan ukuran gambar sesuai kebutuhan
          ),
          const SizedBox(width: 10),
          // Membatasi lebar HP bar agar tidak terlalu panjang dan menempatkannya di tengah
          Container(
            width: barWidth, // Lebar yang sudah dibatasi
            child: LinearProgressIndicator(
              value: hpValue,
              backgroundColor: Colors.red[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              minHeight: 10, // Ukuran tinggi yang sesuai
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${(hpValue * 100).toInt()}%',
            style: const TextStyle(
                color: Color(0xFF800000), fontWeight: FontWeight.bold),
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
    final buttontembak = screenWidth * 0.04;

    return Scaffold(
      body: Stack(
        children: [
          // Background image (menggantikan AppBar)
          Positioned.fill(
            child: Image.asset(
              'assets/play.jpg', // Path gambar background
              fit: BoxFit.cover,
            ),
          ),

          // Ikon kembali dan pengaturan
          Positioned(
            top: 10,
            left: 10,
            child: IconButton(
              color: Color(0xFF800000),
              icon: const Icon(Icons.arrow_back),
              iconSize: 40.0,
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: IconButton(
              icon: const Icon(
                Icons.settings,
                color: Color(0xFF800000),
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

          // Konten lainnya
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: buildHpBar(context),
          ),
          Positioned(
            top: 70,
            left: 75,
            child: Text(
              "Damage: $vibrationText",
              style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF800000)),
            ),
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
            top: screenHeight * 0.45,
            right: screenWidth * 0.16,
            child: buildControlButton(
              icon: Icons.radio_button_checked,
              activeColor: const Color(0xFF800000),
              topic: '/control/tembak',
              size: buttontembak,
            ),
          ),
          // Tombol Musik Berbaris Horizontal
          Positioned(
            top: screenHeight * 0.45,
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
            top: screenHeight * 0.65, // Posisi vertikal di bawah tombol musik
            left: screenWidth * 0.47, // Menyelarakan dengan tombol musik
            child: buildControlButton(
              icon: Icons.stop, // Ikon untuk tombol stop
              activeColor: Color(0xFF800000),
              topic: '/control/stop_music',
              size: smallButtonSize,
            ),
          ),
          // Slider Volume
          Positioned(
            top: screenHeight * 0.80, // Posisi di bawah tombol stop
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
