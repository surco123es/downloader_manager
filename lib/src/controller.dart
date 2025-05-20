import 'dart:async';
import 'dart:isolate';

import 'package:downloader_manager/src/isolate/velocity.dart';
import 'package:downloader_manager/src/model.dart';

import 'file.dart';
import 'func.dart';
import 'isolate/download.dart';
import 'isolate/merge.dart';
import 'isolate/model.dart';
import 'model_require.dart';
import 'request.dart';
import 'sendport.dart';
import 'setting.dart';

class DownloadManager {
  bool sendIntervalState = true;
  bool cancelDownload = false;
  int numDownloadComplete = 0;
  int tokenIsolate = 0;
  int startTime = 0;
  late Timer sendInterval;
  bool startInit = false;
  bool errorInDownload = false;
  bool completeProcess = false;
  late SendPort sendPort;
  late StreamSubscription reciverData;
  bool fileExists = false;
  List<Downloader> endPart = [];
  List<Future<void>> runProcessDownloads = [];
  int tokenDownload = 0;

  //numero de futures activos descargandose
  int nunRun = 0;

  //numero de futures cancelados
  int numRunCancel = 0;

  int totalSize = 0;
  int downloadSize = 0;
  Map<int, StreamSubscription> sub = {};
  bool downloadInPart = true;
  late Velocity speed;
  bool sendstatusIsolate = false;
  int numPart = 0;
  Map<String, dynamic> header = {};
  //estado de descarga
  ManDownload statusDownload = ManDownload(
    speed: '',
    porcent: 0,
    sizeDownload: 0,
    sizeFinal: 0,
  );

  StatusDownloadSendPort statusIsolate = StatusDownloadSendPort(
    tokenDownload: 0,
    status: StatusIsolateType.startDownload,
  );
  late MergePartDownload mergePart;
  late ManReques request;
  late ReceivePort rcv;

  createIsolate(RequestCreate requestIso) async {
    rcv = ReceivePort();
    tokenIsolate = requestIso.token;
    sendPort = requestIso.sendPort;
    request = ManReques(setting: requestIso.setting, url: '', tokenDownload: 0);
    ManSettings setting = requestIso.setting;

    mergePart = MergePartDownload(fileName: '');
    speed = Velocity();

    sendInterval = Timer.periodic(Duration(milliseconds: 1000), (_) {
      sendStatus();
    });

    reciverData = rcv.listen((m) async {
      if (!(m is ManMessagePort)) return;
      ManMessagePort rver = m;
      if (rver.action == 'add') {
        if (startInit && nunRun > 0) return;
        request = rver.download!;
        if (request.tokenDownload == tokenDownload) return;
        mergePart.fileName = request.fileName;
        if (rver.download!.setting == null) {
          request.setting = setting;
        }

        tokenDownload = rver.download!.tokenDownload;
        statusIsolate.tokenDownload = tokenDownload;
        _cleanForWaiting();
        download();
      } else if (rver.action == 'cancel') {
        if (cancelDownload) return;
        cancelDownload = true;

        statusIsolate.status = StatusIsolateType.canceling;
        _cancelDownload();
      } else if (rver.action == 'forceStart') {
        if (rver.download!.fileName == '') {
          print('se forza');
          download(forceStart: true);
        } else {
          request.fileName = rver.download!.fileName;
          mergePart.fileName = rver.download!.fileName;
          print('nomre ${mergePart.fileName}');

          statusIsolate.status = StatusIsolateType.waiting;
          download();
        }
      } else if (rver.action == 'getStatus') {
        sendstatusIsolate = true;
        sendStatus();
      }
    });
    sendPort.send(CreateIsolateSendPort(sendPort: rcv.sendPort));
  }

  _cancelDownload() {
    for (Downloader e in endPart) {
      e.cancel = true;
    }
    Future.wait(runProcessDownloads).then((_) {
      if (cancelDownload) {
        statusDownload.status = DownloadType.cancelDownload;
        statusIsolate.status = StatusIsolateType.cancelDownload;
        sendstatusIsolate = true;
        _cleanForSubcription();
      }
    });
  }

