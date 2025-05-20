class Velocity {
  List<double> velocitys = [];
  final int maxVelocity = 10;
  int _downloadSize = 0;
  Duration interval = Duration(seconds: 1);
  DateTime start = DateTime.now();
  int lastDownloadSize = 0;
  set downloadSize(int size) {
    _downloadSize = size;
  }

  String get speed {
    try {
      final now = DateTime.now();
      final elapsed = now.difference(start).inMilliseconds;
      if (elapsed < interval.inMilliseconds) {
        return '${_calulateVelocity()} MB/s'; // Convert to MB/s
      }
      final downloadSpeedLast = _downloadSize - lastDownloadSize;
      final speedByteSecond = downloadSpeedLast / (elapsed / 100);
      start = now;
      lastDownloadSize = _downloadSize;
      velocitys.add(speedByteSecond);
      if (velocitys.length > maxVelocity) {
        velocitys.removeAt(0);
      }
      return '${_calulateVelocity()} MB/s';
    } catch (e) {
      print(e);
      return '...Mb';
    }
  }

  double _calulateVelocity() {
    if (velocitys.isEmpty) return 0.0;
    final average = velocitys.reduce((a, b) => a + b) / velocitys.length;
    return (average / 1024 / 1024).clamp(0.0, double.infinity);
  }
}
