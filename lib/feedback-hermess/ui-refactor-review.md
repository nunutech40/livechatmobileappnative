# Review Refactor UI Live Chat

## Scope review

Review ini khusus untuk kondisi repository saat ini, ketika prioritas masih **UI prototype dan component structure**. Review tidak menuntut implementasi REST API, auth, repository, atau WebSocket sekarang.

## Executive summary

Refactor UI sudah membawa project dari satu file besar menjadi struktur feature-based yang jauh lebih mudah dirawat. Untuk tahap UI, arahnya sudah sehat dan layak dilanjutkan.

Validasi aktual:

- `fvm flutter analyze` — **lulus, tidak ada issue**.
- `fvm flutter test` — **lulus, 5 test passed**.
- `lib/src/ui/live_chat_page.dart` sekarang sekitar **348 baris**, bukan lagi sekitar 1.555 baris.
- UI sudah dipisah ke conversation list, new conversation, chat room, articles, rating, shared components, model, dan fixture provider.

Status realistis:

> UI prototype yang sudah terstruktur baik, tetapi belum seluruhnya menjadi reusable component system dan belum memiliki data/controller layer production.

## Yang sudah benar

### 1. Pemecahan feature sudah tepat

Struktur saat ini sudah lebih mudah dipahami:

```text
lib/src/
├── models/
├── state/
└── ui/
    ├── articles/
    ├── chat_room/
    ├── conversation_list/
    ├── new_conversation/
    ├── rating/
    └── shared/
```

`LiveChatPage` sekarang lebih berperan sebagai page orchestration: memilih tab, membuka conversation, membuka new conversation, dan meneruskan callback.

### 2. Component sudah mulai callback-driven

Beberapa component sudah memiliki boundary yang baik:

- `LiveChatHeader` menerima `onClose`/`onBack`.
- `LiveChatTabs` menerima `selectedTab` dan `onTabChanged`.
- `ConversationListPage` menerima `onConversationTap` dan `onNewChat`.
- `ArticleCard` menerima `onTap`.
- `RatingPreview` menerima callback submit.
- `MessageBubble` menerima callback download.
- `AttachmentMenu` menerima callback pemilihan foto/file.

Ini sudah sesuai prinsip reusable Flutter UI: component tidak perlu mengetahui navigation atau backend host.

### 3. Model mixed content sudah membaik

`ChatMessage` sekarang memiliki:

```dart
final List<MessageContent> contents;
```

dan renderer mendukung content berurutan:

- `TextContent`;
- `AttachmentContent`;
- `UnsupportedContent`.

Ini lebih future-proof dibanding model yang hanya menyimpan satu text dan satu attachment.

### 4. State tab sudah tidak memakai satu global value bersama

`selectedTabProvider` menggunakan provider family dengan key instance. Ini lebih aman daripada satu state tab global untuk semua instance page.

Catatan: ini belum berarti seluruh state aplikasi sudah instance-scoped; yang sudah diperbaiki baru state tab.

## Temuan dan rekomendasi

### P1 — `ChatComposer` belum menjadi component mandiri sepenuhnya

Saat ini composer masih berupa method `_composer()` di `ChatRoomPage`, dan page menangani:

- membuka `ImagePicker`;
- membuka `FilePicker`;
- membaca bytes file;
- menghitung ukuran file;
- menampilkan snackbar error;
- mengubah pending attachment;
- menambahkan message baru ke list.

Referensi utama: `lib/src/ui/live_chat_page.dart`.

Untuk prototype, implementasi ini masih dapat diterima dan tidak perlu dipecah secara berlebihan. Namun jika targetnya reusable SDK UI, composer sebaiknya dipisahkan menjadi widget dengan API seperti:

```dart
ChatComposer(
  controller: textController,
  pendingAttachment: pendingAttachment,
  isSending: isSending,
  onSend: onSend,
  onAttachmentPressed: onAttachmentPressed,
  onEmojiPressed: onEmojiPressed,
  onRemoveAttachment: onRemoveAttachment,
  onPhotoSelected: onPhotoSelected,
  onFileSelected: onFileSelected,
)
```

Component hanya merender state dan memanggil callback. Page/controller boleh tetap mengorkestrasi mock behavior selama tahap UI.

