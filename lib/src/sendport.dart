import 'dart:isolate';

import 'package:downloader_manager/src/model.dart';

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
  StatusIsolateType status;
  int tokenDownload;
  StatusDownloadSendPort({required this.tokenDownload, required this.status});
}
