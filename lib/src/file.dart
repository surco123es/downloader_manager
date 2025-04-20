// ignore_for_file: camel_case_types, unused_element

import 'dart:isolate';

class ManFile {
  String title, folderTemp, folderOut, url;
  bool replace, complete, download;
  int sizeFinal, sizeDownload, partDownload, key, task;
  ManFile({
    required this.title,
    required this.folderOut,
    required this.folderTemp,
    required this.key,
    required this.url,
    required this.task,
    this.complete = false,
    this.download = false,
    this.partDownload = 0,
    this.replace = false,
    this.sizeDownload = 0,
    this.sizeFinal = 0,
  });
}

class ManDownload {
  int sizeDownload, sizeFinal;
  bool main, complete;
  double porcent;
  String speed;
  ManDownload({
    required this.complete,
    required this.speed,
    required this.porcent,
    required this.sizeDownload,
    required this.sizeFinal,
    required this.main,
  });
}

class StatusDownload {
  bool join, error, init;
  ManDownload main;
  List<ManDownload> part;
  StatusDownload({
    this.error = false,
    this.join = false,
    this.init = false,
    required this.main,
    required this.part,
  });
}
