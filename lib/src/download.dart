import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:vmservice_io';

import 'package:http/http.dart' as http;

import 'file.dart';
import 'func.dart';
import 'merge.dart';
import 'request.dart';
import 'sendport.dart';
import 'setting.dart';

class PartDownload {
  String url;
  int start, end, id;
  PartDownload({
    required this.url,
    required this.start,
    required this.end,
    required this.id,
  });
}

class StatusItem {
  bool complete;
  bool start;
  bool error;
  PartDownload part;
  StatusItem({
    this.complete = false,
    this.error = false,
    this.start = false,
    required this.part,
  });
}

class RunDownload {
  late int tokenIsolate;
  int startTime = 0;
  late Timer sendInterval;
  bool startInit = false;
  int partSizeLimit = 0;
  int numPart = 0;
  final cln = http.Client();
  int totalSize = 0;
  String fOut = '';
  late SendPort sendPort;
  final Map<int, StreamSubscription> streamPart = {};
  late StreamSubscription reciverData;
  List<StatusItem> endpart = [];
  Map<int, Future> run = {};
  int tokenDownload = 0;
  //estado de descarga
  ManDownload mainStatus = ManDownload(
    porcent: 0,
    sizeDownload: 0,
    sizeFinal: 0,
    main: true,
    complete: false,
    speed: '..Mb',
  );
  List<ManDownload> partStatus = [];

  late StatusDownloadSendPort statusDownload;

  late ManReques request;
  late Map<String, dynamic> header;
  late ReceivePort rcv;
  createIsolate(RequestCreate requestIso) async {
    rcv = ReceivePort();
    tokenIsolate = requestIso.token;
    sendPort = requestIso.sendPort;
    request = ManReques(setting: requestIso.setting, url: '', tokenDownload: 0);
    ManSettings setting = requestIso.setting;
    reciverData = rcv.listen((m) async {
      if (!(m is Map<String, ManMessagePort>)) return;
      ManMessagePort rver = m['data']!;
      print(m);
      if (rver.action == 'add') {
        request = rver.download!;
        if (rver.download!.setting == null) {
          request.setting = setting;
        }
        if (startInit) {
          endpart.clear();
          streamPart.clear();
          mainStatus = ManDownload(
            porcent: 0,
            sizeDownload: 0,
            sizeFinal: 0,
            main: true,
            complete: false,
            speed: '..Mb',
          );
          sendInterval.cancel();
        }
        tokenDownload = rver.download!.tokenDownload;
        statusDownload = StatusDownloadSendPort(
          tokenDownload: tokenDownload,
          init: true,
          startDownload: true,
        );
        numPart = 0;
        startInit = false;
        startTime = DateTime.now().millisecondsSinceEpoch;
        sendPort.send(statusDownload);
        download();
      } else if (rver.action == 'stop') {
        if (startInit) {
          endpart.clear();
          sendInterval.cancel();
          run.forEach((key, value) async {
            await streamPart[key]?.cancel();
            run.remove(key);
          });
          streamPart.clear();
        }

        numPart = 0;
        startInit = false;
      }
    });
    sendPort.send(CreateIsolateSendPort(sendPort: rcv.sendPort));
  }

  @pragma('vm:entry-point')
  download() async {
    ManHttpStatus flD = await checkConexionFile(request.url);
    if (flD.status) {
      header = flD.header;
      if (!startInit) {
        startInit = true;
        sendInterval = Timer.periodic(Duration(seconds: 1), (_) {
          sendStatus();
        });
      }
      final int total =
          (header.containsKey('accept-ranges') == true &&
                  header['accept-ranges'] == 'bytes' &&
                  header.containsKey('content-length'))
              ? int.parse(flD.header["content-length"])
              : 0;
      if (total != 0) {
        partSizeLimit = total < 10242880 ? (total / 3).ceil() : 5242880;
        numPart = (total / partSizeLimit).ceil();
        int partDwn = (total / numPart).ceil();
        int endPart = partDwn;
        if (partDwn * numPart != total) {
          endPart = total - ((numPart - 1) * partDwn);
        }
        mainStatus = ManDownload(
          porcent: 0,
          sizeDownload: 0,
          sizeFinal: total,
          main: true,
          complete: false,
          speed: '..Mb',
        );
        for (int i = 0; i < numPart; i++) {
          int start = 0;
          int ipart = partDwn;
          if (i == (numPart - 1)) {
            start = partDwn * i;
            ipart = endPart == 0 ? partDwn : endPart;
          } else {
            start = partDwn * i;
          }
          partStatus.add(
            ManDownload(
              porcent: 0,
              sizeDownload: 0,
              sizeFinal: ipart,
              main: false,
              complete: false,
              speed: '..Mb',
            ),
          );
          int end = (start + ipart);
          if (i > 0) {
            start = start + 1;
          }
          endpart.add(
            StatusItem(
              part: PartDownload(
                url: request.url,
                start: start,
                end: end,
                id: i,
              ),
            ),
          );
        }
      } else {
        endpart.add(
          StatusItem(
            part: PartDownload(url: request.url, start: 0, end: 0, id: 0),
          ),
        );
      }
      initFuture();
    } else {
      request.sendPort?.send(
        ErrorSendPort(
          errorObject: 'No se puede descargar el archivo, error de conexion',
        ),
      );
    }
  }