Rekomendasi praktis: **extract visual composer dulu**, lalu pindahkan picker/upload ke controller atau callback handler pada fase berikutnya. Jangan memaksa membuat seluruh data layer sekarang.

### P1 — Status conversation ditentukan dari ID hardcoded

Saat ini:

```dart
final ended =
    widget.conversationId == '535' || widget.conversationId == '387';
```

Ini membuat UI mengetahui detail fixture: ID tertentu berarti conversation ended. Ketika fixture/API berubah, logic UI ikut berubah.

Lebih baik page menerima data status:

```dart
enum ConversationStatus {
  open,
  handling,
  escalated,
  resolved,
  cancelled,
}
```

Lalu gunakan:

```dart
final ended = status == ConversationStatus.resolved ||
    status == ConversationStatus.cancelled;
```

Untuk sprint UI, cukup ubah fixture agar menyediakan `status`; belum perlu API.

### P1 — Test interaction masih terlalu tipis

Test yang ada sudah mencakup flow dasar:

- render conversation tab;
- pindah ke articles;
- membuka new conversation;
- membuka conversation;
- model mixed content.

Tambahkan test terarah untuk:

- tap tab dan memastikan selected state;
- tap conversation dan memastikan chat room terbuka;
- tap back/close;
- membuka attachment menu;
- remove pending attachment;
- emoji menambah text ke composer;
- send text;
- send attachment;
- rating selection dan submit;
- article card callback;
- download callback;
- ended conversation menyembunyikan composer;
- unsupported message content.

Untuk callback, gunakan spy sederhana atau state test harness. Tidak perlu network mock pada tahap ini.

### P2 — Search artikel masih visual-only

`ArticlePage` sudah memiliki `TextField`, tetapi belum memiliki query state atau filtering.

Pilih salah satu keputusan eksplisit:

1. Implementasikan search lokal untuk fixture artikel sekarang; atau
2. Tandai sebagai planned dan jangan memberikan kesan search sudah berfungsi.

Kalau implementasi lokal dipilih, minimal dukung:

- input query;
- filter title/description;
- empty state;
- clear query.

### P2 — Responsive layout dan text scaling belum diverifikasi

UI memakai font dan padding yang cukup besar, misalnya heading sekitar 25 dan label tab sekitar 20. Ini mungkin sesuai screenshot desain, tetapi perlu diuji pada:

- lebar 320 px;
- device portrait dan landscape;
- text scale 1.3–2.0;
- title artikel atau nama file yang panjang;
- localization dengan string lebih panjang.

Prioritaskan `Flexible`, `Expanded`, `maxLines`, dan `TextOverflow.ellipsis` hanya pada lokasi yang memang membutuhkan truncation. Jangan mengandalkan fixed width untuk content yang berasal dari user/backend.

Tambahkan minimal widget test dengan `MediaQuery` ukuran kecil dan text scale besar.

### P2 — Message display model masih terlalu tipis untuk UI production

`MessageContent` sudah bagus untuk prototype, tetapi UI berikutnya kemungkinan membutuhkan:

- `messageId`;
- `createdAt` sebagai `DateTime`, bukan string display;
- sender/agent display name;
- delivery status;
- failed/sending state;
- retry callback;
- attachment URL/loading/error state;
- variant system message.

Tidak perlu menambahkan semua field sebelum dibutuhkan. Prioritas terdekat adalah mengganti string waktu hardcoded dengan data fixture `DateTime` dan formatter display.

### P2 — Tanggal dan waktu masih hardcoded

Contoh saat ini:

- `DateSeparator(label: 'today')`;
- message baru memakai `time: 'Now'`;
- pending attachment menampilkan `31 Aug 2026`.

Untuk visual mock, ini masih wajar. Namun fixture sebaiknya menyimpan data mentah:

```dart
createdAt: DateTime(...)
```

Widget atau display mapper yang menghasilkan `Today`, jam, atau tanggal terformat. Dengan begitu UI tidak membawa tanggal yang cepat basi.

### P3 — Design token belum lengkap

`LiveChatTheme` sudah menjadi awal yang baik, terutama untuk warna. Spacing, radius, typography, shadow, dan icon size masih tersebar di widget.

Secara bertahap, tambahkan:

