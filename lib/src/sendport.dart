import 'dart:isolate';

import 'file.dart';
import 'request.dart';

class ManMessagePort {
  String action;
  ManReques? download;
  ManMessagePort({required this.action, this.download});
}

class SendportData {
  SendPort? sendPort;
  bool join, kill, error, rangeAccept, init, freeIsolate, startDownload;
  int tokenDownload;
  ManDownload main = ManDownload(
    porcent: 0,
    sizeDownload: 0,
    sizeFinal: 0,
    main: true,
    complete: false,
    speed: '...MB',
  );
  List<ManDownload> part = [];
  SendportData({
    this.sendPort,
    this.error = false,
    this.join = false,
    this.init = false,
    this.rangeAccept = true,
    this.kill = false,
    this.freeIsolate = false,
    this.startDownload = false,
    this.tokenDownload = 0,
  });
}
