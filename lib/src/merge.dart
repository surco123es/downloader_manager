// ignore_for_file: library_private_types_in_public_api, camel_case_types, unused_element

import 'dart:async';
import 'dart:io';

import 'package:download_manager/download_manager.dart';
import 'package:download_manager/src/mime.dart';
import 'package:download_manager/src/request.dart';

Future<int> _checkExists(String name, String ext, int num) async {
  if (await File('$name$num$ext').exists()) {
    return await _checkExists(name, ext, num + 1);
  } else {
    return num;
  }
}

Future<String> joinMerge(
  manReques req, {
  Map<String, dynamic> header = const {},
  required manSettings manSetting,
  required int numpart,
}) async {
  String fName = '';
  late File fli;
  String ext = '';
  try {
    if (req.extension) {
      String ext =
          '.${manMime.getExt(header.containsKey('content-type') ? header["content-type"] : '')}';
      if (req.fileName == '') {
        req.fileName = req.token.toString();
      }
      fName = '${manSetting.folderOut}${req.fileName}.$ext';
    } else {
      fName = '${manSetting.folderOut}${req.fileName}';
    }
    fli = File(fName);
    if (await fli.exists()) {
      int num = await _checkExists('${manSetting.folderOut}${req.fileName}-(',
          ')${(req.extension ? ext : '')}', 1);
      fli = File(
          '${manSetting.folderOut}${req.fileName}-($num)${(req.extension ? ext : '')}');
    }
    IOSink fl = fli.openWrite(mode: FileMode.writeOnlyAppend);
    for (int i = 0; i < numpart; i++) {
      File f = File('${manSetting.folderTemp}${req.token}$i');
      if (await f.exists()) {
        Stream<List<int>> read = f.openRead();
        await fl.addStream(read).then((_) async {
          f.delete();
        });
      }
    }
    await fl.close();
  } catch (e) {
    fName = '';
  }
  return fName;
}
