// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'package:download_manager/download_manager.dart';

Future<int> manDownloader({
  required downRequire req,
  Function? fc,
}) async {
  if (req.token == 0) {
    req.token = manSettings().token();
  }
  await manDown.create(req);
  if (fc != null) {
    fc();
  }
  return req.token;
}
