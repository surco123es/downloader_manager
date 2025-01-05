// ignoreforfile: camelcasetypes, unusedelement, libraryprivatetypesinpublicapi

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

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
  int startTime = 0;
  late Timer sendInterval;
  bool startInit = false;
  int partSizeLimit = 0;
  int numPart = 0;
  final cln = http.Client();
  int totalSize = 0;
  String fOut = '';
  bool sendPort = false;
  final Map<int, StreamSubscription> streamPart = {};
  late StreamSubscription reciverData;
  List<StatusItem> endpart = [];
  Map<int, Future<bool>> run = {};
  StatusDownload status = StatusDownload();
  late ManReques request;
  late ManSettings manSetting;
  late Map<String, dynamic> header;
  late ReceivePort rcv;

  starDownload(
    ManReques req,
  ) {
    rcv = ReceivePort();
    reciverData = rcv.listen((m) {
      ManMessagePort rver = m;
      if (rver.action == 'add') {
        request.fileName = rver.name;
        request.url = rver.url;
        manSetting = request.setting;
        numPart = 0;
        startInit = false;
        endpart.clear();
        streamPart.clear();
        status = StatusDownload();
        sendInterval.cancel();
        download();
      } else if (rver.action == 'sendport') {
        print('Aceeptado el sendPort');
        sendPort = true;
      } else if (rver.action == 'kill') {
        print('the send message for kill process');
        status.forceKill = true;
        sendStatus();
        sendInterval.cancel();
      }
    });
    request = req;
    manSetting = request.setting;
    download();
  }

  download() async {
    try {
      ManHttpStatus flD = await checkConexionFile(request.url);
      if (flD.status) {
        header = flD.header;
        final int total = header.containsKey('content-range') == true
            ? int.parse(flD.header["content-range"]!.split('/')[1].toString())
            : 0;
        partSizeLimit = total < 10242880 ? (total / 3).ceil() : 5242880;
        numPart = (total / partSizeLimit).ceil();
        int partDwn = (total / numPart).ceil();
        int endPart = partDwn;
        if (partDwn * numPart != total) {
          endPart = total - ((numPart - 1) * partDwn);
        }
        status.main = ManDownload(
          key: request.token,
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
          status.part.add(ManDownload(
            key: request.token,
            porcent: 0,
            sizeDownload: 0,
            sizeFinal: ipart,
            main: false,
            complete: false,
            speed: '..Mb',
          ));
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
        initFuture();
      } else {
        print('alerta');
      }
    } catch (e) {
      print(e);
      status.forceKill = true;
    }
  }

  initFuture({bool err = false}) async {
    int nunRun = streamPart.length;
    bool error = false;
    if (nunRun < manSetting.conexion) {
      bool merge = false;
      int numComplet = 0;
      for (StatusItem e in endpart) {
        if (!e.complete && !e.start) {
          if (nunRun < manSetting.conexion) {
            endpart[e.part.id].start = true;
            run.addAll({e.part.id: downloadPart(e.part)});
            nunRun++;
          }
        }
        if (err) {
          if (nunRun <= manSetting.conexion) {
            endpart[e.part.id].error = false;
            endpart[e.part.id].start = true;
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
        status.main.complete = true;
        await chargingMerge();
      }
      if (!startInit) {
        startTime = DateTime.now().millisecondsSinceEpoch;
        startInit = true;
        sendInterval = Timer.periodic(Duration(seconds: 1), (_) {
          sendStatus();
        });
      }
    }
  }

  Future<bool> downloadPart(PartDownload part) async {
    bool ret = true;
    try {
      File f = File('${manSetting.folderTemp}${request.token}${part.id}');
      http.Request req = http.Request(
        'Get',
        Uri.parse(part.url),
      );
      bool exists = await f.exists();
      int idow = 0;
      if (exists) {
        idow = await f.length();
        totalSize += idow;
        part.start = part.start + idow;
        req.headers['range'] = 'bytes=${part.start}-${part.end}';
        if (part.end - part.start < 0) {
          //initFuture();
          return ret;
        }
      } else {
        req.headers['range'] = 'bytes=${part.start}-${part.end}';
      }
      http.StreamedResponse res = await cln.send(req);
      IOSink fOut = exists
          ? f.openWrite(mode: FileMode.append)
          : f.openWrite(mode: FileMode.writeOnlyAppend);
      streamPart.addAll({
        part.id: res.stream.listen((byte) async {
          idow += byte.length;
          totalSize += byte.length;
          status.part[part.id].porcent =
              (idow * 100 / status.part[part.id].sizeFinal).clamp(0.0, 100);
          status.part[part.id].sizeDownload = idow;
          fOut.add(byte);
        }),
      });

      streamPart[part.id]!.onDone(() async {
        status.part[part.id].complete = true;
        endpart[part.id].complete = true;
        status.part[part.id].porcent = 100;
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
        initFuture();
        print(e);
      });
    } catch (e) {
      print(e);
      ret = false;
    }
    return ret;
  }

  chargingMerge() async {
    fOut = await joinMerge(
      request,
      header: header,
      manSetting: manSetting,
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
  sendStatus() async {
    int sidow = 0;
    for (var e in status.part) {
      sidow += e.sizeDownload;
    }
    status.main.porcent = totalSize * 100 / status.main.sizeFinal;
    status.main.sizeDownload = sidow;
    if (!sendPort) {
      status.sendPort = rcv.sendPort;
    }
    status.main.speed =
        velocity(startTime: startTime, size: status.main.sizeDownload);
    if (!status.join && await File(fOut).exists()) {
      if (await File(fOut).length() == status.main.sizeFinal) {
        status.join = true;
      }
    }
    if (status.main.complete && limitSend >= 0 && status.join) {
      status.main.porcent = 100;
      limitSend--;
    }

    if (limitSend == 0) {
      status.kill = true;
      sendInterval.cancel();
    }
    request.sendPort?.send(status);
  }
}
