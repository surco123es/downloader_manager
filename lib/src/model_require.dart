import 'file.dart';
import 'model.dart';
import 'setting.dart';

enum ErrorIsolate {
  //se alcanzo el limite de isolate activos
  limit,
  //no se encontro ningun error
  noEror,
  //todos los isolates estan ocupados pero se añade a la lista de espera
  waiting,
}

enum IsolateType {
  //el isolate esta libre para ser usado
  freeIsolate,
  //el isolate esta ocupado y no se puede usar
  busyIsolate,
}

enum DownloadType {
  waiting,
  join,
  errorDownload,
  errorJoin,
  error,
  startDownload,
  complete,
  errorConexion,
  fileExists,
  errorMerge,
  downloading,
  cancelDownload,
  pause,
  resume,
}

class DownRequire {
  String fileName, url;
  bool extension;
  ManSettings? setting;
  int tokenDownload;
  DownRequire({
    this.fileName = '',
    required this.url,
    this.extension = true,
    this.setting,
    this.tokenDownload = 0,
  });
}

//sera este el retorno de las descargas para manejar el estado de la descarga
class DownloadManagerResponse {
  int tokenDownload;
  bool status;
  ErrorIsolate error;
  DownloadManagerResponse({
    required this.tokenDownload,
    required this.status,
    this.error = ErrorIsolate.noEror,
  });
}

class SelectTask {
  bool exists;
  TaskDownload? task;
  SelectTask({this.exists = false, this.task});
}

class SelectDownload {
  bool exists;
  TokenDownloadStatus? status;
  SelectDownload({required this.exists, this.status});
}

class ControllerType {
  int tokenIsolate;
  int tokenDownload;
  IsolateType status;
  ControllerType({
    required this.tokenIsolate,
    required this.status,
    this.tokenDownload = 0,
  });
}

class ControllerTask {
  bool exists;
  Stream<StatusDownload>? controller;
  ControllerTask({this.controller, required this.exists});
}
