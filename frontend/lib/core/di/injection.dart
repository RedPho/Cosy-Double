import 'package:get_it/get_it.dart';
import '../network/api_client.dart';
import '../../data/datasources/remote_data_source.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/room_repository.dart';
import '../../data/repositories/room_repository_impl.dart';
import '../../domain/repositories/shop_repository.dart';
import '../../data/repositories/shop_repository_impl.dart';
import '../../domain/repositories/canvas_repository.dart';
import '../../data/repositories/canvas_repository_impl.dart';
import '../../presentation/blocs/auth/auth_bloc.dart';
import '../../presentation/blocs/room/room_bloc.dart';
import '../../presentation/blocs/shop/shop_bloc.dart';
import '../../presentation/blocs/canvas/canvas_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Core
  sl.registerLazySingleton(() => ApiClient());

  // Data sources
  sl.registerLazySingleton(() => RemoteDataSource(apiClient: sl()));

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<RoomRepository>(
    () => RoomRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<ShopRepository>(
    () => ShopRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<CanvasRepository>(
    () => CanvasRepositoryImpl(remoteDataSource: sl()),
  );

  // Blocs
  sl.registerLazySingleton(() => AuthBloc(authRepository: sl()));
  sl.registerFactory(() => RoomBloc(roomRepository: sl(), apiClient: sl()));
  sl.registerFactory(() => ShopBloc(shopRepository: sl()));
  sl.registerFactory(() => CanvasBloc(canvasRepository: sl()));
}
