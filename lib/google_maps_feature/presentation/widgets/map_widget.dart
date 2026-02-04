part of '../../home.dart';

class MapWidget extends StatefulWidget {
  const MapWidget({super.key});

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> with MarkerManagementMixin {
  GoogleMapController? _mapController;
  // GoogleMapController? _mapController;

  Position? _lastKnownPosition;
  Position? _initialLastKnownLocation;
  Timer? _zoomDebounceTimer;
  Timer? _cameraIdleDebounceTimer;
  double? _lastEmittedZoom;

  @override
  MarkerBloc get markerBloc => getIt<MarkerBloc>();

  late CameraPosition _initialCameraPosition;

  @override
  void initState() {
    super.initState();
    _initInitialCameraPosition();
    _loadLastKnownLocation();
  }

  void _initInitialCameraPosition() {
    _initialCameraPosition = const CameraPosition(
      target: LatLng(30.0444, 31.2357), // Default Cairo
      zoom: MapConstants.defaultZoom,
    );
  }


  void _updateMarkers(Set<Marker> markers) {
    // loggerInfo('Updating markers: ${markers.length}');
    markerBloc.add(UpdateClusteredMarkersEvent(markers));
  }

  Future<Marker> _markerBuilder(dynamic cluster) async {
    final cm.Cluster<StampPlaceModel> c = cluster;
    /*
    loggerInfo(
      'Building marker for cluster: ${c.getId()}, items: ${c.items.length}',
    );
    */
    if (c.isMultiple) {
      return Marker(
        markerId: MarkerId(c.getId()),
        position: c.location,
        onTap: () async {
          if (c.items.length > 1) {
            double minLat = 90.0;
            double maxLat = -90.0;
            double minLng = 180.0;
            double maxLng = -180.0;

            for (final item in c.items) {
              if (item.latitude < minLat) minLat = item.latitude;
              if (item.latitude > maxLat) maxLat = item.latitude;
              if (item.longitude < minLng) minLng = item.longitude;
              if (item.longitude > maxLng) maxLng = item.longitude;
            }

            final bounds = LatLngBounds(
              southwest: LatLng(minLat, minLng),
              northeast: LatLng(maxLat, maxLng),
            );

            _mapController?.animateCamera(
              CameraUpdate.newLatLngBounds(bounds, 50.0),
            );
          } else {
            final double? currentZoom = await _mapController?.getZoomLevel();
            if (currentZoom != null) {
              _mapController?.animateCamera(
                CameraUpdate.newLatLngZoom(c.location, currentZoom + 2.0),
              );
            }
          }
        },
        icon: await _getClusterIcon(c.count),
      );
    }

    final place = c.items.first;
    final markerBloc = getIt<MarkerBloc>();
    final markerState = markerBloc.state;
    final hasCrown = place.isPremium || place.isGold;

    // Calculate size based on current zoom
    final zoomLevel = _lastEmittedZoom ?? 14.0;

    // We can't easily call _calculateMarkerSize from bloc here as it's private
    // but we can use the logic or make it public. for now let's use the bloc's latest state logic
    // if we need to be precise.

    final markerSize = _getMarkerSize(zoomLevel);
    final anchor = getIt<MarkerDataSource>().calculateAnchor(
      size: markerSize.size,
      showAsDot: markerSize.showAsDot,
      hasCrown: hasCrown,
    );

    final icon = await getIt<MarkerDataSource>().createCustomMarkerIcon(
      color: place.isStamped
          ? HexColor.succesColor
          : place.isPremium
          ? AppColors.purpleAccent
          : HexColor.errorColor,
      zoomLevel: zoomLevel,
      isPremium: place.isPremium,
      isSelected: markerState.selectedPlace?.id == place.id,
      isGold: place.isGold,
      isStamped: place.isStamped,
    );

    return Marker(
      markerId: MarkerId(place.id),
      position: c.location,
      icon: icon,
      anchor: anchor,
      onTap: () {
        markerBloc.add(MarkerTappedEvent(place.id));
      },
    );
  }

  ({double size, bool showAsDot}) _getMarkerSize(double zoomLevel) {
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

  Future<BitmapDescriptor> _getClusterIcon(int count) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = AppColors.purpleAccent;
    final Paint shadowPaint = Paint()
      ..color = Colors.black26
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    const double size = 120.0;

    // Outer white glow/border
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2.1,
      shadowPaint,
    );

    // Main background circle
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2.3,
      Paint()..color = Colors.white,
    );

