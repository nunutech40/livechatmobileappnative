# Review Hermes — Auth Session, ApiClient, dan Arsitektur SDK

Tanggal: 2026-09-01  
Scope: reusable Flutter SDK `LiveChatMobileAppNative`, bukan sekadar `example/` app.

## Executive summary

Fondasi auth sudah mengarah benar: host app memiliki login/refresh token, SDK hanya meminta access token melalui `AuthProvider`, dan `TokenCoordinator` sudah mencegah refresh paralel normal.

Boundary SDK-nya masih perlu dirapikan sebelum dianggap production-ready. Prioritasnya:

1. identity SDK harus menjadi source of truth;
2. ownership `Dio` harus eksplisit;
3. repository harus dimiliki dan diekspos melalui `LiveChatSdk`, bukan dibuat host dari raw API client;
4. auth adapter partner harus dikeluarkan dari core package atau setidaknya tidak menjadi public API default.

## Koreksi review sebelumnya

Credential hardcode pada `example/lib/demo_host_app.dart` bukan finding production. File tersebut memang aplikasi contoh untuk testing/integrasi. Catatan yang tetap relevan bukan hardcoded credential-nya, melainkan identity `userId` yang masih hardcoded walaupun email login dapat berubah.

## Temuan

### P1 — Identity yang diberikan ke SDK bukan source of truth

Bukti:

- `lib/src/live_chat_sdk.dart:13-42` menyimpan `UserIdentity`, tetapi tidak membentuk atau mengekspos repository yang memakai identity tersebut.
- `lib/src/core/repositories/conversation_repository.dart:16-35` masih meminta `email` dan `userEmail` dari setiap caller.
- `example/lib/demo_host_app.dart:219` membuat `ConversationRepositoryImpl(widget.sdk.api)` sendiri.
- `example/lib/demo_host_app.dart:101` masih membuat `userId: 'demo-ryan-oksa'` secara hardcode.

Akibatnya caller dapat melakukan query dengan email berbeda dari identity saat SDK dibuat. `userEmail` juga dipakai untuk menentukan incoming/outgoing message secara lokal. Ini menciptakan dua sumber identity dan berisiko salah klasifikasi atau akses data yang tidak sesuai kontrak host.

Rekomendasi:

- `LiveChatSdk` membuat repository dengan identity yang immutable.
- Hapus `email`/`userEmail` dari method repository publik, atau inject identity-aware context ke repository.
- `UserIdentity` harus berasal dari hasil login/session host; example boleh memakai nilai demo, tetapi tidak boleh mengklaim ID dinamis jika sebenarnya hardcoded.

Target API:

```dart
sdk.conversations.getUserConversations();
sdk.conversations.getConversationMessages(conversationId);
```

### P1 — `ApiClient` dapat menutup `Dio` milik host

Bukti:

- `LiveChatSdk` menerima `Dio?` pada `lib/src/live_chat_sdk.dart:14-22`.
- `ApiClient.close()` di `lib/src/core/network/api_client.dart:80-85` selalu menjalankan `_dio.close(force: true)`.

Jika host menginjeksi `Dio` yang juga dipakai feature lain, `sdk.dispose()` dapat mematikan client milik host atau SDK lain. Ini adalah bug ownership/lifecycle, bukan sekadar detail implementasi.

Pilih satu kontrak yang tegas:

- SDK selalu membuat dan memiliki `Dio` sendiri; atau
- `ApiClient` menerima `ownsDio` dan hanya menutup instance yang dimilikinya.

Kontrak ownership tersebut juga perlu ditest untuk custom `Dio`, dispose dua kali, dan dua instance SDK yang hidup bersamaan.

### P1 — Composition root belum benar-benar dimiliki `LiveChatSdk`

`LiveChatSdk` saat ini hanya menyediakan raw `ApiClient` melalui getter `api` (`lib/src/live_chat_sdk.dart:32`). Karena `ApiClient` dan `ConversationRepositoryImpl` juga diexport dari `lib/src/livechatmobileappnative.dart`, host dapat bypass boundary SDK dan merakit data layer sendiri.

Dampaknya:

- lifecycle repository tidak dimiliki SDK;
- host terekspos ke detail internal `Dio`/repository;
- lebih mudah terjadi konfigurasi identity yang tidak konsisten;
- perubahan internal menjadi breaking change untuk consumer SDK.

Rekomendasi: jadikan `LiveChatSdk` composition root dan expose capability-level API seperti `sdk.conversations`. Jika raw client memang dibutuhkan untuk advanced integration, beri nama dan kontrak advanced yang eksplisit, bukan menjadikannya jalur utama.

