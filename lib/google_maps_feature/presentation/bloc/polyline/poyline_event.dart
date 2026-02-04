part of '../../../home.dart';

abstract interface class PolylineEvent extends Equatable {
  const PolylineEvent();

  @override
  List<Object?> get props => [];
}

class DrawRouteEvent extends PolylineEvent {
  final String polylineId;
  final LatLng origin;
  final LatLng destination;
  final Color? color;

  const DrawRouteEvent({
    required this.polylineId,
    required this.origin,
    required this.destination,
    this.color,
  });

  @override
  List<Object?> get props => [polylineId, origin, destination, color];
}

class RemovePolylineEvent extends PolylineEvent {
  final String polylineId;

  const RemovePolylineEvent(this.polylineId);

  @override
  List<Object?> get props => [polylineId];
}

class ClearRoutesEvent extends PolylineEvent {
  const ClearRoutesEvent();
}
