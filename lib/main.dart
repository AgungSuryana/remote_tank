import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dashboard.dart';
import 'mqtt_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky); // Fullscreen
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Inisialisasi MQTT Controller
  final mqttController = MqttController();

  runApp(MyApp(mqttController: mqttController));
}

class MyApp extends StatelessWidget {
  final MqttController mqttController;

  MyApp({required this.mqttController});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
       // Resolusi landscape
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        // Pastikan layout menggunakan dimensi layar perangkat
        return LayoutBuilder(
          builder: (context, constraints) {
            return MaterialApp(
              title: 'Game Tank Controller',
              theme: ThemeData(primarySwatch: Colors.blue),
              debugShowCheckedModeBanner: false,
              home: Container(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: Dashboard(mqttController: mqttController),
              ),
            );
          },
        );
      },
    );
  }
}
