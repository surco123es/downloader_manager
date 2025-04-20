import 'dart:async';
import 'dart:isolate';

import '../downloader_manager.dart';

class StatusDownloadIsolate {
  bool complete, pause, kill, init;
  late StatusDownload status;

  StatusDownloadIsolate({
    this.complete = false,
    this.pause = false,
    this.kill = false,
    this.init = false,
  });
}

class TaskDownload {
  late Isolate root;
  StatusDownloadIsolate status = StatusDownloadIsolate();
  final StreamController<StatusDownload> statusDownload =
      StreamController<StatusDownload>.broadcast();
  ReceivePort rcvPort = ReceivePort();
  ReceivePort _error = ReceivePort();
  int token;

  late Capability resume;
  TaskDownload({required this.token});

  listing() {
    status.init = true;
    root.addErrorListener(_error.sendPort);
    _error.listen((error) {
      print("Error recibido del isolate: ${error[0]}");
      print("StackTrace: ${error[1]}");
    });
    rcvPort.listen((val) async {
      status.status = val;
      statusDownload.sink.add(status.status);
      if ((status.status.main.complete && !status.kill)) {
        status.complete = status.status.forceKill ? false : true;
        if (!status.kill) {
          status.kill = true;
          rcvPort.close();
          statusDownload.close();
          root.kill(priority: Isolate.immediate);
        }
      }
    });
  }
}
