# ProfitPulse — Dev Log

## Session: 2026-10-14

Branch: `profitpulse-profitability-monthly`, fast-forwarded into `main` and pushed on 2026-10-15

### Fixed
- iOS launch crash: `google_mobile_ads` aborted at startup because
  `GADApplicationIdentifier` was missing from `ios/Runner/Info.plist`.
  Flutter reported it as "Error connecting to the service protocol".

### Done and committed

| Commit | Change |
|---|---|
| `27fe849` | Product Profitability: monthly view (All time / any of last 24 months), search, Profitable / Loss / Not sold filters, stock corrections |
| `574a5a1` | Google Mobile Ads setup, AdMob app IDs |
| `6b2264f` | #1 Ads shown (banner above tab bar, interstitial after every 3rd sale, max once per 3 min; test units in debug). #2 Per-product reorder level and low-stock warnings |
| `b8862a2` | #3 12-month net profit chart on dashboard |
| `619c91c` | #4 Multi-item checkout (cart); lines share a `receiptId`; Sales list grouped by receipt |
| `48b854a` | #5 Customers and credit: balances, ledger, payments, WhatsApp reminder, "Owed to you" card |
| `d40666c` | #6 Shareable receipts (image/text) and Business details in Settings |
| `3b2b69e` | #7 Barcode scanning (`mobile_scanner`): product barcodes, continuous scan at checkout |
| `fc38959` | #8 Offline support: checkout and payments work offline, saves don't hang, sync status strip, unsynced-sale icon |
| `cfe5f1b` | Fix Android launch crash: AdMob `APPLICATION_ID` was missing from `AndroidManifest.xml` |
| `ed981a0` | #9 Daily summary notification: Settings → Notifications, local scheduled notifications (default 20:00), tested on a real phone |
| `e61107f` | #13 Tests (fake_cloud_firestore): FIFO checkout, credit, payments, stock corrections, profitability, report totals. Fixed `setStock` reads-after-writes bug |
| `da08eb3` | #10 Budgets: monthly limit per expense category, Budgets screen, dashboard card, 80%/over warnings on new expenses |
| `f198915` | #12 Import from Excel (Products/Expenses sheets, template) and full backup to .xlsx |

### Services (committed 2026-10-16)
**Services** (session 2026-10-16), for barbers, hair plaiting and similar
- New `services` collection (`ServiceModel`: name, price, materialsCost).
  No stock or batches. Catalog tab (was Products) has Products | Services
  tabs; the table icon opens Product profitability or Service performance.
- Checkout picker has a Products/Services switch. A service line's price
  and jobs can be changed per sale (tap the price). Service lines skip
  stock and FIFO; cost = materialsCost × jobs. Mixed carts and credit work.
- Service sales go in `sales` with `kind: 'service'`, `serviceId`, no
  `productId`; `productName` holds the service name. Old sales without
  `kind` read as products. Product insights/profitability skip services.
- Service performance screen: jobs, revenue, average price, materials,
  profit per service, all time or by month (shared `MonthPeriodBar`).
  Deleted services still show from their sales.
- Backup has a Services sheet and a Type column on Sales; import and the
  template read a Services sheet (Name, Price, Materials cost). Report
  export has a Type column.
- Account deletion now also removes services, customers (and ledgers),
  budgets and product batches.
- Code: `lib/features/services/`, `lib/features/catalog/`,
  `test/services_test.dart`. 68 tests pass, analyze clean, debug APK
  builds. Tested on a phone by the user.
- Later ideas: "done by" (staff) per service sale with commission report;
  hiding Products for service-only businesses.

### Remaining
Nothing. #11 Pro tier (in-app purchase) was dropped on 2026-10-15.

### Open issues
- `AdsController` in `lib/ads/ads_manager.dart` auto-shows rewarded ads
  every 15 min. That breaks AdMob policy. Unused, but should be deleted.
- No UMP consent form (EEA/UK) or iOS App Tracking Transparency prompt yet.
- Typed amounts (expenses, payments, "paid now", budget limits) are saved as entered, not
  converted from the selected display currency. Only matters for non-ZMW
  display currencies.
- Offline edge case: two phones selling the last unit while one is offline
  can drive stock negative (no server check offline).
- Customer phone numbers need a country code for WhatsApp reminders.
