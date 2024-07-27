// ignore_for_file: camel_case_types

import 'package:http/http.dart' as http;

class httpStatus {
  bool status;
  Map<String, dynamic> header;
  String body;
  httpStatus({
    required this.status,
    this.body = '',
    this.header = const {},
  });
}

Future<httpStatus> checkConexionFile(String url) async {
  httpStatus rs = httpStatus(status: false);
  try {
    http.Response res =
        await http.get(Uri.parse(url), headers: {'Range': 'bytes=0-128'});
    if (res.statusCode == 200 || res.statusCode == 206) {
      rs.status = true;
      rs.header = res.headers;
      rs.body = res.body;
    }
    return rs;
  } catch (e_) {
    print(e_);
    return rs;
  }
}

String manFileName(String str) {
  List ltr = [
    'à',
    'á',
    'â',
    'ã',
    'ä',
    'ç',
    'è',
    'é',
    'ê',
    'ë',
    'ì',
    'í',
    'î',
    'ï',
    'ñ',
    'ò',
    'ó',
    'ô',
    'õ',
    'ö',
    'ù',
    'ú',
    'û',
    'ü',
    'ý',
    'ÿ',
    'À',
    'Á',
    'Â',
    'Ã',
    'Ä',
    'Ç',
    'È',
    'É',
    'Ê',
    'Ë',
    'Ì',
    'Í',
    'Î',
    'Ï',
    'Ñ',
    'Ò',
    'Ó',
    'Ô',
    'Õ',
    'Ö',
    'Ù',
    'Ú',
    'Û',
    'Ü',
    'Ý',
    ',',
    ':',
    '"',
    "'",
    '&',
    ';',
    '@',
    '>',
    '<',
    '|'
  ];

  for (var i = 0, c = ltr.length; i < c; i++) {
    var rg = RegExp('[${ltr[i]}]');
    str = str.replaceAll(rg, '');
  }

  return str;
}
