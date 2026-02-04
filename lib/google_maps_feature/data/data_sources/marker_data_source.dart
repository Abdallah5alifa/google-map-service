part of '../../home.dart';

abstract interface class MarkerDataSource {
  Future<Marker> createMarker({
    required String markerId,
    required LatLng position,
    String? title,
    String? snippet,
    BitmapDescriptor? icon,
    VoidCallback? onTap,
    Offset? anchor,
  });
  Future<Marker> updateMarkerPosition({
    required Marker marker,
    required LatLng newPosition,
  });
  Future<BitmapDescriptor> createCustomMarkerIcon({
    required Color color,
    double zoomLevel = 14.0,
    bool isPremium = false,
    bool isSelected = false,
    bool isGold = false,
    bool isStamped = false,
    bool isFestival = false,
  });

  Offset calculateAnchor({
    required double size,
    required bool showAsDot,
    required bool hasCrown,
  });
}

class MarkerDataSourceImpl implements MarkerDataSource {
  final Map<String, BitmapDescriptor> _iconCache = {};

  String _getCacheKey({
    required Color color,
    required double size,
    required bool showAsDot,
    required bool isPremium,
    required bool isGold,
    required bool isStamped,
    required bool isSelected,
  }) {
    return '${color.value}_${size.toStringAsFixed(1)}_${showAsDot}_${isPremium}_${isGold}_${isStamped}_${isSelected}';
  }

  @override
  Future<Marker> createMarker({
    required String markerId,
    required LatLng position,
    String? title,
    String? snippet,
    BitmapDescriptor? icon,
    VoidCallback? onTap,
    Offset? anchor,
  }) async {
    return Marker(
      markerId: MarkerId(markerId),
      position: position,
      infoWindow: InfoWindow(title: title, snippet: snippet),
      icon: icon ?? BitmapDescriptor.defaultMarker,
      onTap: onTap,
      anchor:
          anchor ?? const Offset(0.5, 1.0), // Default anchor at bottom center
    );
  }

  @override
  Future<Marker> updateMarkerPosition({
    required Marker marker,
    required LatLng newPosition,
  }) async {
    return marker.copyWith(positionParam: newPosition);
  }

  @override
  Offset calculateAnchor({
    required double size,
    required bool showAsDot,
    required bool hasCrown,
  }) {
    if (showAsDot) {
      return const Offset(0.5, 0.5);
    }

    if (hasCrown) {
      // Circle is 110 high, total image is 159 high
      // Circle starts at 48.6 from top
      // Center of circle is at 48.6 + 55 = 103.6
      // Anchor Y = 103.6 / 159.0
      return const Offset(0.5, 0.65);
    }

    // Centered for the regular squircle
    return const Offset(0.5, 0.5);
  }

  @override
  Future<BitmapDescriptor> createCustomMarkerIcon({
    required Color color,
    double zoomLevel = 14.0,
    bool isPremium = false,
    bool isSelected = false,
    bool isGold = false,
    bool isStamped = false,
    bool isFestival = false,
  }) async {
    // Use default marker style for selected markers
    if (isSelected) {
      final hue = HSVColor.fromColor(color).hue;
      return BitmapDescriptor.defaultMarkerWithHue(hue);
    }

    // Calculate marker size based on zoom level
    double size;
    bool showAsDot = false;

    if (zoomLevel < 8) {
      // Very zoomed out - tiny dot
      size = 8;
      showAsDot = true;
    } else if (zoomLevel < 10) {
      // Zoomed out - small dot
      size = 12 + (zoomLevel - 8) * 4; // 12-20
      showAsDot = true;
    } else if (zoomLevel < 12) {
      // Medium zoom - small marker
      size = 20 + (zoomLevel - 10) * 10; // 20-40
      showAsDot = false;
    } else if (zoomLevel < 14) {
      // Getting closer - medium marker
      size = 40 + (zoomLevel - 12) * 15; // 40-70
      showAsDot = false;
    } else {
      // Close zoom - full size marker (max 100)
      size = 70 + (zoomLevel - 14) * 15; // 70-100
      size = size.clamp(70, 100); // Cap at 100
      showAsDot = false;
    }

    final key = _getCacheKey(
      color: color,
      size: size,
      showAsDot: showAsDot,
      isPremium: isPremium,
      isGold: isGold,
      isStamped: isStamped,
      isSelected: isSelected,
    );

    if (_iconCache.containsKey(key)) {
      return _iconCache[key]!;
    }

    final icon = await _createCustomBitmapDescriptor(
      color: color,
      size: size,
      showAsDot: showAsDot,
      isPremium: isPremium,
      isGold: isGold,
      isStamped: isStamped,
    );

    _iconCache[key] = icon;
    return icon;
  }

  Future<BitmapDescriptor> _createCustomBitmapDescriptor({
    required Color color,
    required double size,
    required bool showAsDot,
    required bool isPremium,
    required bool isGold,
    required bool isStamped,
  }) async {
    // If we're showing a dot (zoomed out), use simpler drawing
    if (showAsDot) {
      final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(pictureRecorder);
      final center = Offset(size / 2, size / 2);

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, size / 2, paint);

      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(center, size / 2, borderPaint);

      final img = await pictureRecorder.endRecording().toImage(
        size.toInt(),
        size.toInt(),
      );
      final data = await img.toByteData(format: ui.ImageByteFormat.png);
      return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
    }

    // SVG Drawing logic
    final bool hasCrown =
        isGold; // In the current requirement, gold markers have crowns
    final double originalWidth = 113.0;
    final double originalHeight = hasCrown ? 159.0 : 110.0;
    final double scale = size / originalWidth;

