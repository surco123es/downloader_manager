import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../file.dart';
import '../model_require.dart';
import '../sendport.dart';
import 'model.dart';

class Downloader {
  late ErrorSendPort errorPart;
  bool cancel = false;
  DataDownload downloadData;
  String fileTemp;
  int partSizeDownload = 0;
  DownloadType status;
  ManDownload partStatus = ManDownload(
    porcent: 0,
    sizeDownload: 0,
    sizeFinal: 0,
    speed: '..Mb',
  );
  int notification = -1;
  int _lenght = 0;
  StreamController<(DownloadType, int)> controller =
      StreamController<(DownloadType, int)>();
  Downloader({
    required this.downloadData,
    required this.fileTemp,
    this.status = DownloadType.waiting,
  });
  @pragma('vm:entry-point')
  Future<void> startDownload() async {
    http.Client client = http.Client();
    try {
      status = DownloadType.downloading;
      File f = File(fileTemp);
      http.Request req = http.Request('Get', Uri.parse(downloadData.url));
      bool exists = await f.exists();
      controller.sink.add((DownloadType.startDownload, downloadData.id));
      partStatus.sizeFinal = downloadData.end - downloadData.start;
      if (exists) {
        partSizeDownload = await f.length();
        downloadData.start = downloadData.start + partSizeDownload;
        req.headers['range'] =
            'bytes=${downloadData.start}-${downloadData.end == 0 ? '' : downloadData.end}';
        if (downloadData.end - downloadData.start < 0) {
          _completeDownload(partSizeDownload);
          return;
        }
      } else {
        f.create(recursive: true);
        req.headers['range'] =
            'bytes=${downloadData.start}-${downloadData.end == 0 ? '' : downloadData.end}';
      }
      http.StreamedResponse res = await client.send(req);
      final fOut = f.openWrite(mode: FileMode.writeOnlyAppend);

      int sentVal = 0;
      await for (final List<int> byte in res.stream) {
        fOut.add(byte);
        if (cancel) {
          fOut.close();
          client.close();
          _cancelDownload();
          break;
        }
        _lenght += byte.length;
        partSizeDownload += byte.length;
        partStatus.porcent = (partSizeDownload * 100 / partStatus.sizeFinal)
            .clamp(0.0, 100);
        partStatus.sizeDownload = partSizeDownload;
        int not = (partStatus.porcent ~/ 5) * 5;
        if (not > notification && sentVal != not) {
          sentVal = not;
          _sendPorcent();
        }
      }
      if (!cancel) {
        fOut.close();
        _completeDownload(0);
      }
    } catch (e) {
      _errorDownload(e);
    } finally {
      client.close();
    }
  }

  //////////////////////////// manejadores de descarga de startDownload
  ///
  _sendPorcent() {
    try {
      status = DownloadType.downloading;
      controller.sink.add((status, _lenght));
      _lenght = 0;
    } catch (e) {
      print(e);
    }
  }

  _cancelDownload() {
    try {
      status = DownloadType.cancelDownload;
      controller.sink.add((status, downloadData.id));
    } catch (e) {
      print(e);
    }
  }

  _completeDownload(int size) {
    try {
      status = DownloadType.complete;
      controller.sink.add((status, size));
    } catch (e) {
      print(e);
    }
  }

  _errorDownload(Object e) {
    try {
      status = DownloadType.error;
      errorPart = ErrorSendPort(errorObject: e, stack: StackTrace.current);
      controller.sink.add((status, downloadData.id));
    } catch (e) {
      print(e);
    }
  }

  //////////////////////////////final de manjeadores de descarga
  dispose() {
    controller.close();
  }
}
