part of '../../../home.dart';

class PolylineState extends Equatable {
  final Status status;
  final Set<Polyline> polylines;
  final String? errorMessage;

  const PolylineState({
    this.status = Status.initial,
    this.polylines = const {},
    this.errorMessage,
  });

  PolylineState copyWith({
    Status? status,
    Set<Polyline>? polylines,
    String? errorMessage,
  }) {
    return PolylineState(
      status: status ?? this.status,
      polylines: polylines ?? this.polylines,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, polylines, errorMessage];
}