```text
AppColors
AppSpacing
AppRadius
AppTypography
AppShadows
AppIconSizes
```

Ini penting ketika component dipakai oleh lebih dari satu screen atau host app. Tidak perlu menjadi blocker sebelum semua UI prototype selesai.

### P3 — Accessibility perlu diperluas

Sudah ada beberapa tooltip/semantics, terutama pada tab, rating, header, dan download. Lanjutkan dengan:

- semantic label untuk icon add, emoji, send, remove;
- memastikan tombol memiliki ukuran tap target yang layak;
- status selected tab dapat dibaca screen reader;
- focus order composer masuk akal;
- warna disabled memiliki kontras yang cukup;
- jangan menyampaikan status hanya melalui warna.

Tambahkan accessibility guideline test bila komponen mulai stabil.

### P3 — Warning SVG pada test

Test lulus, tetapi output masih menampilkan:

```text
unhandled element <style/>; Picture key: Svg loader
```

Ini bukan kegagalan test, tetapi asset SVG atau loader-nya perlu diperiksa. Pastikan warning tidak menutupi error rendering yang sebenarnya, terutama jika asset tersebut dipakai sebagai avatar/icon utama.

## Koreksi terhadap prinsip arsitektur sebelumnya

Review ini tidak menyarankan bahwa semua logic di widget adalah kesalahan.

Dalam Flutter, page memang lazim mengorkestrasi:

- navigation;
- local UI state kecil;
- callback antar-component;
- fixture state untuk prototype.

Yang perlu dihindari adalah component reusable mengetahui hal-hal yang bukan tanggung jawab visualnya, seperti Dio, endpoint, auth token, atau lifecycle upload production.

Untuk tahap sekarang, pembagian yang cukup sehat adalah:

```text
LiveChatPage
  ├── mengatur tab/navigation dan fixture flow
  ├── ChatRoomPage
  │     ├── mengatur local composer state sementara
  │     └── meneruskan callback ke component
  └── reusable UI components
        ├── menerima display state
        └── tidak memanggil API/backend langsung
```

Nanti ketika backend mulai dikerjakan:

```text
UI component
    ↓ callbacks
Page/controller/state notifier
    ↓
Repository
    ↓
ApiClient
```

Jadi `ImagePicker` dan `FilePicker` tidak harus langsung dipindahkan ke repository. Keduanya lebih cocok berada di application/controller layer atau service khusus upload, bukan di reusable visual component.

## Prioritas pengerjaan yang direkomendasikan

### Tahap UI sekarang

1. Extract `_composer()` menjadi `ChatComposer` callback-driven.
2. Pisahkan timeline/message list menjadi `ChatTimeline` bila file chat room terus membesar.
3. Ganti status berbasis ID dengan status pada fixture/model.
4. Tambahkan interaction tests utama.
5. Tambahkan responsive test untuk width kecil dan text scale besar.
6. Putuskan search artikel: implementasi lokal atau explicitly planned.
7. Rapikan design tokens setelah component stabil.

### Tahap sebelum integrasi backend

1. Pisahkan display model dari DTO/API model.
2. Buat controller/state boundary.
3. Definisikan repository interface dan fake repository.
4. Baru buat `ApiClient`, auth, upload, dan WebSocket sesuai review TRD terpisah.

## Acceptance criteria UI

- `LiveChatPage` tidak menjadi tempat seluruh visual component didefinisikan.
- `ChatComposer` dapat dipakai dengan fake callback tanpa picker/network asli.
- Component tidak memanggil endpoint, Dio, auth provider, atau global API client.
- Conversation status tidak ditentukan dari magic conversation ID.
- Text, attachment, rating, article, back, close, dan download memiliki callback/test yang jelas.
- Layout tidak overflow pada lebar kecil dan text scale besar.
- Message content tetap mendukung ordered mixed content dan unsupported fallback.
- Fixture tidak memakai tanggal display hardcoded untuk behavior yang akan dites.
- `fvm flutter analyze` dan seluruh test tetap lulus.

## Kesimpulan

Refactor ini sudah merupakan kemajuan nyata untuk fokus UI. Tidak perlu menghentikan pekerjaan UI hanya karena auth/API layer belum ada.

