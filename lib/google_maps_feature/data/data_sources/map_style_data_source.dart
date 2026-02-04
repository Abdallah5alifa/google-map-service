part of '../../home.dart';


abstract interface class MapStyleDataSource {
  String? get mapStyle;
  Future<void> loadStyle();
}

class MapStyleDataSourceImpl implements MapStyleDataSource {
  String? _mapStyle;

  @override
  String? get mapStyle => _mapStyle;

  @override
  Future<void> loadStyle() async {
    try {
      _mapStyle = await rootBundle.loadString('Assets.jsonMapStyle');
    } catch (e) {
      debugPrint('❌ MapStyleDataSource: Error loading map style: $e');
    }
  }
}
