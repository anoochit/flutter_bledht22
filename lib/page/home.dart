import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

class HomePage extends StatefulWidget {
  HomePage({Key key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  FlutterBlue flutterBlue;
  List<ScanResult> scanResult;
  Stream<List<int>> listStream;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  scanDevice() {
    flutterBlue = FlutterBlue.instance;
    flutterBlue.startScan(
        scanMode: ScanMode.lowLatency, timeout: Duration(seconds: 4));

    flutterBlue.scanResults.listen((result) {
      setState(() {
        scanResult = result;
      });
    }).onDone(() {
      log("done");
    });

    // Stop scanning
    flutterBlue.stopScan();
  }

  connectDevice(BluetoothDevice device) async {
    await device.connect();
    List<BluetoothService> services = await device.discoverServices();
    services.forEach((service) {
      // do something with service
      log("services -> " + service.uuid.toString());
      List<BluetoothCharacteristic> characteristics = service.characteristics;
      characteristics.forEach((characteristic) async {
        // do something with characteristic
        log("characteristic -> " + characteristic.serviceUuid.toString());
        // get only 0000181a environmental sensor
        if (characteristic.uuid.toString() ==
            "0000181a-0000-1000-8000-00805f9b34fb") {
          try {
            characteristic.setNotifyValue(!characteristic.isNotifying);
            characteristic.value.listen((value) {
              //do something with value
              String valueString = "";
              value.forEach((v) {
                valueString = valueString + String.fromCharCode(v);
              });
              log("value -> " + valueString);
            });
          } catch (e) {
            log("error -> " + e.toString());
          }
        }
      });
    });

    Future.delayed(const Duration(seconds: 5), () {
      device.disconnect();
    });
  }

  buildList(ScanResult scanResult) {
    // only BLE-DHT22
    if (scanResult.device.name.toString().contains("BLE-DHT22")) {
      return ListTile(
        leading: CircleAvatar(child: Icon(Icons.bluetooth)),
        title: Text(
          (scanResult.device.name.toString() != "")
              ? scanResult.device.name.toString()
              : "Noname",
        ),
        trailing: Text(
          scanResult.rssi.toString() + " dBm",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onTap: () {
          log(scanResult.device.id.toString());
          connectDevice(scanResult.device);
        },
      );
    } else {
      return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    // let connect only BLE-DHT22
    return Scaffold(
        appBar: AppBar(
          title: const Text("Thermometer BLE"),
          actions: <Widget>[
            FlatButton(
                child: Text(
                  "Scan",
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  scanDevice();
                })
          ],
        ),
        body: SafeArea(
            child: (scanResult != null)
                ? ListView.builder(
                    itemCount: scanResult.length,
                    itemBuilder: (BuildContext context, int index) {
                      return buildList(scanResult[index]);
                    },
                  )
                : Container()));
  }
}
