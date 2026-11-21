# KhataSmart (کھاتہ سمارٹ)

<p align="center">
  <img src="assets/icons/app_logo.png" alt="KhataSmart Logo" width="120" onerror="this.style.display='none'"/>
</p>

<p align="center">
  <b>Modern Offline-First POS, Inventory & Digital Ledger System</b><br>
  <i>Tailored for Retailers, Wholesalers, Auto Parts, Garments, Pharmacies, and Mandi Commission Agents.</i>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter" alt="Flutter Badge"/>
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart" alt="Dart Badge"/>
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-green" alt="Platform Badge"/>
  <img src="https://img.shields.io/badge/Database-SQLite%20(Offline--First)-003B57?logo=sqlite" alt="SQLite Badge"/>
  <img src="https://img.shields.io/badge/Real--Time%20Sync-Cloud%20Firestore-FFA611?logo=firebase" alt="Firestore Badge"/>
  <img src="https://img.shields.io/badge/Cloud%20Backup-Google%20Drive%2015GB-FFBA00?logo=googledrive" alt="Google Drive Badge"/>
  <img src="https://img.shields.io/badge/License-Proprietary-blue" alt="License Badge"/>
</p>

---

## 📌 Executive Summary

**KhataSmart** is a production-grade, offline-first Point of Sale (POS), Inventory Management, and Digital Ledger (Khata / Udhaar) platform engineered for the dynamic commercial ecosystem of Pakistan and emerging markets.

From neighborhood Kiryana stores to high-volume Auto Spare Parts dealers, and from Multi-branch Wholesalers to **Dana Mandi (Grain Market)** and **Fruit & Sabzi Mandi** commission houses, KhataSmart replaces cumbersome paper ledgers with an agile, reliable, and fault-tolerant digital system:
- **100% Offline-First Operation:** Instant SQLite engine ensures uninterrupted checkout and ledger posting even without internet connectivity.
- **Real-Time Live Cloud Auto-Sync:** Automated background mirroring to Firebase Cloud Firestore within seconds of any transaction.
- **Instant Cloud Auto-Restore:** Seamless data recovery on new device login or app re-installation.
- **Fast 1-Tap POS Checkout:** High-speed barcode scanning, custom units pricing (Mann, Bori, Kg, Meter, Pcs), and multi-mode payment settlement (Cash, Udhaar, Raast QR).
- **Automated Double-Entry Ledger:** Comprehensive Customer (Receivable) and Supplier (Payable) tracking with one-click WhatsApp statement sharing.
- **Hardware-Level Security:** Biometric (Fingerprint / Face ID) and 4-digit PIN terminal lock.

---

## 🏢 Supported Business Verticals & Use-Cases

KhataSmart has been architected with adaptable Units of Measurement (UOM) and flexible workflows to fit diverse business models:

| # | Business Type | Key App Capabilities | Primary Units (UOM) |
|---|---|---|---|
| **1** | **General Stores, Kiryana & Supermarts** | High-speed barcode scanner billing, loose items weighing, customer udhaar limits, and thermal receipt printing. | `Pack`, `Kg`, `Gram`, `Carton / Box`, `Pcs` |
| **2** | **Auto Spare Parts & Hardware Stores** | Part numbers in barcode/SKU, mechanic monthly khata, supplier purchase inwards with bills, and loose parts tracking. | `Pcs`, `Pair`, `Set`, `Box`, `Meter` |
| **3** | **Mobile, Accessories & Electronics** | Custom barcode sticker generator, supplier purchase tracking, and gross/net profit margin analytics. | `Pcs`, `Pack`, `Box` |
| **4** | **Garments, Cloth & Footwear Boutiques** | Measurement by meter/yard or rolls, seasonal customer credit tracking, and WhatsApp ledger reminders. | `Meter`, `Roll / Than`, `Pair`, `Pcs` |
| **5** | **Medical Stores & Pharmacies** | Supplier distributor invoices, safety reorder stock warnings, and clean itemized receipts. | `Pack`, `Pcs`, `Box` |
| **6** | **Wholesalers & Distributors (تھوک فروش)** | Multi-Store management (Godown vs. Front Shop), approved credit limits, and full A4 PDF ledger statements. | `Carton / Box`, `Bori / Bag`, `Pack` |
| **7** | **Dana Mandi / Grain Markets (غلہ منڈی)** | Commission agent (Aarhati) ledgers, farmer crop amad (Inwards), trader bori/mann invoicing, and truck challans. | `Mann (40kg)`, `Bori / Bag`, `Kg` |
| **8** | **Fruit & Sabzi Mandi (سبزی و پھل منڈی)** | Fast crate/carton/bori entry, daily cash/credit settlements, and wholesale rate management. | `Carton / Box (پیٹی)`, `Bori / Bag`, `Kg`, `Dozen` |
| **9** | **Cosmetics, Perfumes & Gift Centers** | Rush-hour checkout, multi-tender split payments (Cash + Raast), and customer loyalty logs. | `Pcs`, `Pack`, `Set` |

