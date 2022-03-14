import 'package:flutter/material.dart';
import 'package:wakelock/wakelock.dart';
import 'chart.dart';
import 'package:camera/camera.dart';

class HeartRateReading extends StatefulWidget {
  const HeartRateReading({
    Key? key,
    required this.camera,
  }) : super(key: key);

  final CameraDescription camera;

  @override
  HeartRateReadingState createState() => HeartRateReadingState();
}

class HeartRateReadingState extends State<HeartRateReading> {
  bool _toggled = false;
  bool _processing = false;
  bool _initialised = false;
  final List<SensorValue> _data = [];
  late CameraController _cameraController;
  final double _alpha = 0.3;
  final int _bpm = 0;

  _toggle() {
    _initController().then((onValue) {
      Wakelock.enable();
      setState(() {
        _toggled = true;
        _processing = false;
      });
      _updateBPM();
    });
  }

  _untoggle() {
    _disposeController();
    Wakelock.disable();
    setState(() {
      _initialised = false;
      _toggled = false;
      _processing = false;
    });
  }

  Future<void> _initController() async {
    try {
      _cameraController = CameraController(widget.camera, ResolutionPreset.low);
      _cameraController.initialize().then((value) {
        setState(() {
          _initialised = true;
        });
        Future.delayed(const Duration(milliseconds: 500)).then((onValue) {
          _cameraController.setFlashMode(FlashMode.torch);
        });
        _cameraController.startImageStream((CameraImage image) {
          if (!_processing) {
            setState(() {
              _processing = true;
            });
            _scanImage(image);
          }
        });
      });
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    super.initState();
    _cameraController = CameraController(
      widget.camera,
      ResolutionPreset.low,
      enableAudio: false,
    );
    _cameraController.initialize();
  }

  _updateBPM() async {
    List<SensorValue> _values;
    double _avg;
    int _n;
    double _m;
    double _threshold;
    double _bpm;
    int _counter;
    int _previous;
    while (_toggled) {
      _values = List.from(_data);
      _avg = 0;
      _n = _values.length;
      _m = 0;
      for (var value in _values) {
        _avg += value.value / _n;
        if (value.value > _m) _m = value.value;
      }
      _threshold = (_m + _avg) / 2;
      _bpm = 0;
      _counter = 0;
      _previous = 0;
      for (int i = 1; i < _n; i++) {
        if (_values[i - 1].value < _threshold &&
            _values[i].value > _threshold) {
          if (_previous != 0) {
            _counter++;
            _bpm +=
                60000 / (_values[i].time.millisecondsSinceEpoch - _previous);
          }
          _previous = _values[i].time.millisecondsSinceEpoch;
        }
      }
      if (_counter > 0) {
        _bpm = _bpm / _counter;
        setState(() {
          _bpm = (1 - _alpha) * _bpm + _alpha * _bpm;
        });
      }
      await Future.delayed(Duration(milliseconds: (1000 * 50 / 30).round()));
    }
  }

  _scanImage(CameraImage image) {
    double _avg =
        image.planes.first.bytes.reduce((value, element) => value + element) /
            image.planes.first.bytes.length;
    if (_data.length >= 50) {
      _data.removeAt(0);
    }
    setState(() {
      _data.add(SensorValue(DateTime.now(), _avg));
    });
    Future.delayed(const Duration(milliseconds: 1000 ~/ 30)).then((onValue) {
      setState(() {
        _processing = false;
      });
    });
  }

  _disposeController() {
    _cameraController.dispose();
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Center(
                      child: _initialised
                          ? Container()
                          : CameraPreview(_cameraController),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        (_bpm > 30 && _bpm < 150
                            ? _bpm.round().toString()
                            : "--"),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: IconButton(
                  icon: Icon(_toggled ? Icons.favorite : Icons.favorite_border),
                  color: Colors.red,
                  iconSize: 128,
                  onPressed: () {
                    if (_toggled) {
                      _untoggle();
                    } else {
                      _toggle();
                    }
                  },
                ),
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(
                    Radius.circular(
                      18,
                    ),
                  ),
                  color: Colors.black,
                ),
                child: Chart(_data),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