  @pragma('vm:entry-point')
  initFuture() async {
    int nunRun = streamPart.length;
    bool error = false;
    if (nunRun < request.setting!.conexion) {
      bool merge = false;
      int numComplet = 0;
      for (StatusItem e in endpart) {
        if (!e.start) {
          if (nunRun < request.setting!.conexion) {
            run.addAll({e.part.id: downloadPart(e.part)});
            nunRun++;
          }
        }
        if (endpart[e.part.id].error) {
          error = true;
        }
        if (e.complete) {
          numComplet++;
        }
      }
      if (numComplet == endpart.length) {
        if (error) {
        } else {
          merge = true;
        }
      }
      if (merge) {
        mainStatus.complete = true;
        await chargingMerge();
      }
    }
  }

  @pragma('vm:entry-point')
  downloadPart(PartDownload part) async {
    try {
      File f = File(
        '${request.setting!.folderTemp}${request.tokenDownload}${part.id}',
      );
      http.Request req = http.Request('Get', Uri.parse(part.url));
      bool exists = await f.exists();
      int idow = 0;
      endpart[part.id].start = true;
      if (exists) {
        idow = await f.length();
        totalSize += idow;
        part.start = part.start + idow;
        req.headers['range'] =
            'bytes=${part.start}-${part.end == 0 ? '' : part.end}';
        if (part.end - part.start < 0) {
          endpart[part.id].complete = true;
          initFuture();
          return false;
        }
      } else {
        req.headers['range'] =
            'bytes=${part.start}-${part.end == 0 ? '' : part.end}';
      }
      runZonedGuarded(
        () async {
          http.StreamedResponse res = await cln.send(req);
          IOSink fOut =
              exists
                  ? f.openWrite(mode: FileMode.append)
                  : f.openWrite(mode: FileMode.writeOnlyAppend);
          streamPart.addAll({
            part.id: res.stream.listen((byte) async {
              idow += byte.length;
              totalSize += byte.length;
              partStatus[part.id].porcent =
                  (idow * 100 / partStatus[part.id].sizeFinal).clamp(0.0, 100);
              partStatus[part.id].sizeDownload = idow;
              fOut.add(byte);
            }),
          });

          streamPart[part.id]!.onDone(() async {
            partStatus[part.id].complete = true;
            endpart[part.id].complete = true;
            partStatus[part.id].porcent = 100;
            streamPart[part.id]?.cancel();
            streamPart.remove(part.id);
            run.remove(part.id);
            fOut.close();
            initFuture();
          });
          streamPart[part.id]!.onError((e) {
            streamPart[part.id]!.cancel();
            endpart[part.id].error = true;
            streamPart.remove(part.id);
            run.remove(part.id);
            print(e);
          });
        },
        (error, stack) {
          sendPort.send(ErrorSendPort(stack: stack, errorObject: error));
        },
      );
    } catch (e) {
      print(e);
      sendPort.send(ErrorSendPort(errorObject: e));
    }
  }

  @pragma('vm:entry-point')
  chargingMerge() async {
    fOut = await joinMerge(
      request,
      header: header,
      manSetting: request.setting!,
      numpart: endpart.length,
    );
  }

  String velocity({required int startTime, required int size}) {
    try {
      double mb = (DateTime.now().millisecondsSinceEpoch - startTime) / 1000;
      return '$mb Mb/s';
    } catch (e) {
      return '...Mb/s';
    }
  }

  int limitSend = 5;
  @pragma('vm:entry-point')
  sendStatus() async {
    int sidow = 0;
    for (ManDownload e in partStatus) {
      sidow += e.sizeDownload;
    }
    mainStatus.porcent = totalSize * 100 / mainStatus.sizeFinal;
    mainStatus.sizeDownload = sidow;
    mainStatus.speed = velocity(
      startTime: startTime,
      size: mainStatus.sizeDownload,
    );
    if (!statusDownload.join && await File(fOut).exists()) {
      if (await File(fOut).length() == mainStatus.sizeFinal) {
        statusDownload.join = true;
      }
    }
    //cuando el porcentaje de descarga sea 100% se empezara a reducir el limite de envios al sendport y cuando llegue a 0 se lioberara el isolate para su nuevo uso
    if (mainStatus.complete && limitSend >= 0 && statusDownload.join) {
      mainStatus.porcent = 100;
      limitSend--;
    }
    if (limitSend == 0) {
      statusDownload.kill = true;
      statusDownload.freeIsolate = true;

      sendPort.send(statusDownload);
      sendInterval.cancel();
    } else {
      sendPort.send(mainStatus);
    }
  }
}
