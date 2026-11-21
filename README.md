# KhataSmart (کھاتہ سمارٹ)

<p align="center">
  <img src="assets/icons/app_logo.png" alt="KhataSmart Logo" width="120" onerror="this.style.display='none'"/>
</p>

<p align="center">
  <b>Modern Offline-First POS & Digital Ledger for Retailers & Wholesalers</b><br>
  <i>Empowering retail shops, supermarkets, and distributors with blazing-fast billing, smart inventory tracking, and double-entry Khata management.</i>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter" alt="Flutter Badge"/>
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart" alt="Dart Badge"/>
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-green" alt="Platform Badge"/>
  <img src="https://img.shields.io/badge/Database-SQLite%20(Offline--First)-003B57?logo=sqlite" alt="SQLite Badge"/>
  <img src="https://img.shields.io/badge/Cloud%20Backup-Google%20Drive%2015GB-FFBA00?logo=googledrive" alt="Google Drive Badge"/>
  <img src="https://img.shields.io/badge/License-Proprietary-blue" alt="License Badge"/>
</p>

---

## 📌 Executive Summary

**KhataSmart** is a production-grade, offline-first Point of Sale (POS) and Customer/Supplier Ledger (Khata / Udhaar) application engineered specifically for the fast-paced retail ecosystem of Pakistan and emerging markets.

Retail businesses frequently suffer from slow billing lines, lost udhaar records, inaccurate manual math, and unstable internet connections. **KhataSmart completely eliminates these bottlenecks:**
- **Zero Internet Required:** Runs 100% offline on a high-performance local SQLite database engine.
- **Fast 1-Tap POS Checkout:** Camera barcode scanning, loose items weighing, and multi-mode payment settlement (Cash, Udhaar, Raast QR).
- **Automated Ledger Sync:** Every credit transaction posts directly to the customer's ledger with instant WhatsApp bill sharing.
- **Data Protection:** Personal 15 GB Google Drive cloud backup and hardware-level biometric PIN locking.

---

## 🌟 Key Features

### 🛒 1. Point of Sale (POS) Billing Engine
- **Instant Barcode & QR Scanning:** Integrated device camera scanner (`mobile_scanner`) with auto-torch, continuous scanning mode, and audible detection feedback.
- **Loose Items & Produce Pricing:** Built-in gram-to-kilogram conversion and dynamic price steppers for loose grains, vegetables, spices, and fluids.
- **Real-Time Cart Calculations:** Automatic gross total, line-item discounts, custom bill discounts, net payable, and customer savings badges.
- **Flexible Checkout Settlement Modes:**
  - 💵 **Cash (Direct Drawer):** Instant change-to-return calculator with quick denomination chips (`+10`, `+50`, `+100`, `+500`, `+1000`).
  - 📖 **Udhaar / Khata (Credit Ledger):** 1-tap customer ledger posting. Checks credit limits in real time and warns before approving over-limit sales.
  - 🔀 **Split Billing:** Collect partial cash at the counter and post the remaining balance to the customer's credit ledger.
  - 📱 **Raast Instant QR:** Dynamic Raast digital payment QR code for zero-fee instant mobile transfers.

### 📖 2. Digital Khata & Party Ledgers (Double-Entry Accounting)
- **Customer & Supplier Accounts:** Unified directory categorized by Customers (Receivables) and Suppliers (Payables).
- **Double-Entry Transaction Journal:** Transparent *You Gave (Debit / ادھار دیا)* and *You Got (Credit / وصول کیا)* ledger timeline with running balances.
- **Credit Limit & Risk Monitoring:** Set individual credit limits per customer with real-time visual progress bars and limit breach alerts.
- **Instant WhatsApp Ledger Reminders:** One-tap sharing of detailed payment reminder statements and itemized bills via WhatsApp (`wa.me`).

