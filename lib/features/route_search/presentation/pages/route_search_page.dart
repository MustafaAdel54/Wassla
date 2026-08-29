import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/sync_constants.dart';
import '../../../dataset_sync/presentation/cubit/sync_cubit.dart';
import '../../domain/entities/routing_entities.dart';
import '../cubit/route_search_cubit.dart';

/// Simple functional route search page for data/routing validation.
/// Final visual design will be implemented later.
class RouteSearchPage extends StatefulWidget {
  const RouteSearchPage({super.key});

  @override
  State<RouteSearchPage> createState() => _RouteSearchPageState();
}

class _RouteSearchPageState extends State<RouteSearchPage> {
  final _originLatCtrl = TextEditingController();
  final _originLngCtrl = TextEditingController();
  final _destLatCtrl = TextEditingController();
  final _destLngCtrl = TextEditingController();

  // Default: Helwan Metro → Maadi Metro (via station IDs for testing)
  final _originIdCtrl = TextEditingController(
    text: 'station_metro_10_AHL_METRO',
  );
  final _destIdCtrl = TextEditingController(text: 'station_metro_23_MAD_METRO');

  bool _useStopIds = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wassla — Route Search'),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: _useStopIds ? 'Switch to coordinates' : 'Switch to IDs',
            onPressed: () => setState(() => _useStopIds = !_useStopIds),
          ),
          if (kEnableDevImport)
            IconButton(
              icon: const Icon(Icons.developer_board),
              tooltip: 'Developer Tools',
              onPressed: () {
                final syncCubit = context.read<SyncCubit>();
                showDialog(
                  context: context,
                  builder: (ctx) => BlocProvider.value(
                    value: syncCubit,
                    child: const _DevToolsDialog(),
                  ),
                );
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_useStopIds) ...[
              TextField(
                controller: _originIdCtrl,
                decoration: const InputDecoration(
                  labelText: 'Origin Stop/Station ID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _destIdCtrl,
                decoration: const InputDecoration(
                  labelText: 'Destination Stop/Station ID',
                  border: OutlineInputBorder(),
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _originLatCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Origin Lat',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _originLngCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Origin Lng',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _destLatCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Dest Lat',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _destLngCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Dest Lng',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _search, child: const Text('Find Route')),
            const SizedBox(height: 16),
            Expanded(
              child: BlocBuilder<RouteSearchCubit, RouteSearchState>(
                builder: (context, state) {
                  if (state is EngineInitializing) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Building routing graph...'),
                        ],
                      ),
                    );
                  }
                  if (state is RouteSearchLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is RouteSearchNoResult) {
                    return const Center(
                      child: Text(
                        'No route found',
                        style: TextStyle(fontSize: 18),
                      ),
                    );
                  }
                  if (state is RouteSearchError) {
                    return Center(
                      child: Text(
                        'Error: ${state.message}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }
                  if (state is RouteSearchSuccess) {
                    return _buildResult(state.result);
                  }
                  return const Center(
                    child: Text(
                      'Enter origin and destination to search',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _search() {
    final cubit = context.read<RouteSearchCubit>();

    if (_useStopIds) {
      final originId = _originIdCtrl.text.trim();
      final destId = _destIdCtrl.text.trim();
      if (originId.isEmpty || destId.isEmpty) return;
      cubit.searchByStopIds(originId, destId);
      return;
    }

    final originLat = double.tryParse(_originLatCtrl.text);
    final originLng = double.tryParse(_originLngCtrl.text);
    final destLat = double.tryParse(_destLatCtrl.text);
    final destLng = double.tryParse(_destLngCtrl.text);

    if (originLat == null ||
        originLng == null ||
        destLat == null ||
        destLng == null) {
      return;
    }

    cubit.searchRoute(
      RouteRequest(
        origin: LocationPoint(latitude: originLat, longitude: originLng),
        destination: LocationPoint(latitude: destLat, longitude: destLng),
      ),
    );
  }

  Widget _buildResult(RouteResult result) {
    return ListView(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${result.durationMinutes} minutes',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${result.transfers} transfer(s) · '
                  '${result.walkingMinutes} min walking',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
        const Divider(),
        ...result.segments.map(
          (seg) => ListTile(
            leading: Icon(_modeIcon(seg.mode)),
            title: Text(seg.routeName ?? seg.mode),
            subtitle: Text('${seg.fromName} → ${seg.toName}'),
            trailing: Text('${seg.durationMinutes} min'),
          ),
        ),
      ],
    );
  }

  IconData _modeIcon(String mode) {
    switch (mode) {
      case 'metro':
        return Icons.subway;
      case 'bus':
        return Icons.directions_bus;
      case 'microbus':
      case 'minibus':
        return Icons.airport_shuttle;
      case 'walking':
        return Icons.directions_walk;
      default:
        return Icons.commute;
    }
  }

  @override
  void dispose() {
    _originLatCtrl.dispose();
    _originLngCtrl.dispose();
    _destLatCtrl.dispose();
    _destLngCtrl.dispose();
    _originIdCtrl.dispose();
    _destIdCtrl.dispose();
    super.dispose();
  }
}

class _DevToolsDialog extends StatelessWidget {
  const _DevToolsDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Developer Tools'),
      content: BlocBuilder<SyncCubit, SyncState>(
        builder: (context, state) {
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
            return const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 48),
                SizedBox(height: 16),
                Text('Dataset published to Firebase!'),
              ],
            );
          }
          if (state is PublishError) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(state.message),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.read<SyncCubit>().publishDataset(),
                  child: const Text('Retry Publish'),
                ),
              ],
            );
          }
          
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Use this to manually push the bundled dataset to Firebase.'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => context.read<SyncCubit>().publishDataset(),
                icon: const Icon(Icons.cloud_upload),
                label: const Text('Publish Dataset to Firebase'),
              ),
            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