---

## 🌟 Core System Modules

### 🛒 1. Point of Sale (POS) Billing Engine
- **Hardware & Camera Barcode Scanning:** Powered by `mobile_scanner` with continuous scanning, auto-flash/torch, and duplicate-prevention debounce.
- **Dynamic Units of Measurement (UOM):** Native support for `Mann (40kg)`, `Bori / Bag`, `Carton / Box`, `Kg`, `Gram`, `Meter`, `Roll / Than`, `Pair`, `Pcs`, `Pack`, and `Dozen`.
- **Flexible Settlement Options:**
  - 💵 **Cash:** Built-in change return calculator with rapid denomination helpers (`+10`, `+50`, `+100`, `+500`, `+1000`).
  - 📖 **Udhaar / Khata (Credit Ledger):** 1-tap customer ledger posting with credit limit verification and overdue warnings.
  - 🔀 **Split Tender:** Collect partial cash and post the remaining balance to the customer's ledger in a single transaction.
  - 📱 **Raast Instant QR:** Dynamic payment QR for instant bank-to-bank settlement without payment gateway fees.

### 📖 2. Digital Khata & Double-Entry Ledgers
- **Unified Directory:** Categorized into Customers (*Receivables / آپ نے لینے ہیں*) and Suppliers (*Payables / آپ نے دینے ہیں*).
- **Audit-Proof Journal:** Full chronological timeline showing transaction dates, invoice references, debit/credit entries, and running net balances.
- **Credit Limit & Risk Alerts:** Set maximum credit ceilings per customer with real-time visual progress indicators and breach alerts.
- **Instant WhatsApp Invoicing:** Send itemized digital receipts and payment reminders directly to customer WhatsApp with a single tap.

### 📦 3. Smart Inventory & Stock Inward
- **Real-Time Catalog:** Wholesale cost price, retail sale price, stock quantity, safety reorder thresholds, and profit margin analysis.
- **Supplier Purchase Inward (Stock Restocking):**
  - Searchable supplier picker and dynamic product picker.
  - Itemized inward entries (quantity, purchase rate, total amount).
  - Flexible payment settlement (Paid from Cash in Hand or Added to Supplier Payable Ledger).
  - Automatically updates inventory stock counts and average cost prices.
- **Safety Reorder Alerts:** Visual badges and system notifications when product stock falls below custom reorder thresholds.

### ☁️ 4. Dual-Engine Cloud Resilience & Auto-Sync
- **Engine 1: Cloud Firestore Real-Time Mirror:**
  - Every inventory change, stock inward, sale, or ledger entry automatically schedules a background sync (2.5s debounce).
  - Automatic zero-click cloud restore upon Google/Email login or fresh application setup.
- **Engine 2: Google Drive Personal Backup:**
  - Free, encrypted backup directly into the shop owner's personal 15 GB Google Drive.
  - Zero server subscription fees and complete data ownership.

### 🖨️ 5. Printing & Digital Exports
- **Bluetooth ESC/POS Support:** Compatible with standard 58mm and 80mm wireless thermal receipt printers.
- **A4 PDF Statement Builder:** Generate clean, print-ready financial statements, stock catalogs, and customer account summaries.
- **Zero Paper Mode:** Instant digital receipt delivery via WhatsApp and Email.

### 🔒 6. Enterprise Security & Multi-Store Management
- **Terminal App Lock:** Hardware-level biometric authentication (Fingerprint on Android, Face ID / Touch ID on iOS) and 4-digit PIN.
- **Multi-Branch Switching:** Manage multiple store locations, warehouses, or mandi godowns from a single account.

---

## 🏛️ System Architecture

KhataSmart follows clean architecture principles with a decoupled, reactive MVVM (Model-View-ViewModel / Service-State-View) pattern:

