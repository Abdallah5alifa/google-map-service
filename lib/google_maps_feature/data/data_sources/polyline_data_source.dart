part of '../../home.dart';

abstract interface class PolylineDataSource {
  Future<List<LatLng>> getPolylinePoints({
    required LatLng origin,
    required LatLng destination,
    String? apiKey,
  });
  Future<Polyline> createPolyline({
    required String polylineId,
    required List<LatLng> points,
    Color? color,
    double? width,
  });
  Future<double> calculateDistance({
    required LatLng start,
    required LatLng end,
  });
}

class PolylineDataSourceImpl implements PolylineDataSource {
  ///TODO: Replace with your Google Maps API key
  final PolylinePoints _polylinePoints = PolylinePoints(
    apiKey: "AIzaSyCU9bEcRiC5X_5JeNX3khU6GcsCoFFGTHw",
  );

  @override
  Future<List<LatLng>> getPolylinePoints({
    required LatLng origin,
    required LatLng destination,
    String? apiKey,
  }) async {
    try {
      // Use Google Directions API with PolylineRequest
      final result = await _polylinePoints.getRouteBetweenCoordinates(
        request: PolylineRequest(
          origin: PointLatLng(origin.latitude, origin.longitude),
          destination: PointLatLng(destination.latitude, destination.longitude),
          mode: TravelMode.driving,
        ),
      );

      if (result.points.isNotEmpty) {
        return result.points
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();
      } else {
        // Fallback to direct line if route calculation fails
        return [origin, destination];
      }
    } catch (e) {
      // Return straight line as fallback
      return [origin, destination];
    }
  }

  @override
  Future<Polyline> createPolyline({
    required String polylineId,
    required List<LatLng> points,
    Color? color,
    double? width,
  }) async {
    return Polyline(
      polylineId: PolylineId(polylineId),
      points: points,
      color: color ?? Colors.blue,
      width: width?.toInt() ?? 5,
    );
  }

  @override
  Future<double> calculateDistance({
    required LatLng start,
    required LatLng end,
  }) async {
    // Calculate distance in meters using Geolocator
    return Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    );
  }
}