### 📦 3. Smart Inventory & Stock Control
- **Product Catalog Management:** Barcode / SKU lookup, category filtering, wholesale cost, retail sales price, and profit margin analysis.
- **Purchase Inward (Stock Restocking):** Restock inventory directly by scanning supplier goods, updating cost prices, and recording supplier payable balances in one seamless flow.
- **Safety Stock & Expiry Alerts:** Real-time low stock badges, out-of-stock reconciliation, and expiry date monitoring for perishable goods.
- **Wholesale vs. Retail Margins:** Automatic margin calculation (`% Profit Margin = ((Sale - Cost) / Sale) * 100`) to guarantee profitability.

### 🖨️ 4. Thermal Printing & Digital Receipts
- **Bluetooth ESC/POS Support:** Compatible with industry-standard 58mm and 80mm wireless thermal receipt printers.
- **A4 PDF Statement Generation:** Generate and download professional financial statements, stock catalogs, and customer account summaries.
- **Zero Paper Mode:** Send clean digital invoices via WhatsApp and Email directly from the POS checkout screen.

### 🔒 5. Enterprise Security & Cloud Safeguards
- **Terminal App Lock:** Secure your cash drawer and ledgers with biometric authentication (Fingerprint on Android, Face ID / Touch ID on iOS) and 4-digit master PIN.
- **Google Drive Backup:** Free, encrypted cloud backup directly into the shop owner's personal 15 GB Google Drive storage — zero costly server subscriptions.
- **Multi-Store Management:** Seamlessly manage and switch between multiple shop branches or warehouses from a single device.

---

## 🏛️ System Architecture

KhataSmart follows clean architecture principles with a decoupled, reactive MVVM (Model-View-ViewModel / Service-State-View) design:

```
lib/
├── main.dart                          # App bootstrap, Firebase & database init
├── firebase_options.dart              # Multi-platform Firebase credentials
│
├── models/                            # Domain Data Models (Immutable)
│   ├── product_model.dart             # Inventory items, barcode, pricing & stock
│   ├── party_model.dart               # Customers & Suppliers with balances & limits
│   ├── order_model.dart               # Invoices, items, payment mode, split amounts
│   ├── shop_model.dart                # Store profile, tax rates, receipt headers
│   └── notification_model.dart        # System alerts & operational notifications
│
├── services/                          # Core System & Hardware Services
│   ├── local_database_service.dart    # SQLite DB wrapper, schema migrations, disk flush
│   ├── google_drive_service.dart      # Google Drive REST API v3 backup engine
│   ├── notification_service.dart      # Real-time event & background notification bus
│   ├── printing_and_sharing_service.dart # ESC/POS printer adapter, PDF builder & WhatsApp
│   ├── security_service.dart          # Local authentication (Biometrics & PIN hash)
│   └── auth_service.dart              # Firebase Auth & Cloud Firestore sync
│
├── state/                             # Reactive State Management (Provider)
│   ├── cart_state.dart                # Active POS cart, line items, discounts & weight
│   ├── inventory_state.dart           # Catalog cache, barcode index, stock deduction
│   ├── khata_state.dart               # Parties directory, balance tracking, ledgers
│   └── shop_state.dart                # Active store session & branch switcher
│
└── views/                             # User Interface (100% Light Theme)
    ├── auth/                          # Login, PIN setup & store registration
    ├── inventory/                     # Catalog, Add/Edit product, Purchase Inward
    ├── khata/                         # Party directory, Ledger details, Statement sheet
    ├── pos/                           # Barcode scanner, Cart, Checkout settlement
    ├── reports/                       # Sales revenue, Daily closing & P&L analytics
    ├── settings/                      # Multi-store, Google Drive, Bluetooth printer
    ├── notifications/                 # Real-time notification center
    └── shared_widgets/                # Custom AppBars, BottomNav, Drawer, Metric cards
```

---

## 💻 Tech Stack & Open-Source Libraries

