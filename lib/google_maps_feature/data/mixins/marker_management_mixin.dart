part of '../../home.dart';

mixin MarkerManagementMixin<T extends StatefulWidget> on State<T> {
  MarkerBloc get markerBloc;

  void addMarker({
    required String markerId,
    required LatLng position,
    String? title,
    String? snippet,
  }) {
    markerBloc.add(
      AddMarkerEvent(
        markerId: markerId,
        position: position,
        title: title,
        snippet: snippet,
      ),
    );
  }

  void removeMarker(String markerId) {
    markerBloc.add(RemoveMarkerEvent(markerId));
  }

  void updateMarker(String markerId, LatLng newPosition) {
    markerBloc.add(UpdateMarkerEvent(markerId, newPosition));
  }

  void addPlaceMarker({
    required StampPlaceModel place,
    BitmapDescriptor? icon,
  }) {
    markerBloc.add(AddPlaceMarkerEvent(place: place, icon: icon));
  }

  void onMarkerTap(String placeId) {
    markerBloc.add(MarkerTappedEvent(placeId));
  }

  void clearMarkers() {
    markerBloc.add(const ClearMarkersEvent());
  }

  void clearSelection() {
    markerBloc.add(const ClearSelectionEvent());
  }

  Set<Marker> get markers => markerBloc.state.markers;
  Map<String, StampPlaceModel> get places => markerBloc.state.places;
  StampPlaceModel? get selectedPlace => markerBloc.state.selectedPlace;
  String? get markerError => markerBloc.state.errorMessage;
  double get currentZoomLevel => markerBloc.state.zoomLevel;
}
