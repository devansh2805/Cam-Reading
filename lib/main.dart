import 'package:cam_reading/heartratereading.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'oxygenreading.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final firstCamera = cameras.first;
  runApp(MaterialApp(
    theme: ThemeData.dark(),
    home: Reader(camera: firstCamera),
  ));
}

class Reader extends StatefulWidget {
  const Reader({
    Key? key,
    required this.camera,
  }) : super(key: key);

  final CameraDescription camera;

  @override
  State<StatefulWidget> createState() => ReaderState();
}

class ReaderState extends State<Reader> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reader'),
      ),
      body: Container(
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return Center(
                      child: Column(
                        children: [
                          const Text('Do you have Health Connect Device?'),
                          Row(
                            children: [
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const OxygenReadingDevice(),
                                    ),
                                  );
                                },
                                child: const Text('Yes'),
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => OxygenReading(
                                        camera: widget.camera,
                                      ),
                                    ),
                                  );
                                },
                                child: const Text("No"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              child: const Text(
                "Read SpO2",
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HeartRateReading(
                      camera: widget.camera,
                    ),
                  ),
                );
              },
              child: const Text(
                "Read Heart Rate",
              ),
            )
          ],
        ),
      ),
    );
  }
}
