import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'mime.dart';
import '../request.dart';

class MergePartDownload {
  String fileName;

  MergePartDownload({required this.fileName});
  @pragma('vm:entry-point')
  Future<(String, bool)> checkFileExists({
    required Map<String, dynamic> header,
    required ManReques request,
    required bool exists,
  }) async {
    String extension = '';
    String outName = '';
    if (fileName == '') {
      fileName =
          header.containsKey('content-type')
              ? ''
              : request.tokenDownload.toString();
    }
    Queue<String> ext = Queue<String>()..addAll(fileName.split('.'));
    if (request.extension) {
      extension =
          '.${manMime.getExt(header.containsKey('content-type') ? header["content-type"] : '')}';
    } else {
      extension = ext.last;
    }
    outName = '${request.setting!.folderOut}${fileName}'.replaceAll(
      '.$extension',
      '',
    );
    String nameExtension =
        (extension != '') ? outName + '.$extension' : outName;
    int num = 1;
    while (await File(nameExtension).exists()) {
      nameExtension = outName + '-($num).$extension';
      num++;
    }
    fileName = nameExtension;
    print(fileName);
    if (exists && num > 1) {
      return (nameExtension, false);
    }
    return (nameExtension, true);
  }

  Future<bool> joinMerge({
    required String temp,
    required String token,
    required int numpart,
  }) async {
    try {
      File fli = File(fileName);
      IOSink fl = fli.openWrite(mode: FileMode.append);
      for (int i = 0; i < numpart; i++) {
        File f = File('$temp$token$i');
        if (await f.exists()) {
          Stream<List<int>> read = f.openRead();
          await fl.addStream(read).then((_) async {
            f.delete();
          });
        }
      }
      await fl.close();
      return true;
    } catch (e) {
      return false;
    }
  }
}
