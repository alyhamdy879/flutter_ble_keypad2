import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BLEKeypadScreen(),
    );
  }
}

class BLEKeypadScreen extends StatefulWidget {
  @override
  _BLEKeypadScreenState createState() => _BLEKeypadScreenState();
}

class _BLEKeypadScreenState extends State<BLEKeypadScreen> {
  FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? keypadCharacteristic;
  String typedPassword = "";

  void startScan() {
    flutterBlue.startScan(timeout: Duration(seconds: 5));
    flutterBlue.scanResults.listen((results) {
      for (ScanResult r in results) {
        if (r.device.name == "ESP32_KEYPAD") {
          connectToDevice(r.device);
          flutterBlue.stopScan();
          break;
        }
      }
    });
  }

  void connectToDevice(BluetoothDevice device) async {
    await device.connect();
    List<BluetoothService> services = await device.discoverServices();
    for (var service in services) {
      for (var characteristic in service.characteristics) {
        if (characteristic.properties.notify) {
          keypadCharacteristic = characteristic;
          characteristic.setNotifyValue(true);
          characteristic.value.listen((value) {
            setState(() {
              typedPassword = String.fromCharCodes(value);
            });
          });
        }
      }
    }
    setState(() {
      connectedDevice = device;
    });
  }

  void sendCommand(String command) async {
    if (keypadCharacteristic != null) {
      await keypadCharacteristic!.write(command.codeUnits);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Flutter BLE Keypad")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Typed Password:", style: TextStyle(fontSize: 20)),
          SizedBox(height: 10),
          Text(typedPassword, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 20),
          connectedDevice == null
              ? ElevatedButton(
                  onPressed: startScan,
                  child: Text("Scan & Connect"),
                )
              : Column(
                  children: [
                    GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 3,
                      children: List.generate(9, (index) {
                        return ElevatedButton(
                          onPressed: () => sendCommand((index + 1).toString()),
                          child: Text("${index + 1}"),
                        );
                      }),
                    ),
                    ElevatedButton(
                      onPressed: () => sendCommand("0"),
                      child: Text("0"),
                    ),
                    ElevatedButton(
                      onPressed: () => sendCommand("ENTER"),
                      child: Icon(Icons.check),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}
