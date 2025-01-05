// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'file.dart';
import 'setting.dart';

Future<int> manDownloader({
  required DownRequire req,
  Function? fc,
}) async {
  if (req.token == 0) {
    req.token = ManSettings().token();
  }
  await manDown.create(req);
  if (fc != null) {
    fc();
  }
  return req.token;
}
