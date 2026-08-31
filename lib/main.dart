import 'dart:developer' as developer;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import 'package:wassla/core/constants/sync_constants.dart';
import 'package:wassla/core/routing/dart_v4_routing_service.dart';
import 'package:wassla/core/storage/sync_database.dart';
import 'package:wassla/core/sync/firebase_remote_data_source.dart';
import 'package:wassla/features/dataset_sync/data/datasources/local_data_source.dart';
import 'package:wassla/features/dataset_sync/data/repositories/dataset_sync_repository_impl.dart';
import 'package:wassla/features/dataset_sync/data/repositories/firebase_dataset_publish_repository.dart';
import 'package:wassla/features/dataset_sync/domain/entities/sync_entities.dart';
import 'package:wassla/features/dataset_sync/domain/usecases/publish_dataset_usecase.dart';
import 'package:wassla/features/dataset_sync/domain/usecases/sync_dataset_usecase.dart';
import 'package:wassla/features/dataset_sync/presentation/cubit/sync_cubit.dart';
import 'package:wassla/features/places/data/repositories/local_place_repository.dart';
import 'package:wassla/features/places/domain/usecases/search_places_usecase.dart';
import 'package:wassla/features/route_details/presentation/pages/route_details_page.dart';
import 'package:wassla/features/route_search/data/datasources/routing_isolate_worker.dart';
import 'package:wassla/features/route_search/domain/entities/routing_entities.dart';
import 'package:wassla/features/route_search/presentation/cubit/autocomplete_cubit.dart';
import 'package:wassla/features/route_search/domain/usecases/search_route_usecase.dart';
import 'package:wassla/features/route_search/presentation/cubit/route_search_cubit.dart';
import 'package:wassla/core/theme/app_theme.dart';
import 'package:wassla/core/router/app_router.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // --- Manual DI wiring (will be replaced by get_it + injectable) ---

  // Database
  final db = SyncDatabase();

  // Data sources
  final localDataSource = LocalDataSource(db);
  final remoteDataSource = FirebaseRemoteDataSource();

  // Repositories
  final syncRepo = DatasetSyncRepositoryImpl(remoteDataSource, localDataSource);

  // Routing
  final routingWorker = RoutingIsolateWorker();
  final routingService = DartV4RoutingService(routingWorker, localDataSource);

  // Places
  final placeRepository = LocalPlaceRepository(localDataSource);
  final searchPlacesUseCase = SearchPlacesUseCase(placeRepository);

  // Use cases
  final searchRouteUseCase = SearchRouteUseCase(routingService);
  final syncDatasetUseCase = SyncDatasetUseCase(syncRepo);

  // Dev import (behind flag)
  PublishDatasetUseCase? publishDatasetUseCase;
  if (kEnableDevImport) {
    final publishRepo = FirebaseDatasetPublishRepository(remoteDataSource);
    publishDatasetUseCase = PublishDatasetUseCase(publishRepo);
  }

  runApp(
    WasslaApp(
      searchRouteUseCase: searchRouteUseCase,
      searchPlacesUseCase: searchPlacesUseCase,
      syncDatasetUseCase: syncDatasetUseCase,
      publishDatasetUseCase: publishDatasetUseCase,
      routingService: routingService,
      localDataSource: localDataSource,
      syncRepo: syncRepo,
    ),
  );
}

class WasslaApp extends StatefulWidget {
  final SearchRouteUseCase searchRouteUseCase;
  final SearchPlacesUseCase searchPlacesUseCase;
  final SyncDatasetUseCase syncDatasetUseCase;
  final PublishDatasetUseCase? publishDatasetUseCase;
  final DartV4RoutingService routingService;
  final LocalDataSource localDataSource;
  final DatasetSyncRepositoryImpl syncRepo;

  const WasslaApp({
    super.key,
    required this.searchRouteUseCase,
    required this.searchPlacesUseCase,
    required this.syncDatasetUseCase,
    this.publishDatasetUseCase,
    required this.routingService,
    required this.localDataSource,
    required this.syncRepo,
  });

  @override
  State<WasslaApp> createState() => _WasslaAppState();
}

class _WasslaAppState extends State<WasslaApp> {
  late final SyncCubit _syncCubit;
  late final RouteSearchCubit _routeSearchCubit;
  late final AutocompleteCubit _fromAutocompleteCubit;
  late final AutocompleteCubit _toAutocompleteCubit;
  bool _isBootstrapping = true;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _syncCubit = SyncCubit(
      widget.syncDatasetUseCase,
      publishDatasetUseCase: widget.publishDatasetUseCase,
    );
    _routeSearchCubit = RouteSearchCubit(
      widget.searchRouteUseCase,
      widget.routingService,
    );
    _fromAutocompleteCubit = AutocompleteCubit(widget.searchPlacesUseCase);
    _toAutocompleteCubit = AutocompleteCubit(widget.searchPlacesUseCase);
    
