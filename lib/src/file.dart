import 'model_require.dart';

class ManFile {
  String title, folderTemp, folderOut, url;
  bool replace, complete, download;
  int sizeFinal, sizeDownload, partDownload, key, task;
  ManFile({
    required this.title,
    required this.folderOut,
    required this.folderTemp,
    required this.key,
    required this.url,
    required this.task,
    this.complete = false,
    this.download = false,
    this.partDownload = 0,
    this.replace = false,
    this.sizeDownload = 0,
    this.sizeFinal = 0,
  });
}

class ManDownload {
  int sizeDownload, sizeFinal;
  DownloadType status = DownloadType.waiting;
  double porcent;
  String speed;
  ManDownload({
    required this.speed,
    required this.porcent,
    required this.sizeDownload,
    required this.sizeFinal,
  });
}

class StatusDownload {
  ManDownload main;
  DownloadType statusDownload = DownloadType.waiting;
  List<ManDownload> part;
  StatusDownload({required this.main, required this.part});
}
