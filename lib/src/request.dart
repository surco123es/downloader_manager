// ignore_for_file: camel_case_types

import 'dart:isolate';

import 'package:download_manager/download_manager.dart';

class manReques {
  String fileName, url;
  manSettings setting;
  bool priority, extension;
  int token;
  SendPort? sendPort;
  manReques({
    this.fileName = '',
    required this.setting,
    required this.url,
    this.priority = false,
    this.extension = true,
    this.sendPort,
    required this.token,
  });
}
