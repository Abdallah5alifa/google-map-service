// import 'dart:async';
// import 'dart:ui' as ui;
// import 'package:equatable/equatable.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter/gestures.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:stampire/core/bloc/paginated_bloc/exports.dart';
// import 'package:stampire/core/enum/snack_bar_enum.dart';
// import 'package:stampire/core/enum/status.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:google_maps_cluster_manager_2/google_maps_cluster_manager_2.dart'
//     as cm;
// import 'package:dart_geohash/dart_geohash.dart';
// import 'package:flutter_polyline_points/flutter_polyline_points.dart';
// import 'package:stampire/core/extensions/extensions.dart';
// import 'package:stampire/core/helpers/helpers.dart';
// import 'package:stampire/core/http/either.dart';
// import 'package:stampire/core/http/failure.dart';
// import 'package:stampire/core/http/http.dart';
// import 'package:stampire/generated/assets.dart';
// import 'package:stampire/core/service_locator/service_locator.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:stampire/core/local_storage/local_storage.dart';
// import 'package:stampire/core/theme/app_colors.dart';

// import '../core/widgets/widgets.dart';
// import 'dart:math' as math;
// part 'presentation/pages/presentation/view/home_screen.dart';
// part 'presentation/pages/presentation/widgets/map_widget.dart';
// part 'presentation/pages/presentation/widgets/stamp_place_bottom_sheet.dart';
// part 'presentation/pages/data_source/location_data_source.dart';
// part 'presentation/pages/data_source/marker_data_source.dart';
// part 'presentation/pages/data_source/polyline_data_source.dart';
// part 'presentation/pages/bloc/location/location_bloc.dart';
// part 'presentation/pages/bloc/location/location_event.dart';
// part 'presentation/pages/bloc/location/location_state.dart';
// part 'presentation/pages/bloc/marker/marker_bloc.dart';
// part 'presentation/pages/bloc/marker/marker_event.dart';
// part 'presentation/pages/bloc/marker/marker_state.dart';
// part 'presentation/pages/bloc/polyline/poyline_event.dart';
// part 'presentation/pages/bloc/polyline/poyline_bloc.dart';
// part 'presentation/pages/bloc/polyline/polyline_state.dart';
// part 'presentation/pages/mixins/location_management_mixin.dart';
// part 'presentation/pages/mixins/marker_management_mixin.dart';
// part 'presentation/pages/mixins/route_management_mixin.dart';
// part 'presentation/pages/models/stamp_place_model.dart';
// part 'presentation/pages/data_source/nearest_stamps_data_source.dart';
// part 'presentation/pages/data_source/map_style_data_source.dart';
// part 'presentation/pages/bloc/nearest_stamps/nearest_stamps_bloc.dart';
// part 'presentation/pages/bloc/nearest_stamps/nearest_stamps_event.dart';
// part 'presentation/pages/data_source/show_stamp_by_id_data_source.dart';
// part 'presentation/pages/bloc/show_stamp/show_stamp_bloc.dart';
// part 'presentation/pages/bloc/show_stamp/show_stamp_event.dart';
// part 'presentation/pages/presentation/widgets/search_stamp_widget.dart';
// part 'presentation/pages/presentation/widgets/countdown_timer_widget.dart';
// part 'presentation/pages/presentation/widgets/premium_stamp_content.dart';
// part 'presentation/pages/presentation/widgets/regular_stamp_content.dart';
// part 'presentation/pages/presentation/widgets/stamp_icon_button.dart';
// part 'presentation/pages/bloc/tip/tip_bloc.dart';
// part 'presentation/pages/bloc/tip/tip_event.dart';
// part 'presentation/pages/bloc/tip/tip_state.dart';
// part 'presentation/pages/presentation/widgets/tip_dialog.dart';

library google_maps_feature;

import 'dart:async';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:geolocator/geolocator.dart';
import 'package:google_map_service/core/app_Color.dart';
import 'package:google_map_service/core/home_service_locator.dart';
import 'package:google_map_service/core/local_storage.dart';
import 'package:google_map_service/core/map_constants.dart';
import 'package:google_map_service/core/status.dart';
import 'package:google_map_service/google_maps_feature/data/models/stamp_place_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
// import 'package:share_plus/share_plus.dart';

// Project imports (Stampire)

part '../core/map_constants.dart';

/// =======================
/// Presentation (Screens/UI)
/// =======================
part 'presentation/widgets/map_widget.dart';
///
///
/// =======================
/// Data Sources
/// =======================
/// (حسب الصورة: google_maps_feature/data/data_sources)
part 'data/data_sources/location_data_source.dart';
part 'data/data_sources/map_style_data_source.dart';
part 'data/data_sources/marker_data_source.dart';
part 'data/data_sources/polyline_data_source.dart';

/// =======================
/// Mixins
/// =======================
/// (حسب الصورة: google_maps_feature/data/mixins)
part 'data/mixins/location_management_mixin.dart';
part 'data/mixins/marker_management_mixin.dart';
part 'data/mixins/route_management_mixin.dart';

/// =======================
/// Blocs - Location
/// =======================
part 'presentation/bloc/location/location_bloc.dart';
part 'presentation/bloc/location/location_event.dart';
part 'presentation/bloc/location/location_state.dart';

/// =======================
/// Blocs - Marker
/// =======================
part 'presentation/bloc/marker/marker_bloc.dart';
part 'presentation/bloc/marker/marker_event.dart';
part 'presentation/bloc/marker/marker_state.dart';

/// =======================
/// Blocs - Polyline
/// =======================
part 'presentation/bloc/polyline/polyline_state.dart';
part 'presentation/bloc/polyline/poyline_bloc.dart';
part 'presentation/bloc/polyline/poyline_event.dart';


/// =====================
/// Service Locator 
/// =====================