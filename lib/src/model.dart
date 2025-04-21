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
  Completer<SendPort> _completer = Completer<SendPort>();
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
      bool sendStream = false;
      if (val is CreateIsolateSendPort) {
        _sendPort = val.sendPort;
        return;
      }
      if (val is ManDownload) {
        status.status.main = val;
        sendStream = true;
      }
      if (val is List<ManDownload>) {
        status.status.part = val;
        sendStream = true;
      }
      if (val is ErrorSendPort) {
        status.status.error = true;
        print('ocurio un error en el isolate ${status.tokenIsolate}');
        print('ocurio un error en el isolate ${val.errorObject}');
        print('ocurio un error en el isolate ${val.stack}');
        sendStream = true;
      }
      if (val is StatusDownloadSendPort) {
        if (val.startDownload) {
          status.tokenDownload = val.tokenDownload;
        } else if (val.freeIsolate) {
          freeIsolate = true;
        } else if (val.join) {
          status.complete = true;
        }
      }

      if (sendStream) {
        statusDownload.sink.add(status.status);
      }
    });
  }
}

class TokenDownload {
  int isolateToken;
  bool active;
  TokenDownload({required this.isolateToken, this.active = false});
}
