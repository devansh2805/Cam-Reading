import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:export_video_frame/export_video_frame.dart';
import 'package:image/image.dart' as img;
import 'package:stats/stats.dart';
import 'OxygenMeasuringWidget.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final firstCamera = cameras.first;
  runApp(MaterialApp(
    theme: ThemeData.dark(),
    home: TakePictureScreen(camera: firstCamera),
  ));
}

class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({
    Key? key,
    required this.camera,
  }) : super(key: key);

  final CameraDescription camera;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _cameraController;
  late Future<void> _initializeControllerFuture;
  num _spo2 = 0;
  bool _recordingOn = false;

  @override
  void initState() {
    super.initState();
    _cameraController = CameraController(
      widget.camera,
      ResolutionPreset.low,
      enableAudio: false,
    );
    _initializeControllerFuture = _cameraController.initialize();
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Take a Picture')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_cameraController);
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: Visibility(
        visible: !_recordingOn,
        child: FloatingActionButton.extended(
          onPressed: () async {
            ImageCache().clear();
            if (await Directory(
                    '/data/user/0/com.example.cam_reading/app_ExportImage')
                .exists()) {
              Directory('/data/user/0/com.example.cam_reading/app_ExportImage')
                  .deleteSync(recursive: true);
            }
            try {
              await _initializeControllerFuture;
              _cameraController.setFlashMode(FlashMode.torch).then(
                (value) {
                  _cameraController.startVideoRecording().then(
                    (value) async {
                      setState(() {
                        _recordingOn = true;
                      });
                      BuildContext dialogContext = context;
                      showDialog(
                        context: context,
                        builder: (context) {
                          dialogContext = context;
                          return const OxygenMeasuringWidget();
                        },
                      );
                      Future.delayed(
                        const Duration(
                          seconds: 20,
                        ),
                        () async {
                          _cameraController.stopVideoRecording().then(
                            (value) {
                              calculateParamters(value);
                              Navigator.pop(dialogContext);
                              _cameraController
                                  .setFlashMode(FlashMode.off)
                                  .then((value) {
                                setState(() {
                                  _recordingOn = false;
                                });
                              });
                            },
                          );
                        },
                      );
                    },
                  );
                },
              );
            } on CameraException catch (e) {
              print(e);
            }
          },
          label: const Text("Take Reading"),
          icon: const Icon(Icons.camera_alt),
        ),
      ),
    );
  }

  void calculateParamters(XFile xFile) {
    List<int> redValues = [];
    List<int> blueValues = [];
    ExportVideoFrame.exportImage(xFile.path, 400, 1).then(
      (images) async {
        for (var image in images) {
          print(image.path);
          final Uint8List inputImg = await image.readAsBytes();
          final decoder = img.PngDecoder();
          final decodedImg = decoder.decodeImage(inputImg);
          final decodedBytes = decodedImg?.getBytes(format: img.Format.rgb);
          for (int y = 0; y < decodedImg!.height; y++) {
            for (int x = 0; x < decodedImg.width; x++) {
              redValues.add(decodedBytes![y * decodedImg.width * 3 + x * 3]);
              blueValues
                  .add(decodedBytes[y * decodedImg.width * 3 + x * 3 + 2]);
            }
          }
        }
        calculatOxygen(redValues, blueValues);
        print(_spo2);
      },
    );
  }

  void calculatOxygen(List<int> red, List<int> blue) {
    final redStats = Stats.fromData(red);
    final blueStats = Stats.fromData(blue);
    num mr = redStats.average;
    num mb = blueStats.average;
    num sdr = redStats.standardDeviation;
    num sdb = blueStats.standardDeviation;
    setState(() {
      _spo2 = 100 - 5 * ((sdr / mr) / (sdb / mb));
    });
  }
}
