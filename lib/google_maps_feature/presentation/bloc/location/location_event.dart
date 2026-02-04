part of '../../../home.dart';

abstract interface class LocationEvent extends Equatable {
  const LocationEvent();

  @override
  List<Object?> get props => [];
}

class GetCurrentLocationEvent extends LocationEvent {
  const GetCurrentLocationEvent();
}

class StartLocationTrackingEvent extends LocationEvent {
  const StartLocationTrackingEvent();
}

class StopLocationTrackingEvent extends LocationEvent {
  const StopLocationTrackingEvent();
}

class UpdateLocationEvent extends LocationEvent {
  final Position position;

  const UpdateLocationEvent(this.position);

  @override
  List<Object?> get props => [position];
}
