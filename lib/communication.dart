import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class Communication {
  late FlutterBluetoothSerial flutterBluetoothSerial =
      FlutterBluetoothSerial.instance;
  BluetoothConnection? bluetoothConnection;
  bool connectionState = false;

  Future<bool> initialize() async {
    connectionState = false;
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
            connectionState = device.isConnected;
            return true;
          } else {
            await _connectToAddress(device.address).then((value) {
              if (device.isConnected) {
                connectionState = device.isConnected;
                return true;
              } else {
                return _connectToRpiDevice();
              }
            });
          }
        }
      }
    });
    return false;
  }

  Future<void> _connectToAddress(address) async {
    await BluetoothConnection.toAddress(address).then((connection) {
      bluetoothConnection = connection;
    }).catchError((error) {
      print(error);
      print('Cannot Connect to HealthConnect Device');
    });
  }

  String readMessage() {
    String result = "";
    try {
      bluetoothConnection?.input?.listen((data) {
        result = ascii.decode(data);
      });
      return result;
    } catch (error) {
      print(error);
    }
    return result;
  }

  Future<void> sendMessage(String text) async {
    try {
      bluetoothConnection?.output.add(Uint8List.fromList(utf8.encode(text)));
      await bluetoothConnection?.output.allSent;
    } catch (error) {
      print("Error Sending Data");
    }
  }
}
