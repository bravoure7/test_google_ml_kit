import 'package:camera_app/common/theme/app_colors.dart';
import 'package:camera_app/presentation/model/detection_state.dart';
import 'package:camera_app/presentation/screen/camera_screen.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  static const routeName = '/home';

  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Test google ml kit'),
        centerTitle: true,
        backgroundColor: AppColors.blueGrey,
      ),
      body: const Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NavigationCard(
              'Face Detection',
              detectionState: DetectionState.face,
            ),
            SizedBox(height: 16.0),
            NavigationCard(
              'Pose Detection',
              detectionState: DetectionState.pose,
            ),
            SizedBox(height: 16.0),
            NavigationCard(
              'Segmentation',
              detectionState: DetectionState.segmentation,
            ),
          ],
        ),
      ),
    );
  }
}

class NavigationCard extends StatelessWidget {
  final String label;
  final DetectionState detectionState;

  const NavigationCard(this.label, {super.key, required this.detectionState});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.grey,
      child: ListTile(
        title: Text(label, textAlign: TextAlign.center),
        onTap: () {
          Navigator.pushNamed(context, CameraScreen.routeName, arguments: detectionState);
        },
      ),
    );
  }
}
