import 'package:flutter_test/flutter_test.dart';
import 'package:profitpulse/core/constants/firestore_collections.dart';
import 'package:profitpulse/features/customers/services/customer_service.dart';

import 'support/fake_shop.dart';

void main() {
  late FakeShop shop;
  late CustomerService service;

  setUp(() {
    shop = FakeShop();
    service = CustomerService(db: shop.db);
  });

  for (final online in [true, false]) {
    final mode = online ? 'online' : 'offline';

    test('a payment reduces the balance and is logged ($mode)', () async {
      await shop.addCustomer('c1', balance: 100);

      await service.recordPayment(
        userId,
        'c1',
        amount: 40,
        online: online,
        note: 'cash',
      );
      await pumpEventQueue();

      expect(await shop.balanceOf('c1'), 60);
      final ledger = await shop
          .customerRef('c1')
          .collection(FirestoreCollections.ledger)
          .get();
      final entry = ledger.docs.single;
      expect(entry['type'], 'payment');
      expect(entry['amount'], 40);
      expect(entry['note'], 'cash');
    });

    test('a payment above the balance is refused ($mode)', () async {
      await shop.addCustomer('c1', balance: 30);

      await expectLater(
        service.recordPayment(userId, 'c1', amount: 31, online: online),
        throwsA(isA<Exception>()),
      );
      await pumpEventQueue();

      expect(await shop.balanceOf('c1'), 30);
    });
  }

  test('paying off the exact balance clears it', () async {
    await shop.addCustomer('c1', balance: 30);

    await service.recordPayment(userId, 'c1', amount: 30, online: true);

    expect(await shop.balanceOf('c1'), 0);
  });

  test('a customer who owes money cannot be deleted', () async {
    await shop.addCustomer('c1', balance: 5);

    await expectLater(
      service.deleteCustomer(userId, 'c1'),
      throwsA(isA<Exception>()),
    );
    expect((await shop.customerRef('c1').get()).exists, isTrue);
  });

  test('deleting a settled customer removes their ledger too', () async {
    await shop.addCustomer('c1', balance: 10);
    await service.recordPayment(userId, 'c1', amount: 10, online: true);

    await service.deleteCustomer(userId, 'c1');

    expect((await shop.customerRef('c1').get()).exists, isFalse);
    final ledger = await shop
        .customerRef('c1')
        .collection(FirestoreCollections.ledger)
        .get();
    expect(ledger.docs, isEmpty);
  });
}
