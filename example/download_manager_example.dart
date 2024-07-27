import 'package:download_manager/download_manager.dart';

void main() async {
  String url = 'https://download.samplelib.com/mp4/sample-5s.mp4';
  int tk = await manDownloader(
    req: downRequire(url: url, fileName: 'filename1.mp4'),
  );
  for (int i = 0; i < 10; i++) {
    manDown.task[tk]!.sub.stream.listen((e) {
      print('conexion port $i - ${e.main.porcent}');
    });
  }
  /* for (int i = 0; i <= 3; i++) {
    String url = 'https://download.samplelib.com/mp4/sample-5s.mp4';
    manDownloader(
      req: downRequire(url: url, fileName: 'filename$i.mp4'),
    );
  } */
}
