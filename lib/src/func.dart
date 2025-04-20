import 'package:http/http.dart' as http;

class ManHttpStatus {
  bool status;
  Map<String, dynamic> header;
  String body;
  ManHttpStatus({
    required this.status,
    this.body = '',
    this.header = const {},
  });
}

Future<ManHttpStatus> checkConexionFile(String url) async {
  ManHttpStatus rs = ManHttpStatus(status: false);
  try {
    http.Response res = await http.head(Uri.parse(url));
    if (res.statusCode == 200 || res.statusCode == 206) {
      rs.status = true;
      rs.header = res.headers;
      rs.body = res.body;
    }
    return rs;
  } catch (e) {
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
