# Daily Collection App

A daily collection loan tracking app built with Flutter. Track loans with daily installment collections, overdue interest, SIM-based SMS, and full backup/restore.

## Features

- **Customer Management**: Add unlimited customers, edit details, archive
- **Loan Entry**: Principal + Return Amount + Daily Installment → auto-calculates days, profit, daily interest rate
- **Daily Schedule**: Auto-generates daily collection entries with Sunday/holiday skip option
- **Collection Entry**: Mark Paid / Partial / Missed; supports multiple collections per day
- **Overdue + Simple Interest**: Grace period configurable, simple interest on overdue amounts
- **Pre-Closure**: Close loan mid-way, cancel remaining schedule
- **Loan Cancel**: Cancel wrongly created loans
- **SMS via SIM**: Send payment confirmations, reminders, completion messages from your SIM
- **Dashboard**: Total given, collected, profit, active/overdue/completed counts
- **Backup/Restore**: Export to JSON, import on another phone, CSV export
- **Fully Offline**: No internet needed, all data stored locally in SQLite

## Setup Instructions

### Prerequisites
- Flutter SDK (stable channel) — version 3.x or later
- Android Studio or VS Code with Flutter extension
- Android device or emulator

### Steps

1. **Extract the project ZIP** to a folder

2. **Generate Flutter scaffolding** (if needed):
   ```bash
   cd daily_collection_app
   flutter create --org com.dailyhisab --project-name daily_collection_app .
   ```
   This generates the Android/iOS platform files. Answer "y" if asked to overwrite.

3. **Copy the AndroidManifest.xml** (already included at):
   ```
   android/app/src/main/AndroidManifest.xml
   ```
   This has SMS permissions. If `flutter create` overwrites it, re-copy from this project.

4. **Install dependencies**:
   ```bash
   flutter pub get
   ```

5. **Run the app**:
   ```bash
   flutter run
   ```

6. **Build APK**:
   ```bash
   flutter build apk --release
   ```
   The APK will be at `build/app/outputs/flutter-apk/app-release.apk`

## Tech Stack

| Component | Technology |
|---|---|
| Framework | Flutter (Dart) |
| Database | SQLite (sqflite package) |
| SMS | SIM-based (telephony package) |
| Backup | JSON export/import |
| Storage | Local (offline) |

## Project Structure

```
lib/
├── main.dart                      # App entry point
├── app.dart                       # MaterialApp + routing
├── models/
│   ├── customer.dart              # Customer model
│   ├── loan.dart                   # Loan model + LoanStatus enum
│   ├── schedule_entry.dart        # Daily schedule entry model
│   ├── collection_entry.dart      # Daily collection record model
│   └── settings.dart              # App settings model
├── database/
│   ├── database_helper.dart       # SQLite setup + schema
│   └── dao/
│       ├── customer_dao.dart      # Customer CRUD
│       ├── loan_dao.dart           # Loan CRUD + aggregation
│       ├── schedule_dao.dart       # Schedule CRUD
│       ├── collection_dao.dart     # Collection CRUD
│       └── settings_dao.dart       # Settings CRUD
├── services/
│   ├── calculation_service.dart   # All math: days, profit, interest, overdue
│   ├── schedule_service.dart      # Generate + manage schedule + collections
│   ├── sms_service.dart           # SIM-based SMS sending
│   └── backup_service.dart        # Export/Import data
├── screens/
│   ├── dashboard_screen.dart      # Home — overview stats
│   ├── customer_list_screen.dart  # All customers list
│   ├── add_customer_screen.dart   # New customer + loan form
│   ├── customer_detail_screen.dart # Customer history + active loan
│   ├── loan_detail_screen.dart    # Loan summary + schedule + collection
│   ├── daily_collection_screen.dart # Today's collections across all loans
│   ├── pre_close_screen.dart      # Pre-closure confirmation
│   └── settings_screen.dart       # All app settings
├── widgets/
│   ├── stat_card.dart             # Dashboard stat cards + status badge
│   └── schedule_entry_tile.dart   # Single schedule day row
└── utils/
    ├── constants.dart             # Colors, padding, defaults
    └── validators.dart            # Form field validators
```

## SMS Permissions

The app requires `SEND_SMS` permission. On Android 11+, the user must grant this permission when the app first tries to send an SMS. The app works fine without SMS — it just won't send messages.

## Tested Scenarios

- Basic calculation: ₹5000 → ₹6000 @ ₹100/day = 60 days, profit ₹1000, rate 0.333%/day ✓
- Non-exact division: ₹5000 → ₹5500 @ ₹90/day = 62 days, last day ₹10 ✓
- Overdue simple interest: ₹100 overdue 5 days (grace 1) = ₹1.332 interest ✓
- Grace period: No interest during grace period ✓
- Date formatting: dd/MM/yyyy ✓
- Indian currency formatting: ₹1,00,000.00 ✓
- Sunday detection ✓

## License

Private project — for personal use.
