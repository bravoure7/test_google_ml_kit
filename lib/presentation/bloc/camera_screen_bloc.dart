import 'dart:io';
import 'package:camera_app/presentation/model/detection_state.dart';
import 'package:camera_app/presentation/utils/painters/face_detector_painter.dart';
import 'package:camera_app/presentation/utils/painters/segmentation_painter.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_selfie_segmentation/google_mlkit_selfie_segmentation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:injectable/injectable.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';

import 'package:camera_app/presentation/utils/painters/pose_painter.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

@injectable
class CameraScreenBloc {
  CameraController _cameraController;
  final List<CameraDescription> _availableCameras;
  final DetectionState _detectionState;

  final BehaviorSubject<bool> _isFrontCameraSubject = BehaviorSubject.seeded(true);
  final BehaviorSubject<CameraController?> _cameraSubject = BehaviorSubject.seeded(null);
  final BehaviorSubject<CustomPaint?> _customPaintSubject = BehaviorSubject.seeded(null);
  final PoseDetector _poseDetector = PoseDetector(options: PoseDetectorOptions());
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableLandmarks: true,
    ),
  );
  final SelfieSegmenter _segmenter = SelfieSegmenter(
    mode: SegmenterMode.stream,
    enableRawSizeMask: true,
  );
  bool _isBusy = false;

  Stream<bool> get isFrontCameraStream => _isFrontCameraSubject.stream;

  Stream<CameraController?> get cameraStream => _cameraSubject.stream;

  Stream<CustomPaint?> get customPaintStream => _customPaintSubject.stream;

  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  CameraScreenBloc(
      {@factoryParam required List<CameraDescription> availableCameras,
      @factoryParam required DetectionState detectionState})
      : _availableCameras = availableCameras,
        _detectionState = detectionState,
        _cameraController = CameraController(
          availableCameras[1],
          ResolutionPreset.high,
          enableAudio: false,
          imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
        ) {
    _initCamera();
  }

  void _initCamera() async {
    _cameraController.initialize().then((_) {
      _cameraSubject.add(_cameraController);
      _cameraController.startImageStream(_processCameraImage);
    });
  }

  void _processCameraImage(CameraImage image) {
    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) return;
    _processImage(inputImage);
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    // get image rotation
    // it is used in android to convert the InputImage from Dart to Java: https://github.com/flutter-ml/google_ml_kit_flutter/blob/master/packages/google_mlkit_commons/android/src/main/java/com/google_mlkit_commons/InputImageConverter.java
    // `rotation` is not used in iOS to convert the InputImage from Dart to Obj-C: https://github.com/flutter-ml/google_ml_kit_flutter/blob/master/packages/google_mlkit_commons/ios/Classes/MLKVisionImage%2BFlutterPlugin.m
    // in both platforms `rotation` and `camera.lensDirection` can be used to compensate `x` and `y` coordinates on a canvas: https://github.com/flutter-ml/google_ml_kit_flutter/blob/master/packages/example/lib/vision_detector_views/painters/coordinates_translator.dart
    final camera = _availableCameras[_isFrontCameraSubject.value ? 1 : 0];
    final sensorOrientation = camera.sensorOrientation;

    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation = _orientations[_cameraController.value.deviceOrientation];
      if (rotationCompensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        // front-facing
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        // back-facing
        rotationCompensation = (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    if (rotation == null) return null;

    // get image format
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    // validate format depending on platform
    // only supported formats:
    // * nv21 for Android
    // * bgra8888 for iOS
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) return null;

    // since format is constraint to nv21 or bgra8888, both only have one plane
    if (image.planes.length != 1) return null;
    final plane = image.planes.first;

    // compose InputImage using bytes
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation, // used only in Android
        format: format, // used only in iOS
        bytesPerRow: plane.bytesPerRow, // used only in iOS
      ),
    );
  }

  Future<void> _processImage(InputImage inputImage) async {
    if (_isBusy) return;
    _isBusy = true;

    dynamic detector = _getDetectorByState(_detectionState);
    final processedImages = await detector.processImage(inputImage);
    final painter = _getPainterByState(_detectionState, processedImages, inputImage);

    painter == null ? _customPaintSubject.add(null) : _customPaintSubject.add(CustomPaint(painter: painter));
    _isBusy = false;
  }

  dynamic _getDetectorByState(DetectionState state) {
    Map<DetectionState, dynamic> detectors = {
      DetectionState.pose: _poseDetector,
      DetectionState.face: _faceDetector,
      DetectionState.segmentation: _segmenter
    };

    return detectors[state];
  }

  CustomPainter? _getPainterByState(DetectionState state, dynamic processedImages, InputImage inputImage) {
    if (inputImage.metadata?.size == null || inputImage.metadata?.rotation == null) {
      return null;
    }

    final CameraLensDirection cameraLensDirection =
        _isFrontCameraSubject.value ? CameraLensDirection.front : CameraLensDirection.back;
    final metadataSize = inputImage.metadata!.size;
    final metadataRotation = inputImage.metadata!.rotation;

    Map<DetectionState, CustomPainter Function()> painters = {
      DetectionState.pose: () => PosePainter(processedImages, metadataSize, metadataRotation, cameraLensDirection),
      DetectionState.face: () =>
          FaceDetectorPainter(processedImages, metadataSize, metadataRotation, cameraLensDirection),
      DetectionState.segmentation: () =>
          SegmentationPainter(processedImages, metadataSize, metadataRotation, cameraLensDirection)
    };

    return painters[state]?.call();
  }

  void changeCamera(bool isFrontCamera) {
    _isFrontCameraSubject.add(isFrontCamera);
    _cameraController = CameraController(
      isFrontCamera ? _availableCameras[1] : _availableCameras[0],
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
    );
    _initCamera();
  }

  void dispose() {
    _isFrontCameraSubject.close();
    _customPaintSubject.close();
    _cameraSubject.close();
    _cameraController.stopImageStream();
    _cameraController.dispose();
    _poseDetector.close();
    _faceDetector.close();
    _segmenter.close();
  }
}
