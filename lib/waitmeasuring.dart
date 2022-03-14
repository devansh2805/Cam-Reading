import 'dart:ui';
import 'package:flutter/material.dart';

class WaitMeasuringWidget extends StatefulWidget {
  const WaitMeasuringWidget({Key? key, required this.nameString})
      : super(key: key);
  final String nameString;
  @override
  State<StatefulWidget> createState() => WaitMeasuringWidgetState();
}

class WaitMeasuringWidgetState extends State<WaitMeasuringWidget> {
  @override
  Widget build(BuildContext context) {
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(
                height: 10,
              ),
              Text(
                'Measuring ' + widget.nameString + ' ........',
                style: const TextStyle(
                  color: Colors.black,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
