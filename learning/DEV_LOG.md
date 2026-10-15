# ProfitPulse — Dev Log

## Session: 2026-10-14

Branch: `profitpulse-profitability-monthly` (not merged to `main`, not pushed)

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

### In progress (uncommitted)
**#10 Budgets** (session 2026-10-15)
- Monthly limit per expense category: `users/{uid}/budgets/{key}`, key =
  lowercased, trimmed category (blank = "other"), so "Rent"/"rent " match.
- Expenses tab → savings icon (badge = budgets near/over) → Budgets screen:
  progress bars, add/edit sheet, delete. Dashboard "Budgets" card.
- Warning after saving an expense that takes a category to 80% or over its
  limit (replaces the "Expense added" snackbar; not repeated once already
  near/over).
- Add Expense category field now suggests existing categories.
- Code: `lib/features/budgets/`, `dashboard/widgets/budget_card.dart`,
  `test/budget_test.dart`. 43 tests pass, analyze clean, debug APK builds.
- Tested on a phone by the user.


### Remaining
1. **#12 Backup and import:** import products/expenses from Excel; full backup.
2. **#11 Pro tier:** in-app purchase (ad-free, staff accounts). Needs App
   Store Connect / Play Console setup.

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
- Merge `profitpulse-profitability-monthly` into `main` and push when ready.
