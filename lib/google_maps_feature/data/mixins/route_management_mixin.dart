part of '../../home.dart';

mixin RouteManagementMixin<T extends StatefulWidget> on State<T> {
  PolylineBloc get polylineBloc;

  void drawRoute({
    required String routeId,
    required LatLng origin,
    required LatLng destination,
    Color? color,
  }) {
    polylineBloc.add(
      DrawRouteEvent(
        polylineId: routeId,
        origin: origin,
        destination: destination,
        color: color,
      ),
    );
  }

  void removeRoute(String routeId) {
    polylineBloc.add(RemovePolylineEvent(routeId));
  }

  void clearRoutes() {
    polylineBloc.add(const ClearRoutesEvent());
  }

  Set<Polyline> get polylines => polylineBloc.state.polylines;
  String? get routeError => polylineBloc.state.errorMessage;
}
