import 'dart:async';
import 'dart:isolate';

import '../downloader_manager.dart';

enum StatusIsolateType {
  waiting,
  waitingFileExists,
  freeIsolate,
  fileExists,
  pause,
  downloading,
  error,
  errorConexion,
  cancelDownload,
  startDownload,
  canceling,
}

class StatusDownloadIsolate {
  late StatusDownload status;
  int tokenIsolate;
  StatusDownloadIsolate({required this.tokenIsolate}) {
    status = StatusDownload(
      main: ManDownload(speed: '', porcent: 0, sizeDownload: 0, sizeFinal: 0),
      part: [],
    );
  }
}

class TaskDownload {
  StatusIsolateType statusIsolate = StatusIsolateType.freeIsolate;
  late Isolate _root;
  int tokenDownload = 0;
  //estes sendport se crea al iniciar el isolate y que este responda corectamente
  late SendPort _sendPort;
  StatusDownloadIsolate status;
  final StreamController<StatusDownload> statusDownload =
      StreamController<StatusDownload>.broadcast();
  ReceivePort rcvPort = ReceivePort();

  late Capability resume;

  set root(Isolate root) {
    _root = root;
  }

  SendPort get sendPort => _sendPort;
  set sendPort(SendPort sndPort) {
    _sendPort = sndPort;
  }

  Isolate get root => _root;

  TaskDownload({required this.status});

  bool getStatus(int tokenDownload) {
    return (tokenDownload == this.tokenDownload);
  }
}

class TokenDownloadStatus {
  int isolateToken;
  DownloadType status;
  TokenDownloadStatus({
    required this.isolateToken,
    this.status = DownloadType.waiting,
  });
}
