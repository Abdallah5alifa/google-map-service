part of '../../../home.dart';

class LocationState extends Equatable {
  final Status status;
  final Position? currentLocation;
  final bool isTracking;
  final String? errorMessage;

  const LocationState({
    this.status = Status.initial,
    this.currentLocation,
    this.isTracking = false,
    this.errorMessage,
  });

  LocationState copyWith({
    Status? status,
    Position? currentLocation,
    bool? isTracking,
    String? errorMessage,
  }) {
    return LocationState(
      status: status ?? this.status,
      currentLocation: currentLocation ?? this.currentLocation,
      isTracking: isTracking ?? this.isTracking,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    currentLocation,
    isTracking,
    errorMessage,
  ];
}
