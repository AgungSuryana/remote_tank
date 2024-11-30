import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player/video_player.dart'; // Import video player
import 'mqtt_controller.dart';
import 'mqtt_settings.dart';
import 'play.dart';

class Dashboard extends StatefulWidget {
  final MqttController mqttController;

  const Dashboard({Key? key, required this.mqttController}) : super(key: key);

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();

    // Mengunci layar dalam orientasi landscape
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // Mengatur mode fullscreen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky,
        overlays: [SystemUiOverlay.top]);

    // Inisialisasi video controller
    _initializeVideoController();
  }

  void _initializeVideoController() {
    _videoController = VideoPlayerController.asset('assets/tank.mp4')
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isVideoInitialized = true; // Set to true once video is initialized
          });
          _videoController.setLooping(true); // Looping video
          _videoController.play(); // Auto play
        }
      }).catchError((error) {
        // Tangani jika terjadi error
        print("Error loading video: $error");
        if (mounted) {
          setState(() {
            _isVideoInitialized = false;
          });
        }
      });
  }

  @override
  void dispose() {
    _videoController.dispose(); // Jangan lupa dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(1920, 1080),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return Scaffold(
          body: Stack(
            children: [
              // Background video (commented out)
              // if (_isVideoInitialized)
              //   SizedBox.expand(
              //     child: FittedBox(
              //       fit: BoxFit.cover, // Video memenuhi seluruh layar
              //       child: SizedBox(
              //         width: _videoController.value.size.width,
              //         height: _videoController.value.size.height,
              //         child: VideoPlayer(_videoController),
              //       ),
              //     ),
              //   ),

              // Overlay konten
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Bagian kiri: Sensor
                  Expanded(
                    flex: 2,
                    child: Container(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildSensorIndicator(
                                  label: 'Gas',
                                  value: 0.7,
                                  color: Colors.green),
                              _buildSensorIndicator(
                                  label: 'Temperature',
                                  value: 0.5,
                                  color: Colors.orange),
                              _buildSensorIndicator(
                                  label: 'Humidity',
                                  value: 0.3,
                                  color: Colors.blue),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Bagian kanan: Video dan tombol Play
                  Expanded(
                    flex: 3,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          margin: EdgeInsets.symmetric(horizontal: 20.w),
                          width: 1.sw * 0.45, // Perkecil sedikit
                          height: 1.sh * 0.45,
                          color: Colors.black,
                          child: Center(
                            child: _isVideoInitialized
                                ? VideoPlayer(
                                    _videoController) // Tampilkan video jika sudah siap
                                : CircularProgressIndicator(), // Tampilkan loading jika video belum siap
                          ),
                        ),
                        SizedBox(height: 30.h),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                horizontal: 70.w, vertical: 25.h),
                            backgroundColor: Colors.blue,
                          ),
                          onPressed: () async {
                            // Navigasi ke halaman PlayPage
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PlayPage(
                                  mqttController: widget.mqttController,
                                ),
                              ),
                            );
                          },
                          child: Text(
                            'PLAY TANK',
                            style:
                                TextStyle(fontSize: 30.sp, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Icon Settings di kanan atas
              Positioned(
                top: 30.h,
                right: 20.w,
                child: IconButton(
                  iconSize: 70.sp,
                  icon: const Icon(Icons.settings,
                      color: Color.fromARGB(255, 255, 7, 7)),
                  onPressed: () async {
                    await showDialog(
                      context: context,
                      barrierDismissible:
                          true, // Dialog dapat ditutup dengan mengetuk di luar
                      builder: (context) => Center(
                        child: Material(
                          color: Colors
                              .transparent, // Hilangkan latar belakang dialog bawaan
                          child: MqttSettings(
                            mqttController: widget.mqttController,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSensorIndicator(
      {required String label, required double value, required Color color}) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 26.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 15.h),
        Container(
          width: 160.w, // Lebar bar lebih besar
          height: 400.h, // Tinggi bar tetap besar
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 3),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: value, // Nilai antara 0.0 - 1.0
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
