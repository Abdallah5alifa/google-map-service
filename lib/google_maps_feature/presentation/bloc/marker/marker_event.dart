part of '../../../home.dart';

abstract interface class MarkerEvent extends Equatable {
  const MarkerEvent();

  @override
  List<Object?> get props => [];
}

class AddMarkerEvent extends MarkerEvent {
  final String markerId;
  final LatLng position;
  final String? title;
  final String? snippet;

  const AddMarkerEvent({
    required this.markerId,
    required this.position,
    this.title,
    this.snippet,
  });

  @override
  List<Object?> get props => [markerId, position, title, snippet];
}

class RemoveMarkerEvent extends MarkerEvent {
  final String markerId;

  const RemoveMarkerEvent(this.markerId);

  @override
  List<Object?> get props => [markerId];
}

class UpdateMarkerEvent extends MarkerEvent {
  final String markerId;
  final LatLng newPosition;

  const UpdateMarkerEvent(this.markerId, this.newPosition);

  @override
  List<Object?> get props => [markerId, newPosition];
}

class ClearMarkersEvent extends MarkerEvent {
  const ClearMarkersEvent();
}

class AddPlaceMarkerEvent extends MarkerEvent {
  final StampPlaceModel place;
  final BitmapDescriptor? icon;

  const AddPlaceMarkerEvent({required this.place, this.icon});

  @override
  List<Object?> get props => [place, icon];
}

class MarkerTappedEvent extends MarkerEvent {
  final String placeId;

  const MarkerTappedEvent(this.placeId);

  @override
  List<Object?> get props => [placeId];
}

class AnimateCameraEvent extends MarkerEvent {
  final double latitude;
  final double longitude;

  const AnimateCameraEvent({required this.latitude, required this.longitude});

  @override
  List<Object?> get props => [latitude, longitude];
}

class UpdateZoomLevelEvent extends MarkerEvent {
  final double zoomLevel;

  const UpdateZoomLevelEvent(this.zoomLevel);

  @override
  List<Object?> get props => [zoomLevel];
}

class ClearSelectionEvent extends MarkerEvent {
  const ClearSelectionEvent();
}

class UpdatePlacesEvent extends MarkerEvent {
  final List<StampPlaceModel> places;

  const UpdatePlacesEvent(this.places);

  @override
  List<Object?> get props => [places];
}

class ClearCameraPositionEvent extends MarkerEvent {
  const ClearCameraPositionEvent();
}

class UpdateClusteredMarkersEvent extends MarkerEvent {
  final Set<Marker> markers;

  const UpdateClusteredMarkersEvent(this.markers);

  @override
  List<Object?> get props => [markers];
}
