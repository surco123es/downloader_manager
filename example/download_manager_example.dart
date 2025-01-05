import 'package:download_manager/download_manager.dart';

void main() async {
  String url =
      'https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe';
  int tk = await manDownloader(
    req: DownRequire(url: url, fileName: 'yt'),
  );
  manDown.task[tk]!.sub.stream.listen((e) {
    print('conexion port main - ${e.main.porcent}');
  });
  /* for (int i = 0; i <= 3; i++) {
    String url = 'https://download.samplelib.com/mp4/sample-5s.mp4';
    manDownloader(
      req: downRequire(url: url, fileName: 'filename$i.mp4'),
    );
  } */
}
