import 'package:camera/camera.dart';
import 'package:camera_app/common/theme/app_colors.dart';
import 'package:camera_app/di/di.dart';
import 'package:camera_app/presentation/bloc/camera_screen_bloc.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CameraScreen extends StatelessWidget {
  static const routeName = '/camera';
  final List<CameraDescription> camera;

  const CameraScreen({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    final detectionState = ModalRoute.of(context)?.settings.arguments;
    return MultiProvider(
        providers: [
          Provider<CameraScreenBloc>(
            create: (_) => getIt<CameraScreenBloc>(
              param1: camera,
              param2: detectionState,
            ),
            dispose: (_, bloc) => bloc.dispose(),
          )
        ],
        child: Consumer<CameraScreenBloc>(builder: (context, cameraScreenBloc, _) {
          return StreamBuilder<bool>(
              stream: cameraScreenBloc.isFrontCameraStream,
              builder: (context, snapshot) {
                final bool isFrontCamera = snapshot.data ?? false;
                return StreamBuilder<CameraController?>(
                    stream: cameraScreenBloc.cameraStream,
                    builder: (context, snapshot) {
                      final CameraController? cameraController = snapshot.data;
                      if (cameraController == null) {
                        return const SizedBox.shrink();
                      }
                      return StreamBuilder<CustomPaint?>(
                          stream: cameraScreenBloc.customPaintStream,
                          builder: (context, snapshot) {
                            final CustomPaint? painter = snapshot.data;
                            return Scaffold(
                                body: Column(children: [
                              CameraPreview(
                                cameraController,
                                child: painter,
                              ),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                  color: AppColors.black,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Row(children: [
                                        GestureDetector(
                                          onTap: () {
                                            cameraScreenBloc.changeCamera(!isFrontCamera);
                                          },
                                          child: SizedBox(
                                            width: 50,
                                            child: Icon(
                                              isFrontCamera ? Icons.flip_camera_ios_outlined : Icons.flip_camera_ios,
                                              color: AppColors.white,
                                              size: 40,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: IconButton(
                                            onPressed: () {},
                                            iconSize: 70,
                                            icon: const Icon(
                                              Icons.circle,
                                              color: AppColors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 50,
                                        )
                                      ]),
                                    ],
                                  ),
                                ),
                              ),
                            ]));
                          });
                    });
              });
        }));
  }
}
