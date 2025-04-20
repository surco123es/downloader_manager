import 'dart:async';
import 'dart:isolate';

import '../downloader_manager.dart';

class StatusDownloadIsolate {
  bool complete, pause, init;
  late StatusDownload status;
  int tokenIsolate;
  int tokenDownload;
  StatusDownloadIsolate({
    required this.tokenIsolate,
    this.tokenDownload = 0,
    this.complete = false,
    this.pause = false,
    this.init = false,
  }) {
    status = StatusDownload(
      main: ManDownload(
        complete: complete,
        speed: '',
        porcent: 0,
        sizeDownload: 0,
        sizeFinal: 0,
        main: true,
      ),
      part: [],
    );
  }
}

class TaskDownload {
  late Isolate root;
  //estes sendport se crea al iniciar el isolate y que este responda corectamente
  late SendPort _sendPort;
  StatusDownloadIsolate status;
  bool freeIsolate = true;
  final StreamController<StatusDownload> statusDownload =
      StreamController<StatusDownload>.broadcast();
  ReceivePort rcvPort = ReceivePort();

  late Capability resume;
  TaskDownload({required this.status}) {
    listing();
  }
  SendPort sendPortIsolate() {
    return _sendPort;
  }

  listing() {
    rcvPort.listen((val) async {
      print('recibimos el mensaje del isolate ${val.runtimeType}');
      SendportData _status = val;
      status.status.main = _status.main;
      status.status.part = _status.part;
      if (status.tokenDownload == _status.tokenDownload) {
        statusDownload.sink.add(status.status);
      }
      if (_status.init) {
        _sendPort = _status.sendPort!;
        print('creamos el isolate ${status.tokenIsolate}');
      } else if (_status.error) {
        print('ocurio un error en el isolate ${status.tokenIsolate}');
      } else if (_status.startDownload) {
        status.tokenDownload = _status.tokenDownload;
      } else if (_status.freeIsolate) {
        freeIsolate = true;
      } else if (_status.join) {
        status.complete = true;
      }
    });
  }
}

class TokenDownload {
  int isolateToken;
  bool active;
  TokenDownload({required this.isolateToken, this.active = false});
}
