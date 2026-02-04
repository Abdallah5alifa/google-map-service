part of '../../../home.dart';

class MarkerState extends Equatable {
  final Status status;
  final Set<Marker> markers;
  final Map<String, StampPlaceModel> places;
  final StampPlaceModel? selectedPlace;
  final String? errorMessage;
  final LatLng? cameraPosition;
  final double zoomLevel;

  final List<StampPlaceModel> placesList;

  const MarkerState({
    this.status = Status.initial,
    this.markers = const {},
    this.places = const {},
    this.placesList = const [],
    this.selectedPlace,
    this.errorMessage,
    this.cameraPosition,
    this.zoomLevel = 14.0,
  });

  MarkerState copyWith({
    Status? status,
    Set<Marker>? markers,
    Map<String, StampPlaceModel>? places,
    List<StampPlaceModel>? placesList,
    StampPlaceModel? selectedPlace,
    String? errorMessage,
    LatLng? cameraPosition,
    double? zoomLevel,
    bool clearSelection = false,
    bool clearCameraPosition = false,
  }) {
    return MarkerState(
      status: status ?? this.status,
      markers: markers ?? this.markers,
      places: places ?? this.places,
      placesList: placesList ?? this.placesList,
      selectedPlace: clearSelection
          ? null
          : (selectedPlace ?? this.selectedPlace),
      errorMessage: errorMessage ?? this.errorMessage,
      cameraPosition: clearCameraPosition
          ? null
          : (cameraPosition ?? this.cameraPosition),
      zoomLevel: zoomLevel ?? this.zoomLevel,
    );
  }

  @override
  List<Object?> get props => [
    status,
    markers,
    places,
    placesList,
    selectedPlace,
    errorMessage,
    cameraPosition,
    zoomLevel,
  ];
}
