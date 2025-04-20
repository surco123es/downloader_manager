import 'dart:io';

import 'package:downloader_manager/downloader_manager.dart';

DownloaderManager manDown = DownloaderManager();
void main() async {
  await manDown.init(numThread: 3, setting: ManSettings());
  List<DownloadManagerResponse> tokens = await [
    await manDown.download(
      req: DownRequire(
        url:
            'https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe',
        fileName: 'yt.exe',
        extension: false,
        tokenDownload: 10001,
      ),
    ),
  ];
  for (DownloadManagerResponse tk in tokens) {
    ControllerTask cn = manDown.controller(tk.token);
    print(cn.exists);
    if (!cn.exists) return;
    bool pause = false;
    cn.controller!.listen((e) {
      if (e.error) {
        print('existio un error');
      }
      print('conexion port main - ${e.main.porcent}');
      if (e.main.porcent > 50 && !pause) {
        manDown.pause(tk.token);
        print('pausado');
        pause = true;
        sleep(Duration(milliseconds: 3000));
        print('continuando');
        print(manDown.resume(tk.token));
      }
      if (e.main.complete) {
        sleep(Duration(milliseconds: 3000));
        print('apagando los isolates');
        manDown.dispose();
      }
    });
  }
}
