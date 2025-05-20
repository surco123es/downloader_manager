import 'dart:async';
import 'dart:isolate';

import 'package:mutex/mutex.dart';

import 'controller.dart';
import 'file.dart';
import 'model.dart';
import 'model_require.dart';
import 'request.dart';
import 'sendport.dart';
import 'setting.dart';

class DownloaderManager {
  //se encarga de no crusar peticiones a la hora de llamar a la funcion download();
  final _mutex = Mutex();
  bool _init = false;
  int _fast = 0;
  bool get fast => (_fast == 0) ? false : true;

  Map<int, TaskDownload> _task = {};
  Map<int, TokenDownloadStatus> _downloadsTask = {};
  List<StreamSubscription> _isolateSub = [];
  StreamController<ControllerType> _controller =
      StreamController<ControllerType>.broadcast();

  Stream<ControllerType> get controll => _controller.stream;

  Future<List<int>> init({required int numThread, ManSettings? setting}) async {
    //aqui esperamos que se inicialice el isolate y se cree el sendport
    //para que el isolate pueda recibir los mensajes
    List<Future<void>> isolates = [];
    try {
      if (_init) _task.keys.toList();
      for (int i = 0; i < numThread; i++) {
        final Completer completer = Completer<void>();
        int tk = ManSettings().token();
        _task.addAll({
          tk: TaskDownload(status: StatusDownloadIsolate(tokenIsolate: tk)),
        });
        TaskDownload isolate = _task[tk]!;
        isolate.root = await Isolate.spawn<RequestCreate>(
          DownloadManager().createIsolate,
          RequestCreate(
            setting: setting ?? ManSettings(),
            token: tk,
            sendPort: isolate.rcvPort.sendPort,
          ),
        );
        _listingIsolate(isolate, () {
          completer.complete();
        });
        isolates.add(completer.future);
        Future.any([
          completer.future,
          Future.delayed(Duration(seconds: 5)).then((_) {
            throw TimeoutException('El isolate no respondio en 5 segundos');
          }),
        ]);
      }
      await Future.wait(isolates);
      _init = true;
      return _task.keys.toList();
    } catch (e) {
      return [];
    }
  }

  _listingIsolate(TaskDownload task, Function call) {
    _isolateSub.add(
      task.rcvPort.listen((val) async {
        bool sendStream = false;
        if (val is CreateIsolateSendPort) {
          task.sendPort = val.sendPort;
          call();
        }
        if (val is ManDownload) {
          task.status.status.main = val;
          sendStream = true;
        }
        if (val is List<ManDownload>) {
          task.status.status.part = val;
          sendStream = true;
        }
        if (val is ErrorSendPort) {
          task.status.status.statusDownload = DownloadType.error;
          print('ocurio un error en el isolate ${task.status.tokenIsolate}');
          print('ocurio un error en el isolate ${val.errorObject}');
          print('ocurio un error en el isolate ${val.stack}');
          sendStream = true;
        }
        if (val is StatusDownloadSendPort) {
          sendStream = true;
          if (val.status == StatusIsolateType.startDownload) {
            task.tokenDownload = val.tokenDownload;
            task.status.status.main.status = DownloadType.startDownload;
            print('empezo la descarga la descarga ${task.status.tokenIsolate}');
          } else if (val.status == StatusIsolateType.freeIsolate) {
            task.status.status.main.status = DownloadType.complete;
            task.statusIsolate = StatusIsolateType.freeIsolate;
            _controller.sink.add(
              ControllerType(
                tokenIsolate: task.status.tokenIsolate,
                status: IsolateType.freeIsolate,
              ),
            );
            print('fast $_fast en ${task.tokenDownload}');
            if (_fast == task.tokenDownload) {
              _clearFastDownload();
            }
            print('se libero el isolate ${task.status.tokenIsolate}');
            task.tokenDownload = 0;
          } else if (val.status == StatusIsolateType.errorConexion) {
            print(
              'error en la conexion al archivo ${task.status.tokenIsolate}',
            );
          } else if (val.status == StatusIsolateType.fileExists) {
            print('el archivo ya existe ${task.status.tokenIsolate}');
            task.status.status.main.status = DownloadType.fileExists;
          } else if (val.status == StatusIsolateType.cancelDownload) {
            task.status.status.main.status = DownloadType.cancelDownload;

            print('se cancelo la descarga ${task.status.tokenIsolate}');
          } else if (val.status == StatusIsolateType.downloading) {
            if (task.statusIsolate == StatusIsolateType.pause) {
              task.status.status.main.status = DownloadType.downloading;
            }
          }
          _updateStatusTokenDownloadStatus(
            tokenDownload: val.tokenDownload,
            type: task.status.status.main.status,
          );
        } else if (val is ManDownload) {
          sendStream = true;
          task.status.status.main = val;
        }
        if (sendStream) {
          task.statusDownload.sink.add(task.status.status);
        }
      }),
    );
  }

