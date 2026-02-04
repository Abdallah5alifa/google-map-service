part of '../../../home.dart';

class MarkerBloc extends Bloc<MarkerEvent, MarkerState> {
  final MarkerDataSource _dataSource;

  MarkerBloc(this._dataSource) : super(const MarkerState()) {
    on<AddMarkerEvent>(_onAddMarker);
    on<RemoveMarkerEvent>(_onRemoveMarker);
    on<UpdateMarkerEvent>(_onUpdateMarker);
    on<ClearMarkersEvent>(_onClearMarkers);
    on<AddPlaceMarkerEvent>(_onAddPlaceMarker);
    on<MarkerTappedEvent>(_onMarkerTapped);
    on<AnimateCameraEvent>(_onAnimateCamera);
    on<UpdateZoomLevelEvent>(_onUpdateZoomLevel);
    on<ClearSelectionEvent>(_onClearSelection);
    on<UpdatePlacesEvent>(_onUpdatePlaces);
    on<UpdateClusteredMarkersEvent>(_onUpdateClusteredMarkers);
    on<ClearCameraPositionEvent>(_onClearCameraPosition);
  }

  // Helper method to calculate marker size and dot status
  ({double size, bool showAsDot}) _calculateMarkerSize(double zoomLevel) {
    double size;
    bool showAsDot = false;

    if (zoomLevel < 8) {
      size = 8;
      showAsDot = true;
    } else if (zoomLevel < 10) {
      size = 12 + (zoomLevel - 8) * 4;
      showAsDot = true;
    } else if (zoomLevel < 12) {
      size = 20 + (zoomLevel - 10) * 10;
      showAsDot = false;
    } else if (zoomLevel < 14) {
      size = 40 + (zoomLevel - 12) * 15;
      showAsDot = false;
    } else {
      size = 70 + (zoomLevel - 14) * 15;
      size = size.clamp(70, 100);
      showAsDot = false;
    }

    return (size: size, showAsDot: showAsDot);
  }

  Future<void> _onAddMarker(
    AddMarkerEvent event,
    Emitter<MarkerState> emit,
  ) async {
    emit(state.copyWith(status: Status.loading));

    try {
      final marker = await _dataSource.createMarker(
        markerId: event.markerId,
        position: event.position,
        title: event.title,
        snippet: event.snippet,
      );

      final updatedMarkers = Set<Marker>.from(state.markers)..add(marker);

      emit(
        state.copyWith(
          status: Status.success,
          markers: updatedMarkers,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: Status.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _onRemoveMarker(
    RemoveMarkerEvent event,
    Emitter<MarkerState> emit,
  ) async {
    final updatedMarkers = Set<Marker>.from(state.markers)
      ..removeWhere((marker) => marker.markerId.value == event.markerId);

    emit(state.copyWith(markers: updatedMarkers, status: Status.success));
  }

  Future<void> _onUpdateMarker(
    UpdateMarkerEvent event,
    Emitter<MarkerState> emit,
  ) async {
    try {
      final existingMarker = state.markers.firstWhere(
        (marker) => marker.markerId.value == event.markerId,
      );

      final updatedMarker = await _dataSource.updateMarkerPosition(
        marker: existingMarker,
        newPosition: event.newPosition,
      );

      final updatedMarkers = Set<Marker>.from(state.markers)
        ..removeWhere((marker) => marker.markerId.value == event.markerId)
        ..add(updatedMarker);

      emit(state.copyWith(markers: updatedMarkers, status: Status.success));
    } catch (e) {
      emit(state.copyWith(status: Status.failure, errorMessage: e.toString()));
    }
  }

  void _onClearMarkers(ClearMarkersEvent event, Emitter<MarkerState> emit) {
    emit(
      state.copyWith(
        markers: const {},
        places: const {},
        status: Status.success,
        clearSelection: true,
      ),
    );
  }

  Future<void> _onAddPlaceMarker(
    AddPlaceMarkerEvent event,
    Emitter<MarkerState> emit,
  ) async {
    emit(state.copyWith(status: Status.loading));
    final place = event.place;
    final hasCrown = place.isPremium || place.isGold;

    // Calculate size based on zoom level
    final markerSize = _calculateMarkerSize(state.zoomLevel);

    final anchor = _dataSource.calculateAnchor(
      size: markerSize.size,
      showAsDot: markerSize.showAsDot,
      hasCrown: hasCrown,
    );

    final icon = await _dataSource.createCustomMarkerIcon(
      color: place.isStamped
          ? HexColor.succesColor
          : place.isPremium
          ? AppColors.purpleAccent
          : HexColor.errorColor,
      zoomLevel: state.zoomLevel,
      isPremium: place.isPremium,
      isSelected: false,
      isGold: place.isGold,
      isStamped: place.isStamped,
      isFestival:
          false, // You can add logic for festival if available in place model
    );
    try {
      final marker = await _dataSource.createMarker(
        markerId: place.id,
        position: LatLng(place.latitude, place.longitude),
        title: place.name,
        snippet: place.isPremium ? 'Limited' : 'Stamp',
        icon: icon,
        anchor: anchor,
        onTap: () {
          add(MarkerTappedEvent(place.id));
        },
      );

      final updatedMarkers = Set<Marker>.from(state.markers)..add(marker);
      final updatedPlaces = Map<String, StampPlaceModel>.from(state.places)
        ..[place.id] = place;

      emit(
        state.copyWith(
          status: Status.success,
          markers: updatedMarkers,
          places: updatedPlaces,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: Status.failure, errorMessage: e.toString()));
    }
  }

  void _onMarkerTapped(
    MarkerTappedEvent event,
    Emitter<MarkerState> emit,
  ) async {
    final place = state.places[event.placeId];
    if (place != null) {
      emit(state.copyWith(selectedPlace: place));
    }
  }

  void _onAnimateCamera(AnimateCameraEvent event, Emitter<MarkerState> emit) {
    emit(
      state.copyWith(cameraPosition: LatLng(event.latitude, event.longitude)),
    );
  }

  Future<void> _onUpdateZoomLevel(
    UpdateZoomLevelEvent event,
    Emitter<MarkerState> emit,
  ) async {
    if ((state.zoomLevel - event.zoomLevel).abs() < 0.3) {
      return;
    }

    emit(state.copyWith(zoomLevel: event.zoomLevel, clearSelection: true));
  }

  void _onClearSelection(
    ClearSelectionEvent event,
    Emitter<MarkerState> emit,
  ) async {
    emit(state.copyWith(clearSelection: true));
  }

  void _onUpdatePlaces(UpdatePlacesEvent event, Emitter<MarkerState> emit) {
    final Map<String, StampPlaceModel> updatedPlaces =
        Map<String, StampPlaceModel>.from(state.places);

    for (var place in event.places) {
      updatedPlaces[place.id] = place;
    }

    emit(
      state.copyWith(
        placesList: updatedPlaces.values.toList(),
        places: updatedPlaces,
      ),
    );
  }

  void _onUpdateClusteredMarkers(
    UpdateClusteredMarkersEvent event,
    Emitter<MarkerState> emit,
  ) {
    emit(state.copyWith(markers: event.markers, status: Status.success));
  }

  void _onClearCameraPosition(
    ClearCameraPositionEvent event,
    Emitter<MarkerState> emit,
  ) {
    emit(state.copyWith(clearCameraPosition: true));
  }
}
