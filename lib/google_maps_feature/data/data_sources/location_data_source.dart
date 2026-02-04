part of '../../home.dart';


abstract interface class LocationDataSource {
  Future<Position> getCurrentLocation();
  Future<Position?> getLastKnownLocation();
  Future<bool> checkAndRequestPermission();
  Stream<Position> getLocationStream();
  Future<bool> isLocationServiceEnabled();
}

class LocationDataSourceImpl implements LocationDataSource {
  final ILocationCache _locationCache;

  LocationDataSourceImpl(this._locationCache);

  @override
  Future<Position> getCurrentLocation() async {
    // logger("Started Get Current Location");
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    // Check and request permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    // Get current position with proper LocationSettings
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );

    // Cache the location to Hive for persistence
    await _locationCache.saveLastLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      timestamp: position.timestamp.millisecondsSinceEpoch,
    );

    return position;
  }

  @override
  Future<Position?> getLastKnownLocation() async {
    // First try to get from geolocator (in-memory cache)
    final geolocatorPosition = await Geolocator.getLastKnownPosition();
    if (geolocatorPosition != null) {
      return geolocatorPosition;
    }

    // Fallback to Hive cache (persistent storage)
    final cachedLocation = _locationCache.getLastLocation();
    if (cachedLocation != null) {
      return Position(
        latitude: cachedLocation['latitude'],
        longitude: cachedLocation['longitude'],
        timestamp: DateTime.fromMillisecondsSinceEpoch(
          cachedLocation['timestamp'],
        ),
        accuracy: cachedLocation['accuracy'],
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );
    }

    return null;
  }

  @override
  Future<bool> checkAndRequestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  @override
  Stream<Position> getLocationStream() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );
    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  @override
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }
}
