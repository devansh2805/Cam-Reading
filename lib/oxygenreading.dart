import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:export_video_frame/export_video_frame.dart';
import 'package:image/image.dart' as img;
import 'package:stats/stats.dart';
import 'communication.dart';

class OxygenReading extends StatefulWidget {
  const OxygenReading({
    Key? key,
    required this.camera,
  }) : super(key: key);

  final CameraDescription camera;

  @override
  OxygenReadingState createState() => OxygenReadingState();
}

class OxygenReadingState extends State<OxygenReading> {
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
      appBar: AppBar(title: const Text('Blood Oxygen Saturation')),
      backgroundColor: const Color(0xFFffffff),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (_recordingOn) {
              return SafeArea(
                child: Container(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Center(
                        child: CircularProgressIndicator(),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Center(
                        child: Text(
                          "Measuring SpO2.....",
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Center(
                        child: Text(
                          "Keep Finger on Camera and Torch",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            } else {
              return SafeArea(
                child: Container(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 10),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(12, 8, 12, 8),
                        child: Text(
                          'Ensure that you place finger on torch and camera before starting.',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Sp02: " + _spo2.toString(),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      CameraPreview(_cameraController)
                    ],
                  ),
                ),
              );
            }
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
                      Future.delayed(
                        const Duration(
                          seconds: 20,
                        ),
                        () async {
                          _cameraController.stopVideoRecording().then(
                            (value) {
                              calculateParamters(value, () {
                                _cameraController
                                    .setFlashMode(FlashMode.off)
                                    .then((value) {
                                  setState(() {
                                    _recordingOn = false;
                                  });
                                  Navigator.pop(
                                    context,
                                    _spo2.round().toString() + " %",
                                  );
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

  void calculateParamters(XFile xFile, Function _callback) {
    List<int> redValues = [];
    List<int> blueValues = [];
    ExportVideoFrame.exportImage(xFile.path, 400, 1).then(
      (images) async {
        for (var image in images) {
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
        _callback();
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
      _spo2 = (99 - 5 * ((sdr / mr) / (sdb / mb))).round();
    });
  }
}