```
lib/
├── main.dart                          # App bootstrap, Firebase & database init
├── firebase_options.dart              # Multi-platform Firebase credentials
│
├── models/                            # Domain Data Models (Immutable)
│   ├── product_model.dart             # Inventory items, barcode, UOM units, pricing & stock
│   ├── party_model.dart               # Customers & Suppliers with balances & limits
│   ├── order_model.dart               # Invoices, items, payment mode, split amounts
│   ├── purchase_model.dart            # Stock inward purchases, supplier reference, bill no
│   ├── shop_model.dart                # Store profile, branch settings, receipt headers
│   └── notification_model.dart        # System alerts & operational notifications
│
├── services/                          # Core System & Hardware Services
│   ├── local_database_service.dart    # SQLite DB wrapper, atomic file writes & disk sync
│   ├── cloud_sync_service.dart        # Real-time Firestore auto-sync & auto-restore
│   ├── google_drive_service.dart      # Google Drive REST API v3 backup engine
│   ├── printing_and_sharing_service.dart # ESC/POS printer adapter, PDF builder & WhatsApp
│   ├── security_service.dart          # Local authentication (Biometrics & PIN hash)
│   └── auth_service.dart              # Firebase Auth & Google Identity Provider
│
├── state/                             # Reactive State Management (Provider)
│   ├── cart_state.dart                # Active POS cart, line items, discounts & weight
│   ├── inventory_state.dart           # Catalog cache, barcode index, stock deduction
│   ├── khata_state.dart               # Parties directory, balance tracking, ledgers
│   └── shop_state.dart                # Active store session & branch switcher
│
└── views/                             # User Interface (100% Light Theme)
    ├── auth/                          # Login, PIN setup & auto-restore onboarding
    ├── inventory/                     # Catalog, Add/Edit product (UOM units), Purchase Inward
    ├── khata/                         # Party directory, Ledger details, Statement sheet
    ├── pos/                           # Barcode scanner, Cart, Checkout settlement
    ├── reports/                       # Sales revenue, Daily closing & P&L analytics
    ├── settings/                      # Multi-store, Cloud Firestore, Google Drive, Printers
    ├── notifications/                 # Real-time notification center
    └── shared_widgets/                # Custom AppBars, BottomNav, Drawer, Metric cards
```

---

## 💻 Tech Stack & Open-Source Libraries

| Category | Technology | Purpose |
| :--- | :--- | :--- |
| **Framework** | **Flutter 3.x / Dart 3.x** | Cross-platform native mobile and web compilation |
| **Database** | **SQLite (`sqflite`)** | Offline-first, ACID-compliant local database engine |
| **Cloud Database** | **Cloud Firestore** | Real-time automated background synchronization |
| **Cloud Storage** | **`googleapis` (Drive v3)** | Google Drive personal 15 GB cloud backup |
| **Cloud Auth** | **`firebase_auth` / `google_sign_in`** | Secure user identification and cloud pairing |
| **State Management** | **`provider`** | Reactive, lightweight state management with minimal rebuilds |
| **Hardware Scanner** | **`mobile_scanner`** | High-speed camera barcode and QR detection (Android / iOS) |
| **Thermal Printing** | **`printing` / `pdf`** | Native ESC/POS thermal printing & PDF generation |
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

### 3. Verify Code Health
```bash
flutter analyze
```

### 4. Run the Application
```bash
# Running on Android (Physical Device or Emulator)
flutter run

# Running on iOS (Mac & Simulator)
cd ios && pod install && cd ..
flutter run -d ios

# Running on Web (Google Chrome)
flutter run -d chrome --web-port=5000
```

---

## ⚙️ Cloud Configuration & Setup

### Firebase Authentication & Firestore Setup
1. Place your `google-services.json` inside `android/app/google-services.json`.
2. Place your `GoogleService-Info.plist` inside `ios/Runner/GoogleService-Info.plist`.
3. In the Firebase Console:
   - Enable **Authentication** (Email/Password & Google Sign-In).
   - Enable **Cloud Firestore** in Production or Test mode.

### Google Drive API Configuration (Optional Drive Backup)
If enabling manual Google Drive backups in addition to Cloud Firestore:
1. Open the [Google Cloud Console API Library](https://console.cloud.google.com/apis/library/drive.googleapis.com).
2. Select your Firebase project and click **ENABLE** for the **Google Drive API**.

---

## 📦 Building Production Releases

### Generate Optimized Android APK (Direct Sideloading)
```bash
flutter build apk --release --split-per-abi
```
The resulting APKs will be located in:
`build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`

### Generate Android App Bundle (Google Play Store)
```bash
flutter build appbundle --release
```
The release bundle will be located in:
`build/app/outputs/bundle/release/app-release.aab`

---

## 🔒 UI/UX Design System

- **100% Light Theme Guarantee:** High-contrast slate blues (`#0F172A`), clean whites (`#FFFFFF`), forest greens (`#15803D`), and crimson alerts (`#DC2626`) engineered for clear visibility under supermarket and outdoor mandi lighting.
- **Zero Screen Overflows:** Scalable `FittedBox`, `Expanded`, and responsive scroll view architectures tested across standard and compact mobile screens.
- **Enterprise Touch Ergonomics:** Minimum 48px touch targets tailored for fast thumb operation on mobile and tablet counters.
- **Clean English UI:** Professional, unified English interface throughout the application.

---

## 📄 License & Ownership

Developed with pride by the **KhataSmart Core Team**.  
All rights reserved. Dedicated to Pakistani retail, wholesale, and mandi commerce empowerment.
