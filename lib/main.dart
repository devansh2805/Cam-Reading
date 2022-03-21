import 'dart:ui';
import 'package:cam_reading/heartrate.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'oxygenreading.dart';
import 'communication.dart';
import 'parameterreader.dart';

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
  Communication communication = Communication();
  String result = "";

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
            Text("Last Reading: $result"),
            const SizedBox(
              height: 10,
            ),
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 10.0,
                        sigmaY: 10.0,
                      ),
                      child: Dialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            20,
                          ),
                        ),
                        elevation: 5,
                        backgroundColor: Colors.indigo[50],
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height * 0.30,
                          width: MediaQuery.of(context).size.width - 10,
                          child: Center(
                            child: Column(
                              children: [
                                const Text(
                                  'Do you have Health Connect Device?',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) {
                                            return ParameterReader(
                                              communication: communication,
                                              bluetoothMessage: "Oxygen",
                                              title: "Oxygen Reading",
                                              sensorWaitingTime: 65,
                                            );
                                          }),
                                        ).then((value) {
                                          setState(() {
                                            result = value;
                                          });
                                        });
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
                                        ).then((value) {
                                          setState(() {
                                            result = value;
                                          });
                                        });
                                      },
                                      child: const Text("No"),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
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
                showDialog(
                  context: context,
                  builder: (context) {
                    return BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 10.0,
                        sigmaY: 10.0,
                      ),
                      child: Dialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            20,
                          ),
                        ),
                        elevation: 5,
                        backgroundColor: Colors.indigo[50],
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height * 0.30,
                          width: MediaQuery.of(context).size.width - 10,
                          child: Center(
                            child: Column(
                              children: [
                                const Text(
                                  'Do you have Health Connect Device?',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) {
                                            return ParameterReader(
                                              communication: communication,
                                              bluetoothMessage: "Heart Rate",
                                              title: "Heart Rate Reading",
                                              sensorWaitingTime: 65,
                                            );
                                          }),
                                        ).then((value) {
                                          setState(() {
                                            result = value;
                                          });
                                        });
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
                                            builder: (context) =>
                                                HeartRateCalculator(
                                              camera: widget.camera,
                                            ),
                                          ),
                                        ).then((value) {
                                          setState(() {
                                            result = value;
                                          });
                                        });
                                      },
                                      child: const Text("No"),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              child: const Text(
                "Read Heart Rate",
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) {
                    return ParameterReader(
                      communication: communication,
                      bluetoothMessage: "Temperature",
                      title: "Temperature Reading",
                      sensorWaitingTime: 125,
                    );
                  }),
                ).then((value) {
                  result = value;
                });
              },
              child: const Text(
                "Read Temperature",
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) {
                    return ParameterReader(
                      communication: communication,
                      bluetoothMessage: "Blood Pressure",
                      title: "Blood Pressure Reading",
                      sensorWaitingTime: 30,
                    );
                  }),
                ).then((value) {
                  result = value;
                });
              },
              child: const Text(
                "Read Blood Pressure",
              ),
            ),
          ],
        ),
      ),
    );
  }
}