    // Inner filled circle
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2.6, paint);

    final TextPainter painter = TextPainter(
      textDirection: ui.TextDirection.ltr,
    );
    painter.text = TextSpan(
      text: count.toString(),
      style: const TextStyle(
        fontSize: size / 3,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
    painter.layout();
    painter.paint(
      canvas,
      Offset(size / 2 - painter.width / 2, size / 2 - painter.height / 2),
    );

    final ui.Image image = await pictureRecorder.endRecording().toImage(
      size.toInt(),
      size.toInt(),
    );
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  Future<void> _loadLastKnownLocation() async {
    try {
      final cachedLocation = getIt<ILocationCache>().getLastLocation();
      if (cachedLocation != null) {
        _initialLastKnownLocation = Position(
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
        _initialCameraPosition = CameraPosition(
          target: LatLng(
            _initialLastKnownLocation!.latitude,
            _initialLastKnownLocation!.longitude,
          ),
          zoom: MapConstants.defaultZoom,
        );
        setState(() {});
      }
    } catch (e) {
      // Ignore error, will use dummy location
    }
  }

  void _animateCameraToPosition(Position position) {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: MapConstants.locationZoom,
          ),
        ),
      );
    }
  }

  bool _isFirstFetch = true;
  bool _isFetching = false;
  double? _lastFetchedZoom;
  LatLng? _lastFetchedCenter;
  double? _lastFetchedAreaKm2;

  double _distanceKm(LatLng a, LatLng b) {
    const double r = 6371.0;
    final double dLat = (b.latitude - a.latitude) * (math.pi / 180.0);
    final double dLng = (b.longitude - a.longitude) * (math.pi / 180.0);
    final double lat1 = a.latitude * (math.pi / 180.0);
    final double lat2 = b.latitude * (math.pi / 180.0);

    final double h =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final double c = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
    return r * c;
  }

  LatLng _boundsCenter(LatLngBounds bounds) {
    return LatLng(
      (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
      (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
    );
  }

  double _boundsAreaKm2(LatLngBounds bounds) {
    final center = _boundsCenter(bounds);
    final double heightKm = _distanceKm(
      LatLng(bounds.northeast.latitude, center.longitude),
      LatLng(bounds.southwest.latitude, center.longitude),
    );
    final double widthKm = _distanceKm(
      LatLng(center.latitude, bounds.northeast.longitude),
      LatLng(center.latitude, bounds.southwest.longitude),
    );
    return (heightKm * widthKm).abs();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _zoomDebounceTimer?.cancel();
    _cameraIdleDebounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<LocationBloc, LocationState>(
          listener: (context, locationState) {
            if (locationState.currentLocation != null &&
                _lastKnownPosition != locationState.currentLocation) {
              _lastKnownPosition = locationState.currentLocation;
              _animateCameraToPosition(locationState.currentLocation!);
            }
          },
        ),
        BlocListener<MarkerBloc, MarkerState>(
          listenWhen: (previous, current) =>
              !listEquals(previous.placesList, current.placesList) ||
              previous.selectedPlace != current.selectedPlace ||
              previous.zoomLevel != current.zoomLevel ||
              previous.cameraPosition != current.cameraPosition,
          listener: (context, markerState) {
            // Add a tiny jitter to markers with identical coordinates to prevent hiding
            final jitteredPlaces = markerState.placesList.map((p) {
              final sameLocationCount = markerState.placesList
                  .where(
                    (other) =>
                        other.id != p.id &&
                        other.latitude == p.latitude &&
                        other.longitude == p.longitude,
                  )
                  .length;

              if (sameLocationCount > 0) {
                // Add a very tiny offset (approx 1-2 meters)
                final index = markerState.placesList.indexOf(p);
                return p.copyWith(
                  latitude: p.latitude + (math.sin(index) * 0.00001),
                  longitude: p.longitude + (math.cos(index) * 0.00001),
                );
              }
              return p;
            }).toList();

            _clusterManager.setItems(jitteredPlaces);
            _clusterManager.updateMap();

            // Animate camera when cameraPosition is set from search
            if (markerState.cameraPosition != null) {
              if (_mapController != null) {
                _mapController!.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: markerState.cameraPosition!,
                      zoom: MapConstants.searchZoom,
                    ),
                  ),
                );
                // Clear the camera position after animating
                markerBloc.add(const ClearCameraPositionEvent());
              }
            }
          },
        ),
        BlocListener<NearestStampsBloc, BaseState<StampPlaceModel>>(
          listener: (context, state) {
            if (state.isFailure) {
              context.showTopSnackBar(
                message: state.errorMessage ?? "",
                type: SnackBarType.error,
              );
            }
          },
        ),
      ],
      child: Container(
        color: const Color(0xFFE5E3DF), // Neutral background
        child: Stack(
          children: [
            RepaintBoundary(
              child: BlocBuilder<MarkerBloc, MarkerState>(
                buildWhen: (previous, current) =>
                    previous.markers != current.markers,
                builder: (context, markerState) {
                  return BlocBuilder<PolylineBloc, PolylineState>(
                    buildWhen: (previous, current) =>
                        previous.polylines != current.polylines,
                    builder: (context, polylineState) {
                      return GoogleMap(
                        key: const ValueKey('main_google_map'),
                        initialCameraPosition: _initialCameraPosition,
                        // style: getIt<MapStyleDataSource>().mapStyle,
                        onMapCreated: (GoogleMapController controller) {
                          _mapController = controller;
                          _clusterManager.setMapId(controller.mapId);
                          // Move to current location once if available on start
                          final locBloc = context.read<LocationBloc>();
                          if (locBloc.state.currentLocation != null) {
                            _animateCameraToPosition(
                              locBloc.state.currentLocation!,
                            );
                          }
                        },
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                        compassEnabled: false,
                        mapToolbarEnabled: false,
                        markers: markerState.markers,
                        polylines: polylineState.polylines,
                        zoomGesturesEnabled: true,
                        scrollGesturesEnabled: true,
                        tiltGesturesEnabled: true,
                        rotateGesturesEnabled: true,
                        gestureRecognizers:
                            <Factory<OneSequenceGestureRecognizer>>{
                              Factory<OneSequenceGestureRecognizer>(
                                () => EagerGestureRecognizer(),
                              ),
                            },
                        onCameraMove: (position) {
                          _clusterManager.onCameraMove(position);
                          _zoomDebounceTimer?.cancel();
                          _zoomDebounceTimer = Timer(
                            const Duration(milliseconds: 300),
                            () {
                              if (_lastEmittedZoom == null ||
                                  (position.zoom - _lastEmittedZoom!).abs() >=
                                      0.3) {
                                _lastEmittedZoom = position.zoom;
                                getIt<MarkerBloc>().add(
                                  UpdateZoomLevelEvent(position.zoom),
                                );
                              }
                            },
                          );
                        },
                        onCameraIdle: () {
                          _clusterManager.updateMap();
                          _cameraIdleDebounceTimer?.cancel();
                          _cameraIdleDebounceTimer = Timer(
                            Duration(
                              milliseconds: MapConstants.fetchDebounceMs,
                            ),
                            () async {
                              if (!mounted ||
                                  _mapController == null ||
                                  _isFetching)
                                return;

                              final bounds = await _mapController!
                                  .getVisibleRegion();
                              final zoom = await _mapController!.getZoomLevel();
                              if (!mounted) return;

                              final center = _boundsCenter(bounds);
                              final areaKm2 = _boundsAreaKm2(bounds);
                              final isFirst = _isFirstFetch;
                              if (isFirst) _isFirstFetch = false;

                              bool zoomChanged =
                                  isFirst ||
                                  (_lastFetchedZoom != null &&
                                      (_lastFetchedZoom! - zoom).abs() >=
                                          MapConstants.minZoomDelta);

                              bool centerMoved =
                                  !zoomChanged &&
                                  _lastFetchedCenter != null &&
                                  _distanceKm(_lastFetchedCenter!, center) >=
                                      MapConstants.minMoveDistanceKm;

                              bool areaChanged =
                                  !zoomChanged &&
                                  !centerMoved &&
                                  _lastFetchedAreaKm2 != null &&
                                  _lastFetchedAreaKm2! > 0 &&
                                  (areaKm2 / _lastFetchedAreaKm2!) >=
                                      MapConstants.minAreaChangeRatio;

                              if (!zoomChanged && !centerMoved && !areaChanged)
                                return;

                              _isFetching = true;
                              _lastFetchedZoom = zoom;
                              _lastFetchedCenter = center;
                              _lastFetchedAreaKm2 = areaKm2;

                              try {
                                final n = bounds.northeast.latitude;
                                final s = bounds.southwest.latitude;
                                final e = bounds.northeast.longitude;
                                final w = bounds.southwest.longitude;
                                final latD = (n - s) * 0.1;
                                final lngD = (e - w) * 0.1;

                                if (mounted) {
                                  getIt<NearestStampsBloc>().add(
                                    GetNearestStampsEvent(
                                      north: n + latD,
                                      south: s - latD,
                                      east: e + lngD,
                                      west: w - lngD,
                                      zoom: zoom,
                                    ),
                                  );
                                }
                              } finally {
                                _isFetching = false;
                              }
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            // Floating UI elements
            _getMyCurrentLocation(context),
          ],
        ),
      ),
    );
  }

  Positioned _getMyCurrentLocation(BuildContext context) {
    return Positioned.directional(
      textDirection: Directionality.of(context),
      bottom: 200.h,
      end: 20.w,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            final locBloc = getIt<LocationBloc>();
            final state = locBloc.state;
            if (state.currentLocation != null) {
              _animateCameraToPosition(state.currentLocation!);
            }
            locBloc.add(const GetCurrentLocationEvent());
          },
          child: Container(
            width: 100.w,
            height: 100.w,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.my_location,
              color: HexColor.greyColor,
              size: 50.w,
            ),
          ),
        ),
      ),
    );
  }
// }

// part of '../../home.dart';

// class MapWidget extends StatefulWidget {
//   const MapWidget({super.key});

//   @override
//   State<MapWidget> createState() => _MapWidgetState();
// }

// class _MapWidgetState extends State<MapWidget>
//     with SingleTickerProviderStateMixin {
//   GoogleMapController? _mapController;

//   static const CameraPosition _defaultCamera = CameraPosition(
//     target: LatLng(30.0444, 31.2357),
//     zoom: 13.5,
//   );

//   // --- Search UI ---
//   final _searchCtrl = TextEditingController();
//   final _focus = FocusNode();
//   final ValueNotifier<List<_PlaceItem>> _suggestions = ValueNotifier([]);

//   // --- Selected place for bottom sheet ---
//   final ValueNotifier<_PlaceItem?> _selected = ValueNotifier(null);

//   // --- Simple style toggle ---
//   bool _darkMap = false;

//   // --- Debounce ---
//   Timer? _debounce;

//   // ✅ بيانات Search (تقدر تربطها بالماركرز بتاعتك بدل الليست دي)
//   // الفكرة: تخليها "مصادر بحث" = (markers, saved places, recent...)
//   late final List<_PlaceItem> _places = [
//     _PlaceItem(
//       id: 'cairo_tower',
//       title: 'Cairo Tower',
//       subtitle: 'Zamalek • Landmark',
//       position: const LatLng(30.0459, 31.2243),
//       icon: Icons.location_city,
//     ),
//     _PlaceItem(
//       id: 'tahrir',
//       title: 'Tahrir Square',
//       subtitle: 'Downtown • Square',
//       position: const LatLng(30.0444, 31.2357),
//       icon: Icons.place,
//     ),
//     _PlaceItem(
//       id: 'al_azhar',
//       title: 'Al-Azhar Park',
//       subtitle: 'Cairo • Park',
//       position: const LatLng(30.0400, 31.2622),
//       icon: Icons.park,
//     ),
//   ];

//   @override
//   void initState() {
//     super.initState();

//     _searchCtrl.addListener(_onSearchChanged);
//     _focus.addListener(() {
//       if (!_focus.hasFocus) {
//         // اقفل السجست عند فقدان التركيز
//         _suggestions.value = [];
//       } else {
//         _onSearchChanged();
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _debounce?.cancel();
//     _searchCtrl.dispose();
//     _focus.dispose();
//     _mapController?.dispose();
//     _suggestions.dispose();
//     _selected.dispose();
//     super.dispose();
//   }

//   void _onSearchChanged() {
//     _debounce?.cancel();
//     _debounce = Timer(const Duration(milliseconds: 180), () {
//       final q = _searchCtrl.text.trim().toLowerCase();
//       if (q.isEmpty || !_focus.hasFocus) {
//         _suggestions.value = [];
//         return;
//       }

//       final list =
//           _places
//               .where(
//                 (p) =>
//                     p.title.toLowerCase().contains(q) ||
//                     p.subtitle.toLowerCase().contains(q),
//               )
//               .take(6)
//               .toList();

//       _suggestions.value = list;
//     });
//   }

//   void _animateTo(LatLng target, {double zoom = 16}) {
//     final c = _mapController;
//     if (c == null) return;
//     c.animateCamera(
//       CameraUpdate.newCameraPosition(
//         CameraPosition(target: target, zoom: zoom, tilt: 35),
//       ),
//     );
//   }

//   void _moveToMyLocation(BuildContext context) {
//     context.read<LocationBloc>().add(const GetCurrentLocationEvent());
//   }

//   void _selectPlace(_PlaceItem p) {
//     _selected.value = p;
//     _suggestions.value = [];
//     _focus.unfocus();
//     _animateTo(p.position, zoom: 16.5);
//   }

//   // ✅ ستايلات جاهزة (خفيفة) — لو عندك MapStyleDataSource خليها ترجع النص بدل هنا
//   String get _darkStyle => '''
// [
//   {"elementType":"geometry","stylers":[{"color":"#1d2c4d"}]},
//   {"elementType":"labels.text.fill","stylers":[{"color":"#8ec3b9"}]},
//   {"elementType":"labels.text.stroke","stylers":[{"color":"#1a3646"}]},
//   {"featureType":"administrative.country","elementType":"geometry.stroke","stylers":[{"color":"#4b6878"}]},
//   {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#6f9ba5"}]},
//   {"featureType":"road","elementType":"geometry","stylers":[{"color":"#304a7d"}]},
//   {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#2c6675"}]},
//   {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0e1626"}]},
//   {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#4e6d70"}]}
// ]
// ''';

//   @override
//   Widget build(BuildContext context) {
//     final textDir = Directionality.of(context);

//     return MultiBlocListener(
//       listeners: [
//         BlocListener<LocationBloc, LocationState>(
//           listener: (context, state) {
//             final pos = state.currentLocation;
//             if (pos == null) return;
//             _animateTo(LatLng(pos.latitude, pos.longitude), zoom: 16.8);
//           },
//         ),
//       ],
//       child: Stack(
//         children: [
//           // =========================
//           // Google Map Layer
//           // =========================
//           BlocBuilder<MarkerBloc, MarkerState>(
//             buildWhen: (p, c) => p.markers != c.markers,
//             builder: (context, markerState) {
//               return BlocBuilder<PolylineBloc, PolylineState>(
//                 buildWhen: (p, c) => p.polylines != c.polylines,
//                 builder: (context, polyState) {
//                   return GoogleMap(
//                     key: const ValueKey('main_google_map'),
//                     initialCameraPosition: _defaultCamera,
//                     onMapCreated: (controller) async {
//                       _mapController = controller;
//                       if (_darkMap) {
//                         await controller.setMapStyle(_darkStyle);
//                       } else {
//                         await controller.setMapStyle(null);
//                       }
//                     },

//                     // UI controls
//                     myLocationEnabled: true,
//                     myLocationButtonEnabled: false,
//                     zoomControlsEnabled: false,
//                     compassEnabled: false,
//                     mapToolbarEnabled: false,

//                     // Data
//                     markers: markerState.markers,
//                     polylines: polyState.polylines,

//                     // Gestures
//                     zoomGesturesEnabled: true,
//                     scrollGesturesEnabled: true,
//                     tiltGesturesEnabled: true,
//                     rotateGesturesEnabled: true,

//                     // ✨ لو عندك ماركرز وعايز تضغط عليها وتفتح sheet:
//                     onTap: (_) => _selected.value = null,
//                     onLongPress: (latLng) {
//                       // انبهار بسيط: long press يعمل نقطة مؤقتة (اختياري)
//                       // تقدر تبعت event للـ MarkerBloc لو عندك events
//                     },

//                     gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
//                       Factory<OneSequenceGestureRecognizer>(
//                         () => EagerGestureRecognizer(),
//                       ),
//                     },
//                   );
//                 },
//               );
//             },
//           ),

//           // =========================
//           // Top Glass Search Bar
//           // =========================
//           Positioned.directional(
//             textDirection: textDir,
//             top: 14.h,
//             start: 14.w,
//             end: 14.w,
//             child: Column(
//               children: [
//                 _GlassSearchBar(
//                   controller: _searchCtrl,
//                   focusNode: _focus,
//                   hint: 'Search places…',
//                   onClear: () {
//                     _searchCtrl.clear();
//                     _suggestions.value = [];
//                     _selected.value = null;
//                   },
//                 ),

//                 ValueListenableBuilder<List<_PlaceItem>>(
//                   valueListenable: _suggestions,
//                   builder: (context, list, _) {
//                     if (list.isEmpty) return const SizedBox.shrink();
//                     return _GlassSuggestions(items: list, onTap: _selectPlace);
//                   },
//                 ),
//               ],
//             ),
//           ),

//           // =========================
//           // Right Floating Buttons
//           // =========================
//           Positioned.directional(
//             textDirection: textDir,
//             bottom: 170.h,
//             end: 14.w,
//             child: Column(
//               children: [
//                 _FabGlass(
//                   icon: Icons.my_location,
//                   onTap: () => _moveToMyLocation(context),
//                 ),
//                 const SizedBox(height: 10),
//                 _FabGlass(
//                   icon: _darkMap ? Icons.light_mode : Icons.dark_mode,
//                   onTap: () async {
//                     setState(() => _darkMap = !_darkMap);
//                     final c = _mapController;
//                     if (c == null) return;
//                     await c.setMapStyle(_darkMap ? _darkStyle : null);
//                   },
//                 ),
//                 const SizedBox(height: 10),
//                 _FabGlass(
//                   icon: Icons.add,
//                   onTap:
//                       () =>
//                           _mapController?.animateCamera(CameraUpdate.zoomIn()),
//                 ),
//                 const SizedBox(height: 10),
//                 _FabGlass(
//                   icon: Icons.remove,
//                   onTap:
//                       () =>
//                           _mapController?.animateCamera(CameraUpdate.zoomOut()),
//                 ),
//               ],
//             ),
//           ),

//           // =========================
//           // Bottom Sheet (Place Preview)
//           // =========================
//           ValueListenableBuilder<_PlaceItem?>(
//             valueListenable: _selected,
//             builder: (context, place, _) {
//               return AnimatedSlide(
//                 duration: const Duration(milliseconds: 220),
//                 curve: Curves.easeOut,
//                 offset: place == null ? const Offset(0, 1.1) : Offset.zero,
//                 child: AnimatedOpacity(
//                   duration: const Duration(milliseconds: 180),
//                   opacity: place == null ? 0 : 1,
//                   child:
//                       place == null
//                           ? const SizedBox.shrink()
//                           : _BottomPlaceCard(
//                             place: place,
//                             onGo: () => _animateTo(place.position, zoom: 17),
//                             onClose: () => _selected.value = null,
//                           ),
//                 ),
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }

// // =========================
// // Models + UI Components
// // =========================

// class _PlaceItem {
//   final String id;
//   final String title;
//   final String subtitle;
//   final LatLng position;
//   final IconData icon;

//   _PlaceItem({
//     required this.id,
//     required this.title,
//     required this.subtitle,
//     required this.position,
//     required this.icon,
//   });
// }

// class _GlassSearchBar extends StatelessWidget {
//   final TextEditingController controller;
//   final FocusNode focusNode;
//   final String hint;
//   final VoidCallback onClear;

//   const _GlassSearchBar({
//     required this.controller,
//     required this.focusNode,
//     required this.hint,
//     required this.onClear,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(18.r),
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
//         child: Container(
//           padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
//           decoration: BoxDecoration(
//             color: Colors.white.withOpacity(0.82),
//             borderRadius: BorderRadius.circular(18.r),
//             border: Border.all(color: Colors.white.withOpacity(0.55)),
//             boxShadow: const [
//               BoxShadow(
//                 color: Colors.black12,
//                 blurRadius: 16,
//                 offset: Offset(0, 6),
//               ),
//             ],
//           ),
//           child: Row(
//             children: [
//               Icon(Icons.search, color: Colors.black87, size: 22.sp),
//               SizedBox(width: 10.w),
//               Expanded(
//                 child: TextField(
//                   controller: controller,
//                   focusNode: focusNode,
//                   textInputAction: TextInputAction.search,
//                   decoration: InputDecoration(
//                     hintText: hint,
//                     border: InputBorder.none,
//                     isDense: true,
//                     hintStyle: TextStyle(
//                       color: Colors.black54,
//                       fontSize: 14.sp,
//                     ),
//                   ),
//                 ),
//               ),
//               ValueListenableBuilder<TextEditingValue>(
//                 valueListenable: controller,
//                 builder: (_, v, __) {
//                   if (v.text.isEmpty) return const SizedBox.shrink();
//                   return InkWell(
//                     borderRadius: BorderRadius.circular(99),
//                     onTap: onClear,
//                     child: Padding(
//                       padding: EdgeInsets.all(6.w),
//                       child: Icon(
//                         Icons.close,
//                         color: Colors.black54,
//                         size: 18.sp,
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _GlassSuggestions extends StatelessWidget {
//   final List<_PlaceItem> items;
//   final ValueChanged<_PlaceItem> onTap;

//   const _GlassSuggestions({required this.items, required this.onTap});

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: EdgeInsets.only(top: 10.h),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(18.r),
//         child: BackdropFilter(
//           filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
//           child: Container(
//             decoration: BoxDecoration(
//               color: Colors.white.withOpacity(0.85),
//               borderRadius: BorderRadius.circular(18.r),
//               border: Border.all(color: Colors.white.withOpacity(0.55)),
//               boxShadow: const [
//                 BoxShadow(
//                   color: Colors.black12,
//                   blurRadius: 16,
//                   offset: Offset(0, 8),
//                 ),
//               ],
//             ),
//             child: ListView.separated(
//               shrinkWrap: true,
//               padding: EdgeInsets.zero,
//               itemCount: items.length,
//               separatorBuilder:
//                   (_, __) => Divider(
//                     height: 1,
//                     color: Colors.black12.withOpacity(0.08),
//                   ),
//               itemBuilder: (context, i) {
//                 final p = items[i];
//                 return ListTile(
//                   dense: true,
//                   leading: CircleAvatar(
//                     backgroundColor: Colors.black.withOpacity(0.04),
//                     child: Icon(p.icon, color: Colors.black87),
//                   ),
//                   title: Text(
//                     p.title,
//                     style: TextStyle(
//                       fontSize: 14.sp,
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//                   subtitle: Text(
//                     p.subtitle,
//                     style: TextStyle(fontSize: 12.sp, color: Colors.black54),
//                   ),
//                   onTap: () => onTap(p),
//                 );
//               },
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _FabGlass extends StatelessWidget {
//   final IconData icon;
//   final VoidCallback onTap;

//   const _FabGlass({required this.icon, required this.onTap});

//   @override
//   Widget build(BuildContext context) {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(18.r),
//       child: Material(
//         color: Colors.white.withOpacity(0.92),
//         child: InkWell(
//           onTap: onTap,
//           child: Container(
//             width: 52.w,
//             height: 52.w,
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(18.r),
//               boxShadow: const [
//                 BoxShadow(
//                   color: Colors.black12,
//                   blurRadius: 16,
//                   offset: Offset(0, 8),
//                 ),
//               ],
//               border: Border.all(color: Colors.white.withOpacity(0.6)),
//             ),
//             child: Icon(icon, color: Colors.black87, size: 22.sp),
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _BottomPlaceCard extends StatelessWidget {
//   final _PlaceItem place;
//   final VoidCallback onGo;
//   final VoidCallback onClose;

//   const _BottomPlaceCard({
//     required this.place,
//     required this.onGo,
//     required this.onClose,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Positioned(
//       left: 14.w,
//       right: 14.w,
//       bottom: 14.h,
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(22.r),
//         child: BackdropFilter(
//           filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
//           child: Container(
//             padding: EdgeInsets.all(14.w),
//             decoration: BoxDecoration(
//               color: Colors.white.withOpacity(0.9),
//               borderRadius: BorderRadius.circular(22.r),
//               border: Border.all(color: Colors.white.withOpacity(0.6)),
//               boxShadow: const [
//                 BoxShadow(
//                   color: Colors.black12,
//                   blurRadius: 20,
//                   offset: Offset(0, 10),
//                 ),
//               ],
//             ),
//             child: Row(
//               children: [
//                 CircleAvatar(
//                   radius: 22.r,
//                   backgroundColor: Colors.black.withOpacity(0.05),
//                   child: Icon(place.icon, color: Colors.black87),
//                 ),
//                 SizedBox(width: 12.w),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         place.title,
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                         style: TextStyle(
//                           fontSize: 15.sp,
//                           fontWeight: FontWeight.w800,
//                         ),
//                       ),
//                       SizedBox(height: 3.h),
//                       Text(
//                         place.subtitle,
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                         style: TextStyle(
//                           fontSize: 12.sp,
//                           color: Colors.black54,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 SizedBox(width: 10.w),
//                 ElevatedButton.icon(
//                   onPressed: onGo,
//                   style: ElevatedButton.styleFrom(
//                     elevation: 0,
//                     backgroundColor: AppColors.primary,
//                     padding: EdgeInsets.symmetric(
//                       horizontal: 14.w,
//                       vertical: 10.h,
//                     ),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(14.r),
//                     ),
//                   ),
//                   icon: const Icon(Icons.near_me, color: Colors.white),
//                   label: Text(
//                     'Go',
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 13.sp,
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//                 ),
//                 SizedBox(width: 6.w),
//                 InkWell(
//                   onTap: onClose,
//                   borderRadius: BorderRadius.circular(999),
//                   child: Padding(
//                     padding: EdgeInsets.all(8.w),
//                     child: Icon(
//                       Icons.close,
//                       color: Colors.black54,
//                       size: 18.sp,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
