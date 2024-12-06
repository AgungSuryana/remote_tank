import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'mqtt_controller.dart';
import 'mqtt_settings.dart';
import 'play.dart';
import 'package:google_fonts/google_fonts.dart';

class Dashboard extends StatefulWidget {
  final MqttController mqttController;

  const Dashboard({Key? key, required this.mqttController}) : super(key: key);

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  @override
  void initState() {
    super.initState();
    precacheImage(AssetImage('assets/bg.jpg'), context);
    // Mengunci layar dalam orientasi landscape
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Hide system UI (status bar and navigation bar)
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
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
              // Background Foto
              Positioned.fill(
                child: Image.asset(
                  'assets/bg.webp', // Path ke gambar background Anda
                  fit: BoxFit.cover, // Gambar memenuhi seluruh layar
                ),
              ),

              // Tombol dan Konten
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Adjust the height dynamically based on the screen size
                  SizedBox(
                      height: MediaQuery.of(context).size.height *
                          0.7), // 40% of screen height

                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Tombol Monitoring dengan latar putih dan teks merah
                      Container(
                        margin: EdgeInsets.only(left: 300.w),
                        child: SizedBox(
                          width: 250.w,
                          height: 60.h,
                          child: ElevatedButton(
                            onPressed: () {
                              print('Monitoring');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              padding: EdgeInsets.zero,
                            ),
                            child: Text(
                              'MONITORING',
                              style: GoogleFonts.ubuntu(
                                fontSize: 25.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 20.w), // Jarak antar tombol

                      // Tombol Play dengan border tanpa latar belakang
                      SizedBox(
                        width: 250.w,
                        height: 60.h,
                        child: OutlinedButton(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PlayPage(
                                  mqttController: widget.mqttController,
                                ),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Colors.white,
                              width: 2.0,
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: Text(
                            'PLAY',
                            style: GoogleFonts.ubuntu(
                              fontSize: 25.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Icon Settings di kiri atas
              Positioned(
                top: 10.h,
                left: 30.w,
                child: IconButton(
                  iconSize: 90.sp,
                  icon: const Icon(Icons.settings,
                      color: Color.fromARGB(255, 255, 255, 255)),
                  onPressed: () async {
                    await showDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (context) => Center(
                        child: Material(
                          color: Colors.transparent,
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
}
