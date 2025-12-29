import 'dart:math';

/// Simple location value object.
class AppLocation {
  final double latitude;
  final double longitude;

  const AppLocation(this.latitude, this.longitude);
}

/// Location-related utilities. For now this uses a dummy current location
/// suitable for design and testing.
class LocationService {
  /// In a real app, this would use a plugin (e.g. geolocator) or a map SDK.
  /// For this project, we just return a fixed dummy location.
  Future<AppLocation> getCurrentLocation() async {
    // Example: central reference point.
    return const AppLocation(37.7749, -122.4194);
  }

  /// Haversine distance between two lat/lng points, in kilometers.
  double distanceInKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;

    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
            cos(_deg2rad(lat1)) *
                cos(_deg2rad(lat2)) *
                sin(dLon / 2) *
                sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _deg2rad(double deg) => deg * (pi / 180.0);
}