/// Constants for dataset synchronization.
library;

/// The six canonical collection names that make up the transport dataset.
const List<String> kDatasetCollections = [
  'agencies',
  'stations',
  'stops',
  'routes',
  'route_patterns',
  'transfers',
];

/// Collections stored in Firestore (queryable).
const List<String> kFirestoreCollections = [
  'agencies',
  'stations',
  'stops',
  'routes',
  'route_patterns',
  'transfers',
];

/// Collections that affect the V4 routing graph.
/// Any change to these collections requires a graph rebuild.
const Set<String> kRoutingCollections = {
  'stops',
  'stations',
  'routes',
  'route_patterns',
  'transfers',
};


/// Local dataset directory name inside applicationDocumentsDirectory.
const String kLocalDatasetDir = 'wassla_dataset';
const String kActiveDir = 'active';
const String kStagingDir = 'staging';

/// Schema version for the current dataset format.
const int kSchemaVersion = 1;

/// Development flag — set to false before production release.
const bool kEnableDevImport = true;
