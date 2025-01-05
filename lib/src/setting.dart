// ignore_for_file: unused_element, camel_case_types, library_private_types_in_public_api

import 'dart:math';

class ManSettings {
  int conexion;
  String folderTemp, folderOut;
  int limitBand;
  ManSettings({
    this.conexion = 2,
    this.folderTemp = 'temp/',
    this.folderOut = 'out/',
    this.limitBand = 5000,
  });
  factory ManSettings.fronJson(Map<String, dynamic> js) {
    return ManSettings(
      conexion: js['conexion'],
      folderOut: js['folderOut'],
      folderTemp: js['folderTemp'],
      limitBand: js['limitBand'],
    );
  }
  Map<String, dynamic> json() {
    return {
      'conexion': conexion,
      'folderTemp': folderTemp,
      'folderOut': folderOut,
      'limitBand': limitBand
    };
  }

  int token() {
    Random random = Random();
    int max = 99999;
    int min = 10000;
    int token = min + random.nextInt((max + 1) - 1);
    return token;
  }
}

class DownRequire {
  String fileName, url;
  bool priority, extension;
  ManSettings? setting;
  int token;
  DownRequire({
    this.fileName = '',
    required this.url,
    this.priority = false,
    this.extension = true,
    this.setting,
    this.token = 0,
  });
}
