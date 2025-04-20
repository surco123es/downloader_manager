import 'package:downloader_manager/downloader_manager.dart';
import 'package:downloader_manager/src/model.dart';

ManagerDownload manDown = ManagerDownload();
void main() async {
  List<DownloadManagerResponse> tokens = await [
    await manDown.create(
      req: DownRequire(
        url:
            'https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe',
        fileName: 'yt.exe',
        extension: false,
        priority: true,
        token: 10001,
      ),
    ),
    await manDown.create(
      req: DownRequire(
        url:
            'https://github.com/surco123es/ffmpegDir/releases/download/1.1/ffprobe.exe',
        fileName: 'ffprobe.exe',
        extension: false,
        priority: true,
        token: 10002,
      ),
    ),
    await manDown.create(
      req: DownRequire(
        url:
            'https://github.com/surco123es/ffmpegDir/releases/download/1.1/ffmpeg.exe',
        fileName: 'ffmpeg.exe',
        extension: false,
        priority: true,
        token: 10003,
        setting: ManSettings(folderOut: 'temp/', folderTemp: 'temp/'),
      ),
    ),
  ];
  for (DownloadManagerResponse tk in tokens) {
    ControllerTask cn = manDown.controller(tk.token);
    if (!cn.exists) return;
    cn.controller!.listen((e) {
      if (e.error) {
        print('existio un error');
      }
      print('conexion port main - ${e.main.porcent}');
    });
  }
}
