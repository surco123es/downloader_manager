// ignore_for_file: camel_case_types

import 'dart:isolate';

import '../download_manager.dart';

class ManReques {
  String fileName, url;
  ManSettings setting;
  bool priority, extension;
  int token;
  SendPort? sendPort;
  ManReques({
    this.fileName = '',
    required this.setting,
    required this.url,
    this.priority = false,
    this.extension = true,
    this.sendPort,
    required this.token,
  });
}
