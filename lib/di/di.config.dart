// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:camera/camera.dart' as _i4;
import 'package:get_it/get_it.dart' as _i1;
import 'package:injectable/injectable.dart' as _i2;

import '../presentation/bloc/camera_screen_bloc.dart' as _i3;
import '../presentation/model/detection_state.dart' as _i5;

// initializes the registration of main-scope dependencies inside of GetIt
_i1.GetIt $initGetIt(
  _i1.GetIt getIt, {
  String? environment,
  _i2.EnvironmentFilter? environmentFilter,
}) {
  final gh = _i2.GetItHelper(
    getIt,
    environment,
    environmentFilter,
  );
  gh.factoryParam<_i3.CameraScreenBloc, List<_i4.CameraDescription>, _i5.DetectionState>((
    availableCameras,
    detectionState,
  ) =>
      _i3.CameraScreenBloc(
        availableCameras: availableCameras,
        detectionState: detectionState,
      ));
  return getIt;
}
