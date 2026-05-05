# FinTrack AI

FinTrack AI adalah aplikasi pencatat keuangan pribadi berbasis Flutter. Aplikasi ini membantu pengguna mencatat pemasukan dan pengeluaran, melihat ringkasan saldo, memantau transaksi terbesar, serta bertanya ke asisten AI tentang kondisi keuangan dari data transaksi yang tersimpan.

## Fitur Utama

- Dashboard saldo, pemasukan, pengeluaran, dan rasio tabungan.
- Pencatatan transaksi pemasukan dan pengeluaran.
- Edit dan hapus transaksi.
- Filter transaksi berdasarkan tipe.
- Pencarian transaksi berdasarkan judul.
- Insight saldo dan kondisi transaksi.
- AI Assistant untuk ringkasan dan saran keuangan.
- Fallback analisis lokal saat API AI eksternal tidak tersedia.
- Penyimpanan lokal menggunakan Hive.

## Teknologi

- Flutter
- Dart
- GetX untuk routing dan state management
- Hive untuk local storage
- Dio untuk HTTP client
- Intl untuk format tanggal dan Rupiah
- Google Fonts

## Struktur Singkat

```text
lib/
  core/
    services/
    theme/
  data/
    models/
    repositories/
    services/
  modules/
    chatbot/
    dashboard/
    transaction/
  routes/
```

## AI Assistant

AI Assistant menggunakan endpoint:

```text
https://rynekoo-api.hf.space/text.gen/ai4chat
```

Aplikasi mengirim konteks transaksi ke AI setiap kali pengguna bertanya. Konteks yang dikirim meliputi total pemasukan, total pengeluaran, saldo, dan transaksi terbaru.

Jika endpoint AI mengembalikan error, aplikasi tetap memberi jawaban menggunakan analisis lokal dari data transaksi yang tersedia.

## Cara Menjalankan

Pastikan Flutter sudah terpasang, lalu jalankan:

```bash
flutter pub get
flutter run
```

Untuk menjalankan di web:

```bash
flutter run -d chrome
```

## Quality Check

Gunakan perintah berikut sebelum membuat release atau pull request:

```bash
dart format lib test
flutter analyze
flutter test
```

## Build

Build APK debug:

```bash
flutter build apk --debug
```

Build APK release per ABI:

```bash
flutter build apk --release --split-per-abi
```

Build web:

```bash
flutter build web
```

## Catatan Data

Data transaksi disimpan secara lokal di perangkat pengguna melalui Hive. Repository ini tidak menyertakan data transaksi pengguna.

## Lisensi

Project ini dibuat untuk kebutuhan pengembangan aplikasi FinTrack AI.
