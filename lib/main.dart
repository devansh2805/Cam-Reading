import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:export_video_frame/export_video_frame.dart';
import 'package:image/image.dart';
import 'package:stats/stats.dart';

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

  @override
  void initState() {
    super.initState();
    _cameraController = CameraController(
      widget.camera,
      ResolutionPreset.low,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          ImageCache().clear();
          try {
            await _initializeControllerFuture;
            await _cameraController.setFlashMode(FlashMode.torch);
            await _cameraController.startVideoRecording();
            int _start = 25;
            Timer.periodic(
              const Duration(seconds: 1),
              (Timer timer) {
                if (_start == 0) {
                  setState(() {
                    timer.cancel();
                  });
                } else {
                  setState(() {
                    _start--;
                  });
                }
              },
            );
            XFile video = await _cameraController.stopVideoRecording();
            await _cameraController.setFlashMode(FlashMode.off);
            calculateParamters(video);
          } catch (e) {
            print(e);
          }
        },
        label: const Text("Take Reading"),
        icon: const Icon(Icons.camera_alt),
      ),
    );
  }

  void calculateParamters(XFile xFile) {
    List<int> redValues = [];
    List<int> blueValues = [];
    ExportVideoFrame.exportImage(xFile.path, 600, 1).then(
      (images) {
        for (var image in images) {
          final Uint8List inputImg = image.readAsBytesSync();
          final decoder = JpegDecoder();
          final decodedImg = decoder.decodeImage(inputImg);
          final decodedBytes = decodedImg?.getBytes(format: Format.rgb);
          for (int y = 0; y < decodedImg!.height; y++) {
            for (int x = 0; x < decodedImg.width; x++) {
              redValues.add(decodedBytes![y * decodedImg.width * 3 + x * 3]);
              blueValues
                  .add(decodedBytes[y * decodedImg.width * 3 + x * 3 + 2]);
            }
          }
          calculatOxygen(redValues, blueValues);
          print(_spo2);
        }
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
