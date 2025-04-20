// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:io';
import 'dart:isolate';

import 'download.dart';
import 'model.dart';
import 'model_require.dart';
import 'request.dart';
import 'sendport.dart';
import 'setting.dart';

class DownloaderManager {
  bool _init = false;
  Map<int, TaskDownload> _task = {};
  Map<int, TokenDownload> _downloadsTask = {};
  Future<List<int>> init({required int numThread, ManSettings? setting}) async {
    try {
      if (_init) return _task.keys.toList();
      for (int i = 0; i < numThread; i++) {
        int tk = ManSettings().token();
        _task.addAll({
          tk: TaskDownload(status: StatusDownloadIsolate(tokenIsolate: tk)),
        });
        _task[tk]!.root = await Isolate.spawn<RequestCreate>(
          RunDownload().createIsolate,
          RequestCreate(
            setting: setting ?? ManSettings(),
            token: tk,
            sendPort: _task[tk]!.rcvPort.sendPort,
          ),
        );

        sleep(Duration(milliseconds: 150));
      }
      _init = true;
      return _task.keys.toList();
    } catch (e) {
      print(e);
      return [];
    }
  }

  @pragma('vm:entry-point')
  Future<DownloadManagerResponse> download({required DownRequire req}) async {
    print('object');
    if (_downloadsTask.containsKey(req.tokenDownload)) {
      //retorna el isolate en el cual se esta descargando
      return DownloadManagerResponse(
        token: _downloadsTask[req.tokenDownload]!.isolateToken,
        status: true,
      );
    }

    bool freeIsolate = false;
    int tokenIsolate = 0;
    for (int isolate in _task.keys) {
      TaskDownload ts = _select(isolate).task!;
      if (ts.freeIsolate) {
        freeIsolate = true;
        tokenIsolate = isolate;
        ts.freeIsolate = false;
        break;
      }
    }
    if (!freeIsolate)
      return DownloadManagerResponse(
        token: 0,
        status: false,
        error: ErrorIsolate.limit,
      );

    DownloadManagerResponse response = DownloadManagerResponse(
      token: tokenIsolate,
      status: true,
    );
    if (req.tokenDownload == 0) {
      req.tokenDownload = ManSettings().token();
    }
    _select(response.token).task?.sendPortIsolate().send(
      ManMessagePort(
        action: 'add',
        download: ManReques(
          setting: req.setting,
          url: req.url,
          fileName: req.fileName,
          extension: req.extension,
          tokenDownload: req.tokenDownload,
        ),
      ),
    );
    return response;
  }

  bool pause(int token) {
    SelectTask st = _select(token);
    if (!st.exists) return false;
    TaskDownload dw = st.task!;
    if (!dw.status.pause) {
      dw.resume = dw.root.pause();
      dw.status.pause = true;
      return true;
    }
    return false;
  }

  bool resume(int token) {
    SelectTask st = _select(token);
    if (!st.exists) return false;
    TaskDownload dw = st.task!;
    if (dw.status.pause) {
      dw.root.resume(dw.resume);
      dw.status.pause = false;
      return true;
    }
    return false;
  }

  StatusDownloadIsolate status(int token) {
    SelectTask st = _select(token);
    if (st.exists) {
      TaskDownload dw = st.task!;
      return dw.status;
    } else {
      return StatusDownloadIsolate(tokenIsolate: token);
    }
  }

  SelectTask _select(int token) {
    if (_task.containsKey(token)) {
      return SelectTask(exists: true, task: _task[token]);
    } else {
      return SelectTask(exists: false);
    }
  }

  ControllerTask controller(int token) {
    SelectTask st = _select(token);
    if (st.exists) {
      TaskDownload dw = st.task!;
      return ControllerTask(exists: true, controller: dw.statusDownload.stream);
    } else {
      return ControllerTask(exists: false);
    }
  }

  Future<bool> cancel({required int token}) async {
    SelectTask st = _select(token);
    if (st.exists) {
      TaskDownload dw = st.task!;
      dw.sendPortIsolate().send(ManMessagePort(action: 'stop'));
      return true;
    } else {
      return false;
    }
  }

  dispose() {
    for (int token in _task.keys) {
      TaskDownload dw = _task[token]!;
      dw.rcvPort.close();
      dw.statusDownload.close();
      dw.root.kill(priority: Isolate.immediate);
    }
    _task.clear();
    _init = false;
  }
}
