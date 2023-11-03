import 'package:camera/camera.dart';
import 'package:camera_app/di/di.dart';
import 'package:camera_app/presentation/screen/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:camera_app/presentation/screen/camera_screen.dart';
import 'package:injectable/injectable.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies(Environment.dev);
  final List<CameraDescription> cameras = await availableCameras();

  runApp(MyApp(availableCameras: cameras));
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> availableCameras;

  const MyApp({super.key, required this.availableCameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: HomeScreen.routeName,
      routes: {
        HomeScreen.routeName: (context) => const HomeScreen(),
        CameraScreen.routeName: (context) => CameraScreen(
              camera: availableCameras,
            ),
      },
    );
  }
}
