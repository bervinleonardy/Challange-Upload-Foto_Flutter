import 'dart:async';

import 'package:flutter/material.dart';

import 'cekKoneksi.dart';

class koneksi extends StatefulWidget {
  @override
  TestWidgetState createState() => new TestWidgetState();
}

class TestWidgetState extends State<koneksi> {
  StreamSubscription _connectionChangeStream;

  bool isOffline = false;

  @override
  initState() {
    super.initState();

    cekKoneksi connectionStatus = cekKoneksi.getInstance();
    _connectionChangeStream = connectionStatus.connectionChange.listen(connectionChanged);
  }

  void connectionChanged(dynamic hasConnection) {
    setState(() {
      isOffline = !hasConnection;
    });
  }

  @override
  Widget build(BuildContext ctxt) {
    return (isOffline)? new Text("Not connected") : new Text("Connected");
  }
}