### P2 — `PartnerAuthClient` terlalu spesifik dan masih berada di core/public package

Bukti: `lib/src/core/auth/partner_auth_client.dart:22-31` mengikat package ke endpoint Affiliate dev, payload `username_email`, dan `fcm_token`. File tersebut juga diexport dari public barrel.

Desain host-owned auth sudah benar: host memiliki login dan refresh token, lalu mengadaptasi hasilnya ke `AuthProvider`. Karena itu `PartnerAuthClient` sebaiknya berada di `example/` atau package adapter terpisah. Core SDK cukup memiliki `AuthProvider` dan identity contract yang netral.

Jika adapter tetap dipertahankan untuk demo, minimal:

- jangan export dari public SDK barrel;
- dokumentasikan sebagai example/dev adapter;
- jangan jadikan endpoint dev sebagai default reusable SDK behavior.

### P2 — Single-flight refresh belum menghindari refresh redundant berbasis token

`TokenCoordinator` sudah menggabungkan refresh yang benar-benar bersamaan. Namun `ApiClient` tidak menyimpan token yang dipakai request ketika menerima `401` dan tidak membandingkannya dengan token terbaru sebelum memanggil `forceRefresh`.

Pada race tertentu, dua request dapat sama-sama dikirim dengan token lama; request kedua menerima `401` setelah refresh pertama selesai dan tetap memulai refresh kedua.

Rekomendasi: kirim token gagal ke coordinator, lalu:

1. jika token host sudah berubah, gunakan token terbaru tanpa refresh ulang;
2. jika masih sama, lakukan satu `forceRefresh` single-flight;
3. retry request maksimal sekali.

### P2 — Lifecycle `dispose()` belum membatalkan seluruh pekerjaan yang dimiliki SDK

`LiveChatSdk.dispose()` menutup realtime client dan `ApiClient`, tetapi `ApiClient.close()` hanya menandai closed, membersihkan coordinator, lalu menutup `Dio`. Belum ada cancellation registry untuk request/upload yang sedang berjalan.

Minimal contract yang perlu dipastikan:

- request baru setelah dispose langsung gagal;
- request yang sedang berjalan dibatalkan;
- reconnect WebSocket berhenti;
- state in-memory session dibuang;
- token/identity user lama tidak dapat dipakai setelah user switch.

## Auth session assessment

### Yang sudah benar

- `AuthProvider` tidak menerima refresh token.
- `forceRefresh` memberi boundary yang jelas ke auth session milik host.
- `TokenCoordinator` memakai satu future refresh untuk concurrent refresh normal.
- `LiveChatSdk.dispose()` idempotent pada level SDK.
- Membuat instance SDK baru untuk user baru adalah strategi yang aman dan sederhana.

### Yang perlu ditegaskan

`AuthSession` saat ini berada di `partner_auth_client.dart` dan hanya berisi access token, email, serta `expiredAt`. Untuk core SDK, session login partner dan `UserIdentity` sebaiknya tidak dicampur. Host boleh memiliki model session sendiri lalu mengubahnya menjadi:

```dart
UserIdentity(userId: hostUser.id, email: hostUser.email)
```

dan adapter `AuthProvider` yang mengambil access token dari host session.

## Arsitektur target

```text
Host app
 ├── Login / refresh token / logout
 └── AuthProvider + UserIdentity
          ↓
LiveChatSdk  (composition root per user)
 ├── ApiClient (Dio milik SDK)
 ├── ConversationRepository (identity-aware)
 ├── Message/repository lain
 ├── RealtimeChatClient
 └── Runtime state
```

Saat logout atau user switch:

```text
host logout/user change → await sdk.dispose() → buat SDK baru untuk identity baru
```

## Verification

Dijalankan dari root package dengan FVM:

- `fvm flutter analyze` — lulus, tidak ada issue.
- `fvm flutter test` — **11 test passed**.

Test yang ada sudah memverifikasi token injection tanpa token, satu retry setelah `401`, parsing repository, dan beberapa interaksi UI. Belum ada test untuk Dio ownership, identity mismatch prevention, concurrent stale-token refresh, cancellation saat dispose, atau isolasi dua SDK instance.

## Kesimpulan

Auth provider dan refresh boundary sudah punya fondasi yang benar. Blocker arsitektural utama bukan login demo, melainkan ownership dan public boundary SDK: identity masih dapat dioverride caller, raw API client masih bocor ke host, dan ownership `Dio` belum aman. Perbaikan sebaiknya dimulai dari tiga P1 tersebut sebelum menambah endpoint atau realtime behavior lebih jauh.