    _router = AppRouter.createRouter(
      bootstrapBuilder: (context) => _BootstrapPage(
        syncCubit: _syncCubit,
        fromCubit: _fromAutocompleteCubit,
        toCubit: _toAutocompleteCubit,
        publishDatasetUseCase: widget.publishDatasetUseCase,
      ),
      fromAutocompleteCubit: _fromAutocompleteCubit,
      toAutocompleteCubit: _toAutocompleteCubit,
    );
    
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final hasLocal = await widget.syncRepo.hasLocalDataset();
    developer.log('Bootstrap Start - hasLocalDataset: $hasLocal', name: 'AppBootstrap');

    if (hasLocal) {
      developer.log('Decision: USE_LOCAL_AND_BACKGROUND_SYNC', name: 'AppBootstrap');
      // Existing install — show UI immediately, sync in background
      _router.go(AppRouter.search);

      // Initialize engine
      _routeSearchCubit.initializeEngine();

      // Background sync
      final result = await _syncCubit.syncDataset();
      developer.log('Background Sync Result: ${result.status}', name: 'AppBootstrap');
      if (result.routingDataChanged) {
        _routeSearchCubit.onRoutingDataUpdated();
        _routeSearchCubit.initializeEngine();
      }
    } else {
      // First install — need to download dataset first
      setState(() {
        _isBootstrapping = true;
      });

      final result = await _syncCubit.syncDataset();
      developer.log('Initial Sync Result: ${result.status}', name: 'AppBootstrap');
      
      if (result.status == SyncStatusType.initialDownload ||
          result.status == SyncStatusType.updated) {
        developer.log('Decision: BOOTSTRAP_FROM_FIREBASE (Success)', name: 'AppBootstrap');
        _router.go(AppRouter.search);
        _routeSearchCubit.initializeEngine();
      } else {
        // Sync failed — stay on bootstrap screen (initialLocation is '/')
        developer.log('Decision: FAILURE', name: 'AppBootstrap');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _syncCubit),
        BlocProvider.value(value: _routeSearchCubit),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return MaterialApp.router(
            title: 'Wassla',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system, // Rely on system theme
            routerConfig: _router,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _syncCubit.close();
    _routeSearchCubit.close();
    _fromAutocompleteCubit.close();
    _toAutocompleteCubit.close();
    super.dispose();
  }
}

/// Bootstrap loading page — shown only on first install.
class _BootstrapPage extends StatelessWidget {
  final SyncCubit syncCubit;
  final AutocompleteCubit fromCubit;
  final AutocompleteCubit toCubit;
  final PublishDatasetUseCase? publishDatasetUseCase;

  const _BootstrapPage({
    required this.syncCubit,
    required this.fromCubit,
    required this.toCubit,
    this.publishDatasetUseCase,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wassla — Setup')),
      body: Center(
        child: BlocBuilder<SyncCubit, SyncState>(
          bloc: syncCubit,
          builder: (context, state) {
            if (state is SyncChecking || state is SyncDownloading) {
              return const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Downloading transport dataset...'),
                ],
              );
            }

            if (state is PublishInProgress) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(state.message),
                ],
              );
            }

            if (state is PublishComplete) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 48),
                  const SizedBox(height: 16),
                  const Text('Dataset published to Firebase!'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      // Now sync to download what we just published
                      final result = await syncCubit.syncDataset();
                      if (result.status == SyncStatusType.initialDownload ||
                          result.status == SyncStatusType.updated) {
                        if (context.mounted) {
                          // Rebuild parent to transition to route search
                          context.go(AppRouter.search);
                        }
                      }
                    },
                    child: const Text('Continue to Sync'),
                  ),
                ],
              );
            }

            if (state is SyncError || state is PublishError || (state is SyncComplete && state.result.status == SyncStatusType.failed)) {
              final message = state is SyncError
                  ? state.message
                  : state is PublishError
                      ? state.message
                      : (state as SyncComplete).result.errorMessage ?? 'Unknown sync failure';
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(message, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  if (kEnableDevImport) ...[
                    const Text(
                      'Firestore appears empty.\n'
                      'Use "Publish Dataset" to upload the transport data.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => syncCubit.publishDataset(),
                      icon: const Icon(Icons.cloud_upload),
                      label: const Text('Publish Dataset to Firebase'),
                    ),
                  ],
                ],
              );
            }

            // Initial state — check if we need dev import
            developer.log('Decision: DEVELOPER_IMPORT', name: 'AppBootstrap');
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('No local dataset found.'),
                const SizedBox(height: 24),
                if (kEnableDevImport) ...[
                  ElevatedButton.icon(
                    onPressed: () => syncCubit.publishDataset(),
                    icon: const Icon(Icons.cloud_upload),
                    label: const Text('Publish Dataset to Firebase'),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '(Development only)',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