  _cleanForWaiting() {
    statusDownload = ManDownload(
      porcent: 0,
      sizeDownload: 0,
      sizeFinal: 0,
      speed: speed.speed,
    );
    endPart.clear();
    nunRun = 0;
    numPart = 0;
    downloadSize = 0;
    totalSize = 0;
    cancelDownload = false;
    startTime = DateTime.now().millisecondsSinceEpoch;
    startInit = false;
    sendstatusIsolate = true;
  }

  download({bool forceStart = false}) async {
    ManHttpStatus flD = await checkConexionFile(request.url);
    if (flD.status) {
      if (!forceStart) {
        var (nm, st) = await mergePart.checkFileExists(
          header: header,
          request: request,
          exists: true,
        );
        if (!st) {
          sendstatusIsolate = true;
          statusIsolate.status = StatusIsolateType.fileExists;
          sendStatus();
          return;
        }
      }
      sendstatusIsolate = true;
      statusIsolate.status = StatusIsolateType.startDownload;
      sendStatus();
      int partSizeLimit = 0;
      header = flD.header;
      if (!startInit) {
        startInit = true;
        sendIntervalState = true;
      }
      totalSize =
          (header.containsKey('accept-ranges') == true &&
                  header['accept-ranges'] == 'bytes' &&
                  header.containsKey('content-length'))
              ? int.parse(flD.header["content-length"])
              : 0;
      if (totalSize != 0) {
        partSizeLimit = totalSize < 10242880 ? (totalSize / 3).ceil() : 5242880;
        numPart = (totalSize / partSizeLimit).ceil();
        int partDwn = (totalSize / numPart).ceil();
        int endPartSize = partDwn;
        if (partDwn * numPart != totalSize) {
          endPartSize = totalSize - ((numPart - 1) * partDwn);
        }
        for (int i = 0; i < numPart; i++) {
          int start = 0;
          int ipart = partDwn;
          if (i == (numPart - 1)) {
            start = partDwn * i;
            ipart = endPartSize == 0 ? partDwn : endPartSize;
          } else {
            start = partDwn * i;
          }
          int end = (start + ipart);
          if (i > 0) {
            start = start + 1;
          }
          endPart.add(
            Downloader(
              downloadData: DataDownload(
                url: request.url,
                start: start,
                end: end,
                id: i,
              ),
              fileTemp: '${request.setting!.folderTemp}${tokenDownload}${i}',
            ),
          );
        }
      } else {
        downloadInPart = false;
        endPart.add(
          Downloader(
            downloadData: DataDownload(
              url: request.url,
              start: 0,
              end: 0,
              id: 0,
            ),
            fileTemp: '${request.setting!.folderTemp}${request.tokenDownload}',
          ),
        );
      }
      downloadPart();
    } else {
      _sendError(
        ErrorSendPort(
          errorObject: 'No se puede descargar el archivo, error de conexion',
        ),
      );
    }
  }

  downloadPart() async {
    int completeRun = 0;
    for (Downloader e in endPart) {
      if (e.status == DownloadType.waiting) {
        if (nunRun < request.setting!.conexion) {
          addSuscription(e.controller.stream, e.downloadData.id);
          runProcessDownloads.add(e.startDownload());
          nunRun++;
        } else {
          break;
        }
      } else if (e.status == DownloadType.complete) {
        completeRun++;
      }
    }
    if (completeRun == endPart.length) {
      runProcessDownloads.add(_completeFuncion());
    }
  }

  Future<void> _completeFuncion() async {
    statusDownload.status = DownloadType.join;
    sendstatusIsolate = true;
    bool join = await mergePart.joinMerge(
      temp: request.setting!.folderTemp,
      token: tokenDownload.toString(),
      numpart: numPart,
    );
    if (join) {
      sendstatusIsolate = true;
      statusDownload.porcent = 100;
      statusDownload.speed = speed.speed;
      statusDownload.status = DownloadType.complete;
      statusIsolate.status = StatusIsolateType.freeIsolate;
      _cleanForSubcription();
    } else {
      _sendError(
        ErrorSendPort(errorObject: 'ocurrio un error en la union de partes'),
      );
    }
  }

