import 'package:downloader_manager/src/file.dart';
import 'package:downloader_manager/src/model.dart';

import 'setting.dart';

class DownRequire {
  String fileName, url;
  bool priority, extension;
  ManSettings? setting;
  int token;
  DownRequire({
    this.fileName = '',
    required this.url,
    this.priority = false,
    this.extension = true,
    this.setting,
    this.token = 0,
  });
}

class DownloadManagerResponse {
  int token;
  bool status;
  DownloadManagerResponse({required this.token, required this.status});
}

class SelectTask {
  bool exists;
  TaskDownload? task;
  SelectTask({this.exists = false, this.task});
}

class ControllerTask {
  bool exists;
  Stream<StatusDownload>? controller;
  ControllerTask({this.controller, required this.exists});
}
