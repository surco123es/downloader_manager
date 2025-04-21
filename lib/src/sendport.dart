import 'dart:isolate';

import 'file.dart';
import 'request.dart';

class ManMessagePort {
  String action;
  ManReques? download;
  ManMessagePort({required this.action, this.download});
}

class CreateIsolateSendPort {
  SendPort sendPort;
  CreateIsolateSendPort({required this.sendPort});
}

class ErrorSendPort {
  StackTrace? stack;
  Object errorObject;
  ErrorSendPort({required this.errorObject, this.stack});
}

class StatusDownloadSendPort {
  bool join, kill, error, rangeAccept, init, freeIsolate, startDownload;
  int tokenDownload;
  StatusDownloadSendPort({
    this.join = false,
    this.kill = false,
    this.error = false,
    this.rangeAccept = true,
    this.init = false,
    this.freeIsolate = false,
    this.startDownload = false,
    this.tokenDownload = 0,
  });
}
