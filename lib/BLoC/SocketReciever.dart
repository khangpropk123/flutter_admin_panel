import 'package:adhara_socket_io/adhara_socket_io.dart';
import 'dart:convert';
import 'dart:io';

class SocketReciver {
  List<String> toPrint = ["trying to connect"];
  SocketIOManager manager;
  Map<String, SocketIO> sockets = {};
  Map<String, bool> _isProbablyConnected = {};
}