Fokus terdekat yang paling bernilai adalah:

1. membuat composer benar-benar reusable melalui callback;
2. menghapus coupling status ke magic ID;
3. memperbanyak interaction dan responsive tests.

Setelah tiga hal tersebut stabil, barulah boundary controller/repository disiapkan untuk integrasi backend.

## Follow-up: `ApiClient`, `APIClass`, dan global client

### Koreksi terhadap rekomendasi sebelumnya

Jangan mengartikan rekomendasi “jangan membuat global `APIClass`” sebagai larangan terhadap semua singleton atau semua object yang dibuat sekali.

Dalam mobile app, satu network client yang hidup pada scope aplikasi adalah pola yang umum dan valid:

- iOS sering memakai `URLSession` atau network client app-scoped;
- Android sering memakai satu `OkHttpClient` dan Retrofit melalui dependency injection;
- Flutter sering membuat satu `Dio` melalui Riverpod, GetIt, atau composition root.

Yang perlu dihindari adalah **global mutable API client** yang memiliki static state dan dipanggil dari mana saja, misalnya:

```dart
class APIClass {
  static final Dio dio = Dio();

  static Future<Response<dynamic>> get(String path) {
    return dio.get(path);
  }
}
```

Masalahnya bukan karena object tersebut singleton semata, tetapi karena dependency, konfigurasi, auth, interceptor, dan lifecycle menjadi tersembunyi:

- base URL dan environment sulit diisolasi;
- token atau interceptor user lama berisiko terbawa setelah logout/user switch;
- sulit menjalankan dua konfigurasi SDK secara bersamaan;
- sulit dites tanpa network asli;
- `dispose`, cancellation, dan shutdown WebSocket tidak memiliki owner yang jelas;
- perubahan konfigurasi global dapat memengaruhi feature lain secara tidak terduga.

### Pola yang direkomendasikan

Gunakan object biasa yang dibuat oleh composition root dan di-inject ke repository/controller:

```text
LiveChatSdk / app composition root
        ↓
ApiClient (satu instance pada scope yang jelas)
        ↓
Dio + AuthInterceptor
        ↓
ConversationRepository / MessageRepository
        ↓
Controller atau state notifier
        ↓
UI
```

Contoh minimum:

```dart
final class ApiClient {
  ApiClient({
    required Dio dio,
    required AuthProvider authProvider,
  })  : _dio = dio,
        _authProvider = authProvider;

  final Dio _dio;
  final AuthProvider _authProvider;

  Future<Response<T>> get<T>(String path) {
    return _dio.get<T>(path);
  }

  Future<void> close() async {
    _dio.close(force: true);
  }
}
```

Nama `APIClass` sendiri tidak otomatis salah. Top-level helper juga tidak otomatis salah jika hanya berupa fungsi murni tanpa state tersembunyi. Namun nama `ApiClient` biasanya lebih jelas karena menunjukkan bahwa object ini memiliki dependency dan lifecycle.

### Bedakan app-scoped dan SDK-scoped

Untuk aplikasi internal yang hanya memiliki satu user aktif dan satu environment, satu `ApiClient` app-scoped melalui dependency injection adalah pilihan yang lazim.

Untuk LiveChat yang dikemas sebagai reusable SDK, instance-scoped lebih aman:

```dart
final sdk = LiveChatSdk(
  config: config,
  authProvider: hostAuthProvider,
  identity: identity,
);
```

`LiveChatSdk` menjadi owner dari `ApiClient`, repository, runtime state, dan koneksi realtime. Saat SDK di-dispose, resource miliknya dapat ditutup tanpa memengaruhi network client feature lain di host app.

Ini tidak berarti setiap request harus membuat `Dio` baru. Sebaliknya, satu `Dio` sebaiknya dipakai ulang selama lifetime owner-nya, dengan timeout, interceptor, dan base URL yang dikonfigurasi melalui dependency injection.

### Auth tetap milik host app

SDK tidak boleh memiliki refresh token atau mengimplementasikan login host. SDK hanya meminta access token melalui adapter:

```dart
abstract interface class AuthProvider {
  Future<String?> getAccessToken({
    bool forceRefresh = false,
  });
}
```

Flow HTTP yang direkomendasikan:

