// ignore_for_file: camel_case_types, unused_element

import 'dart:isolate';

import 'package:download_manager/src/task.dart';

class manFile {
  String title, folderTemp, folderOut, url;
  bool replace, complete, download;
  int sizeFinal, sizeDownload, partDownload, key, task;
  manFile({
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

class manDownload {
  int key, sizeDownload, sizeFinal;
  bool main, complete;
  double porcent;
  String speed;
  manDownload({
    required this.key,
    required this.complete,
    required this.speed,
    required this.porcent,
    required this.sizeDownload,
    required this.sizeFinal,
    required this.main,
  });
}

class statusDownload {
  bool join = false;
  bool forceKill = false;
  SendPort? sendPort;
  bool kill = false;
  manDownload main = manDownload(
    key: 0,
    porcent: 0,
    sizeDownload: 0,
    sizeFinal: 0,
    main: true,
    complete: false,
    speed: '...MB',
  );
  List<manDownload> part = [];
}

managerDownload manDown = managerDownload();
