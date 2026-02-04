part of '../../home.dart';

mixin LocationManagementMixin<T extends StatefulWidget> on State<T> {
  LocationBloc get locationBloc;

  void getCurrentLocation() {
    debugPrint(
      '🌍 LocationManagementMixin: Dispatching GetCurrentLocationEvent',
    );
    locationBloc.add(const GetCurrentLocationEvent());
    debugPrint('🌍 LocationManagementMixin: Event dispatched');
  }

  void startTracking() {
    locationBloc.add(const StartLocationTrackingEvent());
  }

  void stopTracking() {
    locationBloc.add(const StopLocationTrackingEvent());
  }

  Position? get currentLocation => locationBloc.state.currentLocation;
  bool get isTracking => locationBloc.state.isTracking;
  String? get locationError => locationBloc.state.errorMessage;
}