1. Ambil access token normal dari `AuthProvider`.
2. Inject sebagai `Bearer` token.
3. Jika response `401`, minta token dengan `forceRefresh: true`.
4. Retry request maksimal satu kali.
5. Jika tetap gagal, kembalikan typed `AuthException` dan jangan retry tanpa batas.

Jika beberapa request menerima `401` bersamaan, gunakan single-flight refresh: hanya satu operasi refresh berjalan, request lain menunggu hasilnya lalu masing-masing retry satu kali. Ini penting agar SDK tidak memicu refresh storm.

### Error dan retry policy

Boundary API perlu memetakan error ke tipe yang dapat dipahami controller, bukan membocorkan seluruh detail Dio ke UI:

```dart
sealed class ApiException implements Exception {
  const ApiException();
}

final class AuthException extends ApiException {
  const AuthException();
}

final class NetworkException extends ApiException {
  const NetworkException();
}

final class ServerException extends ApiException {
  const ServerException(this.statusCode);

  final int statusCode;
}
```

Policy minimal:

- `401`: refresh satu kali, lalu `AuthException`;
- `403`: jangan retry;
- `404`: map sebagai not found;
- `409`/`422`: map sebagai conflict/validation error;
- `429`: hormati `Retry-After` bila tersedia;
- timeout/network: retry terbatas hanya untuk operasi yang aman;
- send/create message: pertimbangkan idempotency key agar retry tidak menggandakan pesan.

### Session dan lifecycle

Jangan memakai satu class generik `SessionManager` untuk tiga konsep berbeda:

| Session | Owner | Isi |
|---|---|---|
| Auth session | Host app | login, access token, refresh token, logout |
| Conversation session | Backend/domain | conversation ID, status, history, rating |
| Runtime session | SDK | WebSocket, active conversation, pending upload, controller state |

Pada logout atau pergantian user, lifecycle yang diharapkan:

```text
host logout / user change
        ↓
sdk.dispose()
        ↓
close WebSocket
cancel request/upload/reconnect
clear in-memory state
discard pending message
        ↓
buat SDK baru untuk identity berikutnya
```

Pendekatan dispose lalu membuat instance baru lebih sederhana dan lebih aman daripada mengganti token/identity pada object lama secara parsial. Jika produk membutuhkan instance yang tetap hidup, sediakan API eksplisit seperti `resetForUser`, dengan operasi reset yang atomik dan teruji.

### Scope yang sesuai untuk fase UI sekarang

Karena project masih fokus UI, belum perlu langsung membangun auth refresh, Dio, dan WebSocket. Yang perlu disiapkan lebih dulu adalah boundary yang dapat dipakai fake:

```dart
abstract interface class ConversationRepository {
  Future<List<Conversation>> getConversations();
}
```

UI/controller dapat memakai `FakeConversationRepository` untuk fixture. Implementasi `ApiClient` baru masuk ketika kontrak endpoint dan TRD sudah final.

### Acceptance criteria API layer

- Tidak ada static mutable token, Dio, repository, WebSocket, atau feature state.
- App-scoped singleton melalui dependency injection diperbolehkan untuk host app.
- Untuk SDK, `ApiClient` dimiliki oleh instance `LiveChatSdk`.
- Dua instance SDK dapat hidup dengan konfigurasi berbeda tanpa saling berbagi auth atau state.
- Semua protected request mengambil token melalui `AuthProvider`.
- Concurrent `401` hanya menghasilkan satu refresh operation.
- Setiap request retry maksimal satu kali setelah refresh.
- `dispose()` menutup resource dan membersihkan runtime state.
- UI tidak memanggil Dio, endpoint, atau API client secara langsung.
- Repository dapat dites menggunakan fake tanpa network asli.
- Test mencakup token injection, refresh `401`, concurrent refresh, retry limit, error mapping, logout cleanup, dan isolasi dua SDK instance.

Kesimpulan yang perlu dipakai oleh AI coding agent:

> Jangan melarang singleton secara absolut. Larang global mutable state yang menyembunyikan dependency dan lifecycle. Gunakan `ApiClient` sebagai object yang di-inject, dengan scope sesuai owner: app-scoped untuk aplikasi biasa, SDK-scoped untuk reusable LiveChat SDK.
