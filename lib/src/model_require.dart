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
  DownloadManagerResponse({
    required this.token,
    required this.status,
  });
}
