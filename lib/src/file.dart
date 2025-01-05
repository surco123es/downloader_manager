// ignore_for_file: camel_case_types, unused_element

import 'dart:isolate';

import 'task.dart';

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
  int key, sizeDownload, sizeFinal;
  bool main, complete;
  double porcent;
  String speed;
  ManDownload({
    required this.key,
    required this.complete,
    required this.speed,
    required this.porcent,
    required this.sizeDownload,
    required this.sizeFinal,
    required this.main,
  });
}

class StatusDownload {
  bool join = false;
  bool forceKill = false;
  SendPort? sendPort;
  bool kill = false;
  ManDownload main = ManDownload(
    key: 0,
    porcent: 0,
    sizeDownload: 0,
    sizeFinal: 0,
    main: true,
    complete: false,
    speed: '...MB',
  );
  List<ManDownload> part = [];
}

ManagerDownload manDown = ManagerDownload();
