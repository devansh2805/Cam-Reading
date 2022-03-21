import 'package:flutter/material.dart';
import 'communication.dart';
import 'dart:ui';
import 'dart:convert';

class ParameterReader extends StatefulWidget {
  const ParameterReader(
      {Key? key,
      required this.communication,
      required this.bluetoothMessage,
      required this.sensorWaitingTime,
      required this.title})
      : super(key: key);

  final Communication communication;
  final String title;
  final String bluetoothMessage;
  final int sensorWaitingTime;

  @override
  ParameterReaderState createState() => ParameterReaderState();
}

class ParameterReaderState extends State<ParameterReader> {
  String reading = "";
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    widget.communication.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          automaticallyImplyLeading: false,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Visibility(
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(
                      height: 20,
                    ),
                    Text("Reading " + widget.bluetoothMessage)
                  ],
                ),
                visible: _loading,
              ),
              Visibility(
                child: TextButton(
                  child: const Text("Start Reading"),
                  onPressed: () async {
                    await widget.communication.initialize();
                    if (widget.communication.connectionState) {
                      setState(() {
                        _loading = true;
                      });
                      await widget.communication
                          .sendMessage(widget.bluetoothMessage);
                      // Show Some Temporary Screen Instructing User to use sensor
                      Future.delayed(
                        Duration(seconds: widget.sensorWaitingTime),
                        () async {
                          setState(() {
                            _loading = false;
                          });
                          widget.communication.bluetoothConnection?.input
                              ?.listen((data) {
                            String value = ascii.decode(data);
                            print(value);
                            switch (widget.bluetoothMessage) {
                              case "Oxygen":
                                {
                                  Navigator.pop(
                                    context,
                                    value + " %",
                                  );
                                  break;
                                }
                              case "Heart Rate":
                                {
                                  Navigator.pop(
                                    context,
                                    value + " bpm",
                                  );
                                  break;
                                }
                              case "Temperature":
                                {
                                  Navigator.pop(
                                    context,
                                    value + " °F",
                                  );
                                  break;
                                }
                              case "Blood Pressure":
                                {
                                  Navigator.pop(
                                    context,
                                    value,
                                  );
                                  break;
                                }
                            }
                          });
                        },
                      );
                    } else {
                      showDialog(
                        context: context,
                        useRootNavigator: false,
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
                                height:
                                    MediaQuery.of(context).size.height * 0.30,
                                width: MediaQuery.of(context).size.width - 10,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text("Error Connecting Device"),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: const Text("Retry"),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }
                  },
                ),
                visible: !_loading,
              )
            ],
          ),
        ),
      ),
    );
  }
}
