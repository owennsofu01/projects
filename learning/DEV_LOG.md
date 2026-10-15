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
| `da08eb3` | #10 Budgets: monthly limit per expense category, Budgets screen, dashboard card, 80%/over warnings on new expenses |

### In progress (uncommitted)
**#12 Import and backup** (session 2026-10-15)
- Settings → Data → Import from Excel: pick an .xlsx (`file_picker`),
  preview counts and rows that will be left out, then import. "Products"
  sheet (Name, Cost price, Selling price, Stock, Reorder level, Barcode)
  and/or "Expenses" sheet (Date, Title, Category, Amount). Headers and
  sheet names match ignoring case; dates as Excel dates, YYYY-MM-DD or
  D/M/YYYY. Products with an existing name and expenses already recorded
  (same day, title, category, amount) are skipped. Opening stock gets a
  purchase batch. Writes split into batches of 400.
- "Get the template" shares a template workbook with examples and help.
- Settings → Data → Back up all data: shares an .xlsx with About,
  Products, Expenses, Sales, Customers, Customer ledger, Stock purchases,
  Budgets. Amounts are stored ZMW values. Products/Expenses sheets use the
  import layout, so a backup re-imports (skipping what's already there).
- No full restore of sales, customers or ledgers (backup is a copy for
  the user's records).
- Code: `lib/features/data_transfer/`, `test/data_transfer_test.dart`.
  56 tests pass, analyze clean, Android debug APK builds.
- Tested on a phone by the user. iOS needs `pod install` for file_picker.

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
- Merge `profitpulse-profitability-monthly` into `main` and push when ready.
