part of 'local_storage.dart';

abstract interface class ILocationCache {
  Future<void> saveLastLocation({
    required double latitude,
    required double longitude,
    required double accuracy,
    required int timestamp,
  });

  Map<String, dynamic>? getLastLocation();

  Future<void> clearLastLocation();
}




class LocationCacheImpl implements ILocationCache {
  static const String boxName = 'location_cache_box';
  static const String _key = 'last_location';

  final Box box;
  LocationCacheImpl(this.box);

  @override
  Future<void> saveLastLocation({
    required double latitude,
    required double longitude,
    required double accuracy,
    required int timestamp,
  }) async {
    await box.put(_key, {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'timestamp': timestamp,
    });
  }

  @override
  Map<String, dynamic>? getLastLocation() {
    final data = box.get(_key);
    if (data == null) return null;

    // Hive بيرجع dynamic
    return Map<String, dynamic>.from(data as Map);
  }

  @override
  Future<void> clearLastLocation() async {
    await box.delete(_key);
  }
}
