// ignore_for_file: camel_case_types, non_constant_identifier_names, unused_element, library_private_types_in_public_api, no_leading_underscores_for_local_identifiers

import 'dart:async';
import 'dart:isolate';

import '../download_manager.dart';
import 'download.dart';
import 'request.dart';

class TaskDownload {
  bool complete, pause, kill, init;
  late Isolate _root;
  final StreamController<StatusDownload> sub =
      StreamController<StatusDownload>.broadcast();
  ReceivePort rcvPort = ReceivePort();
  int token;

  late Capability _cap;
  TaskDownload({
    this.complete = false,
    this.pause = false,
    this.kill = false,
    this.init = false,
    required this.token,
  });

  pauseOresume() async {
    if (pause) {
      _root.resume(_cap);
    } else {
      _cap = _root.pause(_root.pauseCapability);
    }
    pause = !pause;
  }

  listing() {
    rcvPort.listen((val) async {
      StatusDownload e = val;
      sub.sink.add(e);
      if ((e.main.complete && e.kill) || e.forceKill) {
        complete = e.forceKill ? false : true;
        kill = true;
        manDown.stop(token: token);
        sub.close();
        rcvPort.close();
        _root.kill(priority: Isolate.immediate);
      }
    });
  }
}

class ManagerDownload {
  Map<int, TaskDownload> task = {};
  Future<bool> create(DownRequire _rq) async {
    ManSettings msetting = _rq.setting ??= ManSettings();
    ManReques _req = ManReques(
      url: _rq.url,
      extension: _rq.extension,
      fileName: _rq.fileName,
      token: _rq.token,
      priority: _rq.priority,
      setting: msetting,
    );
    bool res = true;
    TaskDownload tsk = TaskDownload(token: _req.token);
    task.addAll({_req.token: tsk});
    _req.sendPort = task[_req.token]?.rcvPort.sendPort;
    task[_req.token]?._root =
        await Isolate.spawn<ManReques>(RunDownload().starDownload, _req);
    task[_req.token]?.listing();
    return res;
  }

  stop({required int token}) async {
    if (task.containsKey(token)) {
      task[token]?.kill = true;
      task[token]?.rcvPort.close();
      task[token]?.sub.close();
      task[token]?._root.kill(priority: Isolate.immediate);
      task.remove(token);
    }
  }
}
