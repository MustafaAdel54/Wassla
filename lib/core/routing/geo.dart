import 'dart:math';

/// Haversine distance in meters between two geographic points.
/// Direct port from V4 Python engine geo.py.
double haversineM(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371000.0;
  final p1 = _radians(lat1);
  final p2 = _radians(lat2);
  final dp = _radians(lat2 - lat1);
  final dl = _radians(lng2 - lng1);
  final a =
      sin(dp / 2) * sin(dp / 2) + cos(p1) * cos(p2) * sin(dl / 2) * sin(dl / 2);
  return 2 * r * atan2(sqrt(a), sqrt(1 - a));
}

double _radians(double degrees) => degrees * pi / 180.0;
