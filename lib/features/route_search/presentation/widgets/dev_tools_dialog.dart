import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../dataset_sync/presentation/cubit/sync_cubit.dart';

class DevToolsDialog extends StatelessWidget {
  const DevToolsDialog({super.key});

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