  //esta funcion actualiza el estado de la descarga
  bool _updateStatusTokenDownloadStatus({
    required int tokenDownload,
    required DownloadType type,
  }) {
    SelectDownload sl = checkDownload(tokenDownload);
    if (sl.exists) return false;
    sl.status!.status = type;
    return true;
  }

  Future<DownloadManagerResponse> download({required DownRequire req}) async {
    await _mutex.acquire();
    try {
      SelectDownload selectDow = checkDownload(req.tokenDownload);
      if (selectDow.exists)
        return DownloadManagerResponse(
          tokenDownload: req.tokenDownload,
          status: true,
        );

      bool freeIsolate = false;
      int tokenIsolate = 0;
      late TaskDownload selectTask;
      for (int isolate in _task.keys) {
        TaskDownload ts = _selectIsolate(isolate).task!;
        if (ts.statusIsolate == StatusIsolateType.freeIsolate) {
          freeIsolate = true;
          tokenIsolate = isolate;
          ts.statusIsolate = StatusIsolateType.waiting;
          selectTask = ts;
          break;
        }
      }
      if (!freeIsolate)
        return DownloadManagerResponse(
          status: false,
          tokenDownload: req.tokenDownload,
          error: ErrorIsolate.limit,
        );

      if (req.tokenDownload == 0) {
        req.tokenDownload = ManSettings().token();
      }
      DownloadManagerResponse response = DownloadManagerResponse(
        tokenDownload: req.tokenDownload,
        status: true,
      );

      selectTask.sendPort.send(
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
      _downloadsTask.addAll({
        req.tokenDownload: TokenDownloadStatus(
          isolateToken: tokenIsolate,
          status: DownloadType.waiting,
        ),
      });
      _controller.sink.add(
        ControllerType(
          tokenIsolate: selectTask.status.tokenIsolate,
          status: IsolateType.busyIsolate,
          tokenDownload: req.tokenDownload,
        ),
      );
      return response;
    } finally {
      _mutex.release();
    }
  }

  bool pause(int tokenDownload) {
    SelectDownload selectDow = checkDownload(tokenDownload);
    if (!selectDow.exists) false;
    TokenDownloadStatus status = selectDow.status!;
    SelectTask st = _selectIsolate(status.isolateToken);
    if (!st.exists) false;
    TaskDownload dw = st.task!;
    if (dw.statusIsolate == StatusIsolateType.downloading) {
      dw.resume = dw.root.pause();
      dw.statusIsolate = StatusIsolateType.pause;
      selectDow.status!.status = DownloadType.pause;
      return true;
    }
    return false;
  }

  bool resume(int tokenDownload) {
    SelectDownload selectDow = checkDownload(tokenDownload);
    if (!selectDow.exists) false;
    TokenDownloadStatus status = selectDow.status!;
    SelectTask st = _selectIsolate(status.isolateToken);
    if (!st.exists) false;
    TaskDownload dw = st.task!;
    if (dw.statusIsolate == StatusIsolateType.pause) {
      dw.root.resume(dw.resume);
      dw.statusIsolate = StatusIsolateType.downloading;
      selectDow.status!.status = DownloadType.downloading;
      return true;
    }
    return false;
  }

  fastDownload(int tokenDownload) {
    if (tokenDownload == _fast) return true;
    _fast = tokenDownload;
    SelectDownload selectDow = checkDownload(tokenDownload);
    if (!selectDow.exists) return false;
    TokenDownloadStatus status = selectDow.status!;
    for (int e in _task.keys) {
      TaskDownload dw = _selectIsolate(e).task!;
      if (status.isolateToken != e) {
        if (dw.statusIsolate != StatusIsolateType.pause) {
          dw.resume = dw.root.pause();
          dw.statusIsolate = StatusIsolateType.pause;
          selectDow.status!.status = DownloadType.pause;
        }
      } else if (status.isolateToken == e &&
          dw.statusIsolate == StatusIsolateType.pause) {
        dw.root.resume(dw.resume);
        dw.sendPort.send(
          ManMessagePort(
            action: 'getStatus',
            download: ManReques(
              setting: ManSettings(),
              url: '',
              tokenDownload: 0,
              fileName: '',
            ),
          ),
        );
      }
    }
  }

  _clearFastDownload() {
    for (TaskDownload dw in _task.values) {
      if (dw.statusIsolate == StatusIsolateType.pause) {
        dw.root.resume(dw.resume);
        dw.sendPort.send(
          ManMessagePort(
            action: 'getStatus',
            download: ManReques(
              setting: ManSettings(),
              url: '',
              tokenDownload: 0,
              fileName: '',
            ),
          ),
        );
      }
    }
    _fast = 0;
  }

  Future<StatusDownloadIsolate> statusDownload(int tokenDownload) async {
    SelectDownload selectDow = checkDownload(tokenDownload);
    if (!selectDow.exists) StatusDownloadIsolate(tokenIsolate: 0);

    TokenDownloadStatus status = selectDow.status!;
    SelectTask st = _selectIsolate(status.isolateToken);
    if (!st.exists) StatusDownloadIsolate(tokenIsolate: 0);
    TaskDownload dw = st.task!;
    if (await dw.getStatus(tokenDownload)) {
      return dw.status;
    }
    return StatusDownloadIsolate(tokenIsolate: 0);
  }

  StatusIsolateType statusIsolate(int tokenIsolate) {
    SelectTask st = _selectIsolate(tokenIsolate);
    if (st.exists) {
      TaskDownload dw = st.task!;
      return dw.statusIsolate;
    } else {
      return StatusIsolateType.waiting;
    }
  }

  (bool, int) checkFreeIsolate() {
    for (int tokenIsolate in _task.keys) {
      TaskDownload ts = _selectIsolate(tokenIsolate).task!;
      if (ts.statusIsolate == StatusIsolateType.freeIsolate) {
        return (true, tokenIsolate);
      }
    }
    return (false, 0);
  }

  SelectDownload checkDownload(int tokenDownload) {
    if (_downloadsTask.containsKey(tokenDownload)) {
      return SelectDownload(
        exists: true,
        status: _downloadsTask[tokenDownload]!,
      );
    } else {
      return SelectDownload(exists: false);
    }
  }

  SelectTask _selectIsolate(int tokenIsolate) {
    if (_task.containsKey(tokenIsolate)) {
      return SelectTask(exists: true, task: _task[tokenIsolate]);
    } else {
      return SelectTask(exists: false);
    }
  }

  ControllerTask controller(int tokenDownload) {
    SelectDownload selectDow = checkDownload(tokenDownload);
    if (!selectDow.exists || selectDow.status == null)
      ControllerTask(exists: false);

    TokenDownloadStatus status = selectDow.status!;
    SelectTask st = _selectIsolate(status.isolateToken);
    if (!st.exists) ControllerTask(exists: false);
    TaskDownload dw = st.task!;
    if (!dw.getStatus(tokenDownload)) ControllerTask(exists: false);
    return ControllerTask(exists: true, controller: dw.statusDownload.stream);
  }

  Future<bool> cancel({required int tokenDownload}) async {
    try {
      SelectDownload selectDow = checkDownload(tokenDownload);
      if (!selectDow.exists) false;
      if (selectDow.status!.status == DownloadType.cancelDownload) true;
      TokenDownloadStatus status = selectDow.status!;
      SelectTask st = _selectIsolate(status.isolateToken);
      if (st.exists) {
        TaskDownload dw = st.task!;
        selectDow.status!.status = DownloadType.cancelDownload;
        dw.sendPort.send(ManMessagePort(action: 'cancel'));
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print(e);
      return false;
    }
  }

  forzeDownload({required int tokenDownload, String rename = ''}) {
    SelectDownload selectDow = checkDownload(tokenDownload);
    if (!selectDow.exists) false;
    TokenDownloadStatus status = selectDow.status!;
    SelectTask st = _selectIsolate(status.isolateToken);
    if (st.exists) {
      TaskDownload dw = st.task!;
      dw.sendPort.send(
        ManMessagePort(
          action: 'forceStart',
          download: ManReques(
            setting: ManSettings(),
            url: '',
            tokenDownload: tokenDownload,
            fileName: rename,
          ),
        ),
      );
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
    for (StreamSubscription sub in _isolateSub) {
      sub.cancel();
    }
    _isolateSub.clear();
    _task.clear();
    _init = false;
  }
}
