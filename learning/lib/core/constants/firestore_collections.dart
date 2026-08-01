class FirestoreCollections {
  FirestoreCollections._();

  static const users = 'users';
  static const products = 'products';
  static const sales = 'sales';
  static const expenses = 'expenses';

  /// Subcollection under each product: one doc per purchase batch, so a
  /// restock at a different price never overwrites the previous cost.
  static const batches = 'batches';
}
