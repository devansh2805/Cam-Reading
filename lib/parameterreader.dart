import 'package:flutter/material.dart';
import 'communication.dart';
import 'dart:ui';

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
  late Future<bool> connectionState;

  @override
  void initState() {
    super.initState();
    connectionState = widget.communication.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
          child: TextButton(
        child: const Text("Start Reading"),
        onPressed: () async {
          await connectionState;
          if (widget.communication.bluetoothConnection.isConnected) {
            await widget.communication.sendMessage(widget.bluetoothMessage);
            // Show Some Temporary Screen Instructing User to use sensor
            Future.delayed(Duration(seconds: widget.sensorWaitingTime), () async {
              await widget.communication.readMessage().then((value) {
                print(value);
                Navigator.pop(context);
              });
            });
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
                      height: MediaQuery.of(context).size.height * 0.30,
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
      )),
    );
  }
}
