/// Domain interface for the temporary developer/admin dataset import action.
/// Publishes the bundled transport dataset to Firebase.
abstract interface class DatasetPublishRepository {
  /// Upload the bundled dataset to Firebase (Firestore + Cloud Storage).
  /// Generates and publishes the manifest.
  Future<void> publishToFirebase();
}
