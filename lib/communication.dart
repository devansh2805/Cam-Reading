import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class Communication {
  late FlutterBluetoothSerial flutterBluetoothSerial =
      FlutterBluetoothSerial.instance;
  late BluetoothConnection bluetoothConnection;

  Future<bool> initialize() async {
    return await _askforEnablingBluetooth();
  }

  Future<bool> _askforEnablingBluetooth() async {
    await flutterBluetoothSerial.isEnabled.then((bluetoothAdapterState) async {
      if (bluetoothAdapterState != null) {
        if (bluetoothAdapterState) {
          return await _connectToRpiDevice();
        } else {
          await flutterBluetoothSerial.requestEnable().then((isOn) async {
            if (isOn != null) {
              if (isOn) {
                return await _connectToRpiDevice();
              } else {
                return await _askforEnablingBluetooth();
              }
            }
            return isOn;
          });
        }
      }
    });
    return false;
  }

  Future<bool> _connectToRpiDevice() async {
    // Check if it is Already Bonded
    await flutterBluetoothSerial.getBondedDevices().then((devices) async {
      for (BluetoothDevice device in devices) {
        if (device.name == "healthconnectdevice") {
          if (device.isConnected) {
            return true;
          } else {
            await _connectToAddress(device.address).then((value) {
              if (!device.isConnected) {
                return _connectToRpiDevice();
              } else {
                return true;
              }
            });
          }
        }
      }
    });
    Stream<BluetoothDiscoveryResult> bluetoothDiscoveryResult =
        flutterBluetoothSerial.startDiscovery();
    bluetoothDiscoveryResult.forEach((element) async {
      if (element.device.name == "healthconnectdevice") {
        if (element.device.isConnected) {
          Future.delayed(const Duration(milliseconds: 10), () {
            return true;
          });
        }
        if (!element.device.isBonded) {
          flutterBluetoothSerial
              .bondDeviceAtAddress(element.device.address)
              .then((bondValue) async {
            if (bondValue != null) {
              if (bondValue) {
                await _connectToAddress(element.device.address).then((value) {
                  if (!element.device.isConnected) {
                    return _connectToRpiDevice();
                  } else {
                    return true;
                  }
                });
              } else {
                return _connectToRpiDevice();
              }
            }
          });
        } else {
          await _connectToAddress(element.device.address).then((value) {
            if (!element.device.isConnected) {
              return _connectToRpiDevice();
            } else {
              return true;
            }
          });
        }
      }
    });
    return _connectToRpiDevice();
  }

  Future<void> _connectToAddress(address) async {
    await BluetoothConnection.toAddress(address).then((connection) {
      bluetoothConnection = connection;
    }).catchError((error) {
      print('Cannot Connect to HealthConnect Device');
    });
  }

  Future<String> readMessage() async {
    String result = "";
    await Future.delayed(const Duration(seconds: 30), () {
      try {
        bluetoothConnection.input?.listen((data) {
          result = ascii.decode(data);
        }).onDone(() {});
      } catch (error) {
        print(error);
      }
      return result;
    });
    return result;
  }

  Future<void> sendMessage(String text) async {
    try {
      bluetoothConnection.output.add(Uint8List.fromList(utf8.encode(text)));
      await bluetoothConnection.output.allSent;
    } catch (error) {
      print("Error Sending Data");
    }
  }
}