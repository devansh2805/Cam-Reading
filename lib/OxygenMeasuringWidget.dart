import 'dart:ui';

import 'package:flutter/material.dart';

class OxygenMeasuringWidget extends StatefulWidget {
  const OxygenMeasuringWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => OxygenMeasuringWidgetState();
}

class OxygenMeasuringWidgetState extends State<OxygenMeasuringWidget> {
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CircularProgressIndicator(),
              Text("Measuring SpO2........")
            ],
          ),
        ),
      ),
    );
  }
}
