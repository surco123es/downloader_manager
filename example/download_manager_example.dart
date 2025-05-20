import 'dart:io';

import 'package:downloader_manager/downloader_manager.dart';

DownloaderManager manDown = DownloaderManager();
void main() async {
  await manDown.init(numThread: 3, setting: ManSettings());
  List<DownloadManagerResponse> tokens = await [
    await manDown.download(
      req: DownRequire(
        url:
            'https://raw.githubusercontent.com/surco123es/ffmpegDir/refs/heads/main/ffmpeg.exe',
        fileName: 'yt.exe',
        extension: false,
        tokenDownload: 10001,
      ),
    ),
    await manDown.download(
      req: DownRequire(
        url:
            'https://raw.githubusercontent.com/surco123es/ffmpegDir/refs/heads/main/ffmpeg.exe',
        fileName: 'segundo.exe',
        extension: false,
        tokenDownload: 10002,
      ),
    ),
    await manDown.download(
      req: DownRequire(
        url:
            'https://raw.githubusercontent.com/surco123es/ffmpegDir/refs/heads/main/ffmpeg.exe',
        fileName: 'tercero.exe',
        extension: false,
        tokenDownload: 10003,
      ),
    ),
  ];

  for (DownloadManagerResponse tk in tokens) {
    if (!tk.status) return;
    ControllerTask cn = manDown.controller(tk.tokenDownload);
    print('token: ${tk.tokenDownload}');
    if (!cn.exists) return;
    bool pause = false;
    cn.controller!.listen((e) async {
      print(e.main.status);
      if (e.main.status == DownloadType.fileExists) {
        manDown.cancel(tokenDownload: tk.tokenDownload);
        print('el archivo existe');
      }
      if (e.main.status == DownloadType.error) {
        print('existio un error');
      }

      print(e.main.porcent);
      if (e.main.porcent > 50) {
        /* bool sta = await manDown.cancel(tokenDownload: tk.tokenDownload);
        if (sta) {
          print(sta);
        } */
        if (manDown.fast) return;
        manDown.fastDownload(tk.tokenDownload);
        print(
          'cancelando la descarga /////////////////////////////////////////////////////////////////////////////////',
        );
      }
      if (e.main.status == DownloadType.complete) {
        sleep(Duration(milliseconds: 3000));
        SelectDownload st = await manDown.checkDownload(tk.tokenDownload);
        if (!st.exists) return;

        print('apagando los isolates');
        //manDown.dispose();
      }
    });
  }
  manDown.controll.listen((e) async {
    print(e.status);
    if (e.status == IsolateType.freeIsolate) {
      print('se libero el isolate ${e.tokenIsolate}');
      await manDown.download(
        req: DownRequire(
          url:
              'https://raw.githubusercontent.com/surco123es/ffmpegDir/refs/heads/main/ffmpeg.exe',
          fileName: 'cuarto.exe',
          extension: false,
          tokenDownload: 10004,
        ),
      );
    }
  });
}