    final double width = size;
    final double height = originalHeight * scale;

    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    canvas.scale(scale);

    if (hasCrown) {
      _drawCrownSvg(canvas);
    }

    // Determine colors
    Color outerColor;
    Color innerColor;

    if (isGold || isPremium) {
      // Both Gold and Premium use purple colors regardless of stamped status
      outerColor = const Color(0xFFFF97D3);
      innerColor = const Color(0xFFFF5DB1);
    } else {
      // Regular markers use red/green based on stamped status
      if (isStamped) {
        outerColor = const Color(0xFFACF9AC);
        innerColor = const Color(0xFF5BFA61);
      } else {
        outerColor = const Color(0xFFFF8D8D);
        innerColor = const Color(0xFFFF5E58);
      }
    }

    final double yOffset = hasCrown ? 48.6 : 0.0;
    _drawSquircleSvg(canvas, outerColor, innerColor, yOffset);

    final img = await pictureRecorder.endRecording().toImage(
      width.toInt(),
      height.toInt(),
    );
    final data = await img.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  void _drawSquircleSvg(
    Canvas canvas,
    Color outerColor,
    Color innerColor,
    double yOffset,
  ) {
    // Outer Path: M55 0H57.56C87.94 0 112.56 24.62 112.56 55C112.56 85.38 87.94 110 57.56 110H55C24.62 110 0 85.38 0 55C0 24.62 24.62 0 55 0Z
    final outerPath = Path()
      ..moveTo(55, yOffset)
      ..lineTo(57.56, yOffset)
      ..cubicTo(87.94, yOffset, 112.56, yOffset + 24.62, 112.56, yOffset + 55)
      ..cubicTo(
        112.56,
        yOffset + 85.38,
        87.94,
        yOffset + 110,
        57.56,
        yOffset + 110,
      )
      ..lineTo(55, yOffset + 110)
      ..cubicTo(24.62, yOffset + 110, 0, yOffset + 85.38, 0, yOffset + 55)
      ..cubicTo(0, yOffset + 24.62, 24.62, yOffset, 55, yOffset)
      ..close();

    final outerPaint = Paint()
      ..color = outerColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(outerPath, outerPaint);

    // Inner Path: M55.2698 11.5703H57.2899C81.2799 11.5703 100.72 31.0203 100.72 55.0003C100.72 78.9903 81.2699 98.4303 57.2899 98.4303H55.2698C31.2798 98.4303 11.8398 78.9803 11.8398 55.0003C11.8398 31.0103 31.2898 11.5703 55.2698 11.5703Z
    final innerPath = Path()
      ..moveTo(55.2698, yOffset + 11.5703)
      ..lineTo(57.2899, yOffset + 11.5703)
      ..cubicTo(
        81.2799,
        yOffset + 11.5703,
        100.72,
        yOffset + 31.0203,
        100.72,
        yOffset + 55.0003,
      )
      ..cubicTo(
        100.72,
        yOffset + 78.9903,
        81.2699,
        yOffset + 98.4303,
        57.2899,
        yOffset + 98.4303,
      )
      ..lineTo(55.2698, yOffset + 98.4303)
      ..cubicTo(
        31.2798,
        yOffset + 98.4303,
        11.8398,
        yOffset + 78.9803,
        11.8398,
        yOffset + 55.0003,
      )
      ..cubicTo(
        11.8398,
        yOffset + 31.0103,
        31.2898,
        yOffset + 11.5703,
        55.2698,
        yOffset + 11.5703,
      )
      ..close();

    final innerPaint = Paint()
      ..color = innerColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(innerPath, innerPaint);
  }

  void _drawCrownSvg(Canvas canvas) {
    // M21.969 43.2496C32.619 37.7596 44.699 34.6496 57.489 34.6496C69.389 34.6496 80.679 37.3396 90.769 42.1396L94.929 17.0496C95.109 15.9596 93.829 15.2396 92.999 15.9696C86.719 21.4696 78.609 27.3596 73.589 26.4496C67.509 25.3196 61.289 11.4096 57.369 0.76957C56.989 -0.26043 55.539 -0.26043 55.159 0.76957C51.249 11.4096 45.019 25.3096 38.949 26.4496C33.929 27.3696 25.819 21.4696 19.539 15.9696C18.709 15.2396 17.419 15.9696 17.599 17.0496L21.949 43.2496H21.969Z
    final crownPath = Path()
      ..moveTo(21.969, 43.2496)
      ..cubicTo(32.619, 37.7596, 44.699, 34.6496, 57.489, 34.6496)
      ..cubicTo(69.389, 34.6496, 80.679, 37.3396, 90.769, 42.1396)
      ..lineTo(94.929, 17.0496)
      ..cubicTo(95.109, 15.9596, 93.829, 15.2396, 92.999, 15.9696)
      ..cubicTo(86.719, 21.4696, 78.609, 27.3596, 73.589, 26.4496)
      ..cubicTo(67.509, 25.3196, 61.289, 11.4096, 57.369, 0.76957)
      ..cubicTo(56.989, -0.26043, 55.539, -0.26043, 55.159, 0.76957)
      ..cubicTo(51.249, 11.4096, 45.019, 25.3096, 38.949, 26.4496)
      ..cubicTo(33.929, 27.3696, 25.819, 21.4696, 19.539, 15.9696)
      ..cubicTo(18.709, 15.2396, 17.419, 15.9696, 17.599, 17.0496)
      ..lineTo(21.949, 43.2496)
      ..close();

    final crownPaint = Paint()
      ..color = const Color(0xFFFFD630)
      ..style = PaintingStyle.fill;
    canvas.drawPath(crownPath, crownPaint);
  }
}
