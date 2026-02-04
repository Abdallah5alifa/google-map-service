part of '../../../home.dart';

class PolylineBloc extends Bloc<PolylineEvent, PolylineState> {
  final PolylineDataSource _dataSource;

  PolylineBloc(this._dataSource) : super(const PolylineState()) {
    on<DrawRouteEvent>(_onDrawRoute);
    on<RemovePolylineEvent>(_onRemovePolyline);
    on<ClearRoutesEvent>(_onClearRoutes);
  }

  Future<void> _onDrawRoute(
    DrawRouteEvent event,
    Emitter<PolylineState> emit,
  ) async {
    emit(state.copyWith(status: Status.loading));

    try {
      final points = await _dataSource.getPolylinePoints(
        origin: event.origin,
        destination: event.destination,
      );

      final polyline = await _dataSource.createPolyline(
        polylineId: event.polylineId,
        points: points,
        color: event.color,
      );

      final updatedPolylines = Set<Polyline>.from(state.polylines)
        ..add(polyline);

      emit(
        state.copyWith(
          status: Status.success,
          polylines: updatedPolylines,
          errorMessage: null,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: Status.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _onRemovePolyline(
    RemovePolylineEvent event,
    Emitter<PolylineState> emit,
  ) async {
    final updatedPolylines = Set<Polyline>.from(
      state.polylines,
    )..removeWhere((polyline) => polyline.polylineId.value == event.polylineId);

    emit(state.copyWith(polylines: updatedPolylines, status: Status.success));
  }

  void _onClearRoutes(ClearRoutesEvent event, Emitter<PolylineState> emit) {
    emit(state.copyWith(polylines: const {}, status: Status.success));
  }
}