  addSuscription(Stream<(DownloadType, int)> stream, int id) {
    sub.addAll({
      id: stream.listen((e) {
        DownloadType tp = e.$1;
        if (tp == DownloadType.complete) {
          if (e.$2 > 0) {
            downloadSize += e.$2;
            speed.downloadSize = downloadSize;
            statusDownload.speed = speed.speed;
          }
          --nunRun;
          downloadPart();
        } else if (tp == DownloadType.downloading) {
          if (cancelDownload) {
            statusIsolate.status = StatusIsolateType.cancelDownload;
            statusDownload.status = DownloadType.cancelDownload;
            return;
          }
          downloadSize += e.$2;
          speed.downloadSize = downloadSize;
          statusDownload.speed = speed.speed;
          if (statusDownload.status != tp) {
            statusIsolate.status = StatusIsolateType.downloading;
            statusDownload.status = tp;
          }
        } else if (tp == DownloadType.error) {
          _sendError(
            ErrorSendPort(errorObject: 'ocurrio un error en la descarga'),
          );
          _cleanForSubcription();
        } else if (tp == DownloadType.pause) {
          statusDownload.status = tp;
          statusIsolate.status = StatusIsolateType.pause;
        } else if (tp == DownloadType.cancelDownload) {
          numRunCancel++;
          print(
            'numero de cancelados: $numRunCancel y numero de futuro $nunRun',
          );
          if (numRunCancel == nunRun) {
            print('se esta cancelando la descarga');
            statusDownload.speed = '0 MB/s';
            statusDownload.status = DownloadType.cancelDownload;
            statusIsolate.status = StatusIsolateType.cancelDownload;
            completeProcess = true;
            _cleanForSubcription();
          }
        }
      }),
    });
  }

  _sendError(ErrorSendPort error) {
    statusDownload.status = DownloadType.errorDownload;
    statusIsolate.status = StatusIsolateType.error;
    sendstatusIsolate = true;
  }

  int ind = 0;
  _cleanForSubcription() {
    nunRun = 0;
    numRunCancel = 0;
    sub.forEach((_, _sub) => _sub.cancel());
    endPart.forEach((e) => e.dispose());
    sub.clear();
    endPart.clear();
    header.clear();
    runProcessDownloads.clear();
    startInit = false;
    numDownloadComplete++;
    Future.delayed(Duration(seconds: 2), () {
      sendstatusIsolate = true;
      statusIsolate.status = StatusIsolateType.freeIsolate;
      sendStatus();
      sendIntervalState = false;
      cancelDownload = false;
    });
  }

  @pragma('vm:entry-point')
  sendStatus() {
    if (!sendIntervalState) return;
    if (sendstatusIsolate) {
      sendstatusIsolate = false;
      print('se envio el status de descarga');
      sendPort.send(statusIsolate);
      return;
    }
    if (errorInDownload) {
      print('hubo un error en la descarga');
      sendPort.send(statusIsolate);
      return;
    }
    print('esta es de estatus ${statusIsolate.status}');
    if (statusDownload.status == DownloadType.downloading) {
      statusDownload.porcent = (downloadSize * 100 / totalSize).clamp(
        0.0,
        100.0,
      );
    }
    //cuando el porcentaje de descarga sea 100% se empezara a reducir el limite de envios al sendport y cuando llegue a 0 se lioberara el isolate para su nuevo uso
    if (statusDownload.status == DownloadType.complete) {
      statusDownload.porcent = 100;
    }
    if (completeProcess) {
      statusIsolate.status = StatusIsolateType.freeIsolate;
      print('se completo el proceso de descarga');
      sendPort.send(statusIsolate);
      completeProcess = false;
    } else {
      sendPort.send(statusDownload);
    }
  }
}
