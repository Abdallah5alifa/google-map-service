// import 'package:get_it/get_it.dart';

// // ✅ ده لازم يحتوي على ILocationCache و LocationCacheImpl
// import 'package:google_map_service/core/local_storage.dart';

// // ✅ feature imports (عدّل المسارات حسب مشروعك)
// import 'package:google_map_service/google_maps_feature/home.dart';

// final GetIt getIt = GetIt.instance;

// abstract final class AppServiceLocator {
//   AppServiceLocator._();

//   static Future<void> setup() async {
//     _registerCore(getIt); // ✅ لازم
//     await HomeServiceLocator.execute(getIt: getIt);
//   }

//   static void _registerCore(GetIt sl) {
//     // ✅ تسجيل الكاش اللي كان ناقص
//     if (!sl.isRegistered<ILocationCache>()) {}
//   }
// }

import 'package:get_it/get_it.dart';
import 'package:google_map_service/core/local_storage.dart';
import 'package:google_map_service/google_maps_feature/home.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HomeServiceLocator {
  static Future<void> execute({required GetIt getIt}) async {
    // =========================
    // Data Sources
    // =========================
    if (!getIt.isRegistered<LocationDataSource>()) {
      getIt.registerLazySingleton<LocationDataSource>(
        () => LocationDataSourceImpl(getIt<ILocationCache>()),
      );
    }

    if (!getIt.isRegistered<MarkerDataSource>()) {
      getIt.registerLazySingleton<MarkerDataSource>(
        () => MarkerDataSourceImpl(),
      );
    }

    if (!getIt.isRegistered<PolylineDataSource>()) {
      getIt.registerLazySingleton<PolylineDataSource>(
        () => PolylineDataSourceImpl(),
      );
    }

    if (!getIt.isRegistered<MapStyleDataSource>()) {
      getIt.registerLazySingleton<MapStyleDataSource>(
        () => MapStyleDataSourceImpl(),
      );
    }

    // =========================
    // Blocs
    // =========================
    if (!getIt.isRegistered<LocationBloc>()) {
      getIt.registerLazySingleton<LocationBloc>(
        () => LocationBloc(getIt<LocationDataSource>()),
      );
    }

    if (!getIt.isRegistered<MarkerBloc>()) {
      getIt.registerLazySingleton<MarkerBloc>(
        () => MarkerBloc(getIt<MarkerDataSource>()),
      );
    }

    if (!getIt.isRegistered<PolylineBloc>()) {
      getIt.registerLazySingleton<PolylineBloc>(
        () => PolylineBloc(getIt<PolylineDataSource>()),
      );
    }
  }
}


final GetIt getIt = GetIt.instance;

abstract final class AppServiceLocator {
  AppServiceLocator._();

  static Future<void> setup() async {
    await _registerCore(getIt); // ✅ await
    await HomeServiceLocator.execute(getIt: getIt);
  }

  static Future<void> _registerCore(GetIt sl) async {
    // ✅ Hive init (مرة واحدة)
    await Hive.initFlutter();

    // ✅ Open box (مرة واحدة)
    if (!Hive.isBoxOpen(LocationCacheImpl.boxName)) {
      await Hive.openBox(LocationCacheImpl.boxName);
    }

    // ✅ Register box
    if (!sl.isRegistered<Box>()) {
      sl.registerLazySingleton<Box>(() => Hive.box(LocationCacheImpl.boxName));
    }

    // ✅ Register cache
    if (!sl.isRegistered<ILocationCache>()) {
      sl.registerLazySingleton<ILocationCache>(
        () => LocationCacheImpl(sl<Box>()),
      );
    }
  }
}
