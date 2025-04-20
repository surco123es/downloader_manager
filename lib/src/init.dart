// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:isolate';

import 'download.dart';
import 'model.dart';
import 'model_require.dart';
import 'request.dart';
import 'setting.dart';

class DownloaderManager {
  Map<int, TaskDownload> _task = {};

  @pragma('vm:entry-point')
  Future<DownloadManagerResponse> create({
    required DownRequire req,
    Function? fc,
  }) async {
    DownloadManagerResponse response = DownloadManagerResponse(
      token: 0,
      status: true,
    );
    try {
      if (req.token == 0) {
        req.token = ManSettings().token();
      }
      response.token = req.token;

      ManReques _req = ManReques(
        url: req.url,
        extension: req.extension,
        fileName: req.fileName,
        token: req.token,
        priority: req.priority,
        setting: req.setting ??= ManSettings(),
      );
      _task.addAll({response.token: TaskDownload(token: response.token)});
      _req.sendPort = _task[response.token]?.rcvPort.sendPort;
      _task[response.token]?.root = await Isolate.spawn<ManReques>(
        RunDownload().starDownload,
        _req,
      );
      _task[response.token]?.listing();

      if (fc != null) {
        fc();
      }
    } catch (e) {
      response.status = false;
    }
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

  StatusDownloadIsolate status(int token) {
    SelectTask st = _select(token);
    if (st.exists) {
      TaskDownload dw = st.task!;
      return dw.status;
    } else {
      return StatusDownloadIsolate();
    }
  }

  bool resume(int token) {
    SelectTask st = _select(token);
    if (!st.exists) return false;
    TaskDownload dw = st.task!;
    if (!dw.status.pause) {
      dw.root.resume(dw.resume);
      dw.status.pause = false;
      return true;
    }
    return false;
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

  Future<bool> stop({required int token}) async {
    SelectTask st = _select(token);
    if (st.exists) {
      TaskDownload dw = st.task!;
      if (dw.status.kill) return false;
      dw.status.kill = true;
      dw.rcvPort.close();
      dw.statusDownload.close();
      dw.root.kill(priority: Isolate.immediate);
      _task.remove(token);
      return true;
    } else {
      return false;
    }
  }
}
