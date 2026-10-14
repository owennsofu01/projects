class FirestoreCollections {
  FirestoreCollections._();

  static const users = 'users';
  static const products = 'products';
  static const sales = 'sales';
  static const expenses = 'expenses';
  static const customers = 'customers';

  /// Subcollection under each customer: one doc per credit sale or
  /// payment, so the running balance on the customer doc has an audit
  /// trail behind it.
  static const ledger = 'ledger';

  /// Subcollection under each product: one doc per purchase batch, so a
  /// restock at a different price never overwrites the previous cost.
  static const batches = 'batches';
}
