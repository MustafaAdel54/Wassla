import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/sync_constants.dart';
import '../../../dataset_sync/presentation/cubit/sync_cubit.dart';
import '../../domain/entities/routing_entities.dart';
import '../cubit/autocomplete_cubit.dart';
import '../cubit/route_search_cubit.dart';

/// Simple functional route search page for data/routing validation.
/// Final visual design will be implemented later.
class RouteSearchPage extends StatefulWidget {
  final AutocompleteCubit fromCubit;
  final AutocompleteCubit toCubit;

  const RouteSearchPage({
    super.key,
    required this.fromCubit,
    required this.toCubit,
  });

  @override
  State<RouteSearchPage> createState() => _RouteSearchPageState();
}

class _RouteSearchPageState extends State<RouteSearchPage> {
  // Only used when NOT using Stop IDs
  final _originLatCtrl = TextEditingController();
  final _originLngCtrl = TextEditingController();
  final _destLatCtrl = TextEditingController();
  final _destLngCtrl = TextEditingController();

  final _originCtrl = TextEditingController();
  final _destCtrl = TextEditingController();

  final _originFocusNode = FocusNode();
  final _destFocusNode = FocusNode();

  bool _useStopIds = true;

  @override
  void initState() {
    super.initState();
    _originCtrl.addListener(() {
      widget.fromCubit.onQueryChanged(_originCtrl.text);
    });
    _destCtrl.addListener(() {
      widget.toCubit.onQueryChanged(_destCtrl.text);
    });
    _originFocusNode.addListener(() {
      if (!_originFocusNode.hasFocus) widget.fromCubit.onFocusLost();
    });
    _destFocusNode.addListener(() {
      if (!_destFocusNode.hasFocus) widget.toCubit.onFocusLost();
    });
  }

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
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_useStopIds) ...[
              _AutocompleteField(
                label: 'Origin (From)',
                controller: _originCtrl,
                focusNode: _originFocusNode,
                cubit: widget.fromCubit,
              ),
              const SizedBox(height: 8),
              _AutocompleteField(
                label: 'Destination (To)',
                controller: _destCtrl,
                focusNode: _destFocusNode,
                cubit: widget.toCubit,
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
          ],
        ),
      ),
    ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _search, child: const Text('Find Route')),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 16.0)),
        ],
      ),
    );
  }

  void _search() {
    final cubit = context.read<RouteSearchCubit>();

    if (_useStopIds) {
      final originPlace = widget.fromCubit.state.selectedPlace;
      final destPlace = widget.toCubit.state.selectedPlace;
      if (originPlace == null || destPlace == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select valid places from the suggestions')),
        );
        return;
      }
      cubit.searchByStopIds(originPlace.id, destPlace.id);
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
    _originCtrl.dispose();
    _destCtrl.dispose();
    _originFocusNode.dispose();
    _destFocusNode.dispose();
    super.dispose();
  }
}

class _AutocompleteField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final AutocompleteCubit cubit;

  const _AutocompleteField({
    required this.label,
    required this.controller,
    required this.focusNode,
    required this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AutocompleteCubit, AutocompleteState>(
      bloc: cubit,
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: cubit.onQueryChanged,
              decoration: InputDecoration(
                labelText: label,
                border: const OutlineInputBorder(),
                suffixIcon: state.selectedPlace != null
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : (state.isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null),
              ),
            ),
            if (state.suggestions.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 4),
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: state.suggestions.length,
                  itemBuilder: (context, index) {
                    final place = state.suggestions[index];
                    return ListTile(
                      title: Text(place.name),
                      dense: true,
                      onTap: () {
                        // Unfocus the field
                        focusNode.unfocus();
                        // 1. We must temporarily remove the listener to avoid
                        // immediately invalidating the selected place when we 
                        // update the text field programmatically.
                        final text = place.name;
                        // Actually, the easiest way to avoid re-triggering is to let the cubit handle it
                        // by checking `if (query == state.query) return;` which it already does!
                        
                        // BUT, to be safe, we just set the text. The listener fires, 
                        // sees text == place.name, but since we are about to call onSuggestionSelected,
                        // we must ensure order.
                        // Better: call cubit first, then update text.
                        cubit.onSuggestionSelected(place);
                        controller.text = text; 
                        
                        // Wait, if we set text, listener fires with text.
                        // In cubit, query == state.query will be TRUE since we just set state.query = text!
                      },
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
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