| Category | Technology | Purpose |
| :--- | :--- | :--- |
| **Framework** | **Flutter 3.x / Dart 3.x** | Cross-platform native mobile and web compilation |
| **Database** | **SQLite (`sqflite`)** | Offline-first, ACID-compliant local structured database |
| **State Management** | **`provider`** | Reactive, lightweight state management with minimal rebuilds |
| **Hardware Scanner** | **`mobile_scanner`** | High-speed camera barcode and QR detection (Android / iOS) |
| **Thermal Printing** | **`printing` / `pdf`** | Native ESC/POS thermal printing & PDF generation |
| **Cloud Storage** | **`googleapis` (Drive v3)** | Google Drive personal 15 GB cloud backup |
| **Cloud Auth** | **`firebase_auth` / `google_sign_in`** | Secure user identification and cloud pairing |
| **Biometrics** | **`local_auth` / `crypto`** | Fingerprint, Face ID, and SHA-256 PIN security |
| **External Sharing** | **`url_launcher` / `share_plus`** | Direct WhatsApp bill sending and OS sharing |
| **Localization** | **`intl`** | Number, currency (PKR), and datetime formatting |

---

## 🚀 Getting Started

### Prerequisites
1. **Flutter SDK:** Version `3.22.0` or higher ([Install Flutter](https://docs.flutter.dev/get-started/install)).
2. **Android Studio / VS Code** with Flutter and Dart extensions.
3. **Java Development Kit (JDK):** Version 17+.
4. **Git** installed on your system.

### 1. Clone the Repository
```bash
git clone https://github.com/FahadMustafa001/KhataSmart.git
cd KhataSmart
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Run the App

#### Running on Android (Physical Device or Emulator - Recommended)
Connect your Android phone via USB (with USB Debugging enabled):
```bash
flutter run
```

#### Running on iOS (Mac & Simulator)
```bash
cd ios && pod install && cd ..
flutter run -d ios
```

#### Running on Web (Google Chrome)
When running on Web with Google Drive OAuth enabled, specify a fixed port:
```bash
flutter run -d chrome --web-port=5000
```

---

## ⚙️ Configuration & Credentials

### Android Firebase Setup
Place your `google-services.json` file inside:
```
android/app/google-services.json
```

### iOS Firebase & Google Sign-In Setup
Place your `GoogleService-Info.plist` file inside:
```
ios/Runner/GoogleService-Info.plist
```
*Note: Camera (`NSCameraUsageDescription`), Bluetooth (`NSBluetoothAlwaysUsageDescription`), and Face ID (`NSFaceIDUsageDescription`) permissions are already configured in `ios/Runner/Info.plist`.*

### Web OAuth Configuration (Google Drive Backup)
If testing Google Drive connection on Chrome Web:
1. Open [Google Cloud Console Credentials](https://console.cloud.google.com/apis/credentials).
2. Select your Firebase project (`smartkhata-19806`).
3. Under **OAuth 2.0 Client IDs**, select the Web Client.
4. Add `http://localhost:5000` to **Authorized JavaScript origins**.

---

## 📦 Building Production Releases

### Generate Android APK (Direct Install)
```bash
flutter build apk --release --split-per-abi
```
The optimized APKs will be generated in:
`build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`

### Generate Android App Bundle (Google Play Store)
```bash
flutter build appbundle --release
```
The bundle will be generated in:
`build/app/outputs/bundle/release/app-release.aab`

---

## 🔒 Design System & UI Principles

- **100% Light Theme Guarantee:** Engineered with high-contrast slate blues (`#0F172A`), clean whites (`#FFFFFF`), forest greens (`#15803D`), and crimson alerts (`#DC2626`) to ensure crystal-clear visibility under harsh supermarket and outdoor retail lighting.
- **Zero Distracting Emojis:** All UI components use crisp, scalable vector icons (`Icons.*`) for a sleek, enterprise-grade finish.
- **Large Touch Targets:** Minimum 48px touch targets tailored for fast thumb operation on mobile and tablet counters.
- **Bilingual Context:** Natural integration of Urdu retail terminology (*ادھار / Khata, وصولی / Got, جمع / Gave*) alongside English for effortless staff adoption.

---

## 🤝 Contributing

Contributions, bug reports, and feature suggestions are welcome!
1. Fork the Project.
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`).
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`).
4. Push to the Branch (`git push origin feature/AmazingFeature`).
5. Open a Pull Request.

---

## 📄 License & Ownership

Developed with pride by the **KhataSmart Core Team**.  
All rights reserved. Designed for Pakistani retail empowerment.
