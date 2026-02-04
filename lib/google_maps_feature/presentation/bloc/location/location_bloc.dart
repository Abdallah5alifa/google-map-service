part of '../../../home.dart';

class LocationBloc extends Bloc<LocationEvent, LocationState> {
  final LocationDataSource _dataSource;
  StreamSubscription<Position>? _locationSubscription;

  LocationBloc(this._dataSource) : super(const LocationState()) {
    on<GetCurrentLocationEvent>(_onGetCurrentLocation);
    on<StartLocationTrackingEvent>(_onStartLocationTracking);
    on<StopLocationTrackingEvent>(_onStopLocationTracking);
    on<UpdateLocationEvent>(_onUpdateLocation);
  }

  Future<void> _onGetCurrentLocation(
    GetCurrentLocationEvent event,
    Emitter<LocationState> emit,
  ) async {
    debugPrint('🌍 LocationBloc: Started Get Current Location');
    emit(state.copyWith(status: Status.loading));

    try {
      debugPrint('🌍 LocationBloc: Calling getCurrentLocation from datasource');
      final position = await _dataSource.getCurrentLocation();
      debugPrint(
        '🌍 LocationBloc: Got position: ${position.latitude}, ${position.longitude}',
      );
      emit(
        state.copyWith(
          status: Status.success,
          currentLocation: position,
          errorMessage: null,
        ),
      );
    } catch (e) {
      debugPrint('🌍 LocationBloc: Error getting current location: $e');
      // Try to get last known location as fallback
      try {
        debugPrint('🌍 LocationBloc: Trying last known location as fallback');
        final lastKnownPosition = await _dataSource.getLastKnownLocation();
        if (lastKnownPosition != null) {
          debugPrint(
            '🌍 LocationBloc: Using last known position: ${lastKnownPosition.latitude}, ${lastKnownPosition.longitude}',
          );
          emit(
            state.copyWith(
              status: Status.success,
              currentLocation: lastKnownPosition,
              errorMessage: 'Using last known location',
            ),
          );
        } else {
          debugPrint('🌍 LocationBloc: No last known location available');
          emit(
            state.copyWith(status: Status.failure, errorMessage: e.toString()),
          );
        }
      } catch (fallbackError) {
        debugPrint('🌍 LocationBloc: Fallback also failed: $fallbackError');
        emit(
          state.copyWith(status: Status.failure, errorMessage: e.toString()),
        );
      }
    }
  }

  Future<void> _onStartLocationTracking(
    StartLocationTrackingEvent event,
    Emitter<LocationState> emit,
  ) async {
    emit(state.copyWith(status: Status.loading));

    try {
      // Check permission first
      final hasPermission = await _dataSource.checkAndRequestPermission();

      if (!hasPermission) {
        emit(
          state.copyWith(
            status: Status.failure,
            errorMessage:
                'Location permission denied. Please enable location access in settings.',
          ),
        );
        return;
      }

      // Cancel any existing subscription
      await _locationSubscription?.cancel();

      // Start listening to location updates
      _locationSubscription = _dataSource.getLocationStream().listen(
        (position) {
          add(UpdateLocationEvent(position));
        },
        onError: (error) {
          emit(
            state.copyWith(
              status: Status.failure,
              errorMessage: error.toString(),
              isTracking: false,
            ),
          );
        },
      );

      emit(state.copyWith(isTracking: true, status: Status.success));
    } catch (e) {
      emit(
        state.copyWith(
          status: Status.failure,
          errorMessage: e.toString(),
          isTracking: false,
        ),
      );
    }
  }

  Future<void> _onStopLocationTracking(
    StopLocationTrackingEvent event,
    Emitter<LocationState> emit,
  ) async {
    await _locationSubscription?.cancel();
    _locationSubscription = null;
    emit(state.copyWith(isTracking: false));
  }

  void _onUpdateLocation(
    UpdateLocationEvent event,
    Emitter<LocationState> emit,
  ) {
    emit(
      state.copyWith(currentLocation: event.position, status: Status.success),
    );
  }

  @override
  Future<void> close() {
    _locationSubscription?.cancel();
    return super.close();
  }
}
