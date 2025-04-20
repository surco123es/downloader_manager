// ignore_for_file: camel_case_types

import 'dart:isolate';

import '../downloader_manager.dart';

class ManReques {
  String fileName, url;
  ManSettings? setting;
  bool extension;
  int tokenDownload;
  SendPort? sendPort;
  ManReques({
    this.fileName = '',
    required this.setting,
    required this.url,
    this.extension = true,
    this.sendPort,
    required this.tokenDownload,
  });
}

class RequestCreate {
  SendPort sendPort;
  ManSettings setting;
  int token;
  RequestCreate({
    required this.setting,
    required this.token,
    required this.sendPort,
  });
}
