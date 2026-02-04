// part of 'google_maps_feature.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';

class StampPlaceModel {
  final String id;
  final String name;

  final double latitude;
  final double longitude;

  final bool isPremium;
  final bool isStamped;
  final bool isGold;
  final bool isFestival;

  const StampPlaceModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.isPremium = false,
    this.isStamped = false,
    this.isGold = false,
    this.isFestival = false,
  });

  /// 🔹 Convenience getter
  LatLng get latLng => LatLng(latitude, longitude);

  /// 🔹 CopyWith (مهم جدًا مع BLoC)
  StampPlaceModel copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    bool? isPremium,
    bool? isStamped,
    bool? isGold,
    bool? isFestival,
  }) {
    return StampPlaceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isPremium: isPremium ?? this.isPremium,
      isStamped: isStamped ?? this.isStamped,
      isGold: isGold ?? this.isGold,
      isFestival: isFestival ?? this.isFestival,
    );
  }
}
