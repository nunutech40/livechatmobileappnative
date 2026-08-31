# Review TRD: Auth Session, Runtime Session, dan API Client

## Tujuan dokumen

Dokumen ini adalah tanggapan arsitektural terhadap `LIVE_CHAT_TRD.md`, khususnya:

- ownership auth/session;
- desain `AuthProvider`;
- bentuk `APIClass`/`ApiClient`;
- lifecycle logout dan pergantian user;
- boundary REST, repository, dan WebSocket;
- rekomendasi implementasi untuk coding agent.

Dokumen ini ditulis berdasarkan TRD/PRD dan kondisi repository saat ini.

## Executive summary

Arah dasar TRD sudah benar:

1. Auth/login dimiliki aplikasi host.
2. SDK hanya meminta access token dari host.
3. REST API menjadi source of truth.
4. WebSocket hanya untuk realtime event.
5. Satu instance `Dio` dipakai per instance SDK.
6. Conversation ID adalah identitas session bisnis.

Namun desainnya belum cukup detail untuk production, terutama pada:

- refresh token dan respons HTTP `401`;
- concurrent request yang sama-sama menerima `401`;
- lifecycle logout dan user switch;
- perbedaan auth session, conversation session, dan runtime SDK session;
- aturan retry, cancellation, dan idempotency;
- ownership `identityProvider` versus immutable identity;
- public API yang dapat dipakai host tanpa mengimpor `src`.

Kesimpulan utama: jangan membuat `APIClass` sebagai global function, static mutable class, atau singleton global. Gunakan `ApiClient` sebagai object instance-scoped yang dibuat oleh `LiveChatSdk` melalui dependency injection.

## Koreksi terhadap review sebelumnya

Review sebelumnya menyebut `ChatMessage` hanya mendukung satu attachment. Itu sudah tidak benar untuk kondisi repository sekarang.

`lib/src/models/chat_models.dart` sudah menggunakan:

```dart
final List<MessageContent> contents;
```

dan mendukung ordered content melalui `TextContent`, `AttachmentContent`, serta `UnsupportedContent`. Temuan tersebut dihapus dari rekomendasi ini.

## Kondisi repository saat ini

TRD mengharapkan struktur core seperti API client, auth, errors, repositories, dan websocket. Tetapi repository saat ini baru memiliki UI/model/fixture.

Bukti utama:

- `pubspec.yaml` belum memiliki dependency `dio`, `web_socket`, `json_serializable`, `build_runner`, `mocktail`, atau `flutter_secure_storage`.
- Belum ada directory `lib/src/core/api`, `lib/src/core/auth`, `lib/src/core/errors`, `lib/src/core/repositories`, atau `lib/src/core/websocket`.
- `lib/src/state/live_chat_fixture_providers.dart` masih menyediakan conversation/message hardcoded.
- `lib/src/ui/live_chat_page.dart` masih membaca fixture, menyimpan `_messages`, dan menjalankan picker/upload-like behavior di widget.
- Public export saat ini masih mengekspos komponen UI dan model fixture; belum ada `LiveChatSdk`, `LiveChatConfig`, `AuthProvider`, atau `ApiClient`.

Dengan demikian pekerjaan ini bukan sekadar mengganti nama `APIClass`. Perlu dibuat boundary arsitektur terlebih dahulu, baru UI dihubungkan ke data layer.

## 1. Ownership auth yang direkomendasikan

### Host app memiliki auth session

Host app bertanggung jawab atas:

- login dan logout;
- access token;
- refresh token;
- refresh policy;
- user identity yang sedang aktif;
- perubahan user/account;
- penyimpanan credential sesuai security policy aplikasi.

SDK tidak boleh:

- meminta username/password;
- menyimpan refresh token secara default;
- membuat flow OAuth milik host;
- mengasumsikan library auth tertentu;
- menulis token ke log;
- menganggap token yang diberikan saat konstruktor selalu valid.

### SDK memiliki akses token secara ephemeral

SDK meminta token tepat sebelum request protected dibuat. Token tidak perlu disimpan lebih lama dari yang diperlukan oleh client/interceptor.

## 2. Kontrak `AuthProvider`

Kontrak TRD saat ini:

```dart
abstract interface class AuthProvider {
  Future<String?> getAccessToken();
}
```

Kontrak ini belum menjelaskan cara SDK meminta token baru setelah token expired. Rekomendasi minimal:

```dart
abstract interface class AuthProvider {
  Future<String?> getAccessToken({
    bool forceRefresh = false,
  });
}
```

Makna parameter:

- `forceRefresh: false`: kembalikan access token yang saat ini valid/cached di host.
- `forceRefresh: true`: host wajib mencoba memperoleh token baru sesuai mekanisme auth-nya.
- hasil `null`: tidak ada authenticated user/token; SDK harus menghasilkan typed `AuthException`.

Refresh token tetap tidak pernah masuk ke SDK. SDK hanya meminta hasil akhirnya berupa access token.

Contoh adapter host:

```dart
final class HostAuthProvider implements AuthProvider {
  HostAuthProvider(this.session);

  final HostSession session;

  @override
  Future<String?> getAccessToken({bool forceRefresh = false}) {
    return session.getValidAccessToken(forceRefresh: forceRefresh);
  }
}
```

## 3. Aturan HTTP `401` dan refresh

Flow yang direkomendasikan:

```text
request
  ↓
ambil access token biasa
  ↓
kirim request
  ├── sukses → return response
  └── 401 → satu kali force refresh melalui host
                 ↓
             retry request satu kali
                 ├── sukses → return response
                 └── 401 → AuthException
```

Aturan wajib:

1. Request tanpa token tidak boleh dikirim sebagai request authenticated.
2. `401` hanya boleh memicu retry maksimal satu kali untuk request tersebut.
3. Jika refresh gagal atau token tetap `null`, lempar `AuthException`.
4. Jika retry kedua kembali `401`, jangan retry lagi.
5. Jangan retry mutation tanpa idempotency protection secara tidak terbatas.

### Single-flight refresh

Jika banyak request menerima `401` bersamaan, SDK tidak boleh memanggil refresh host berkali-kali.

```text
Request A ─┐
Request B ─┼─ 401 ─► satu operasi force refresh ─► retry A/B/C masing-masing satu kali
Request C ─┘
```

Implementasikan single-flight refresh pada `AuthInterceptor` atau `TokenCoordinator`. Request berikutnya menunggu `Future` refresh yang sedang berjalan.

Catatan penting: interceptor harus memastikan retry memakai token hasil refresh terbaru, bukan token lama yang tersimpan di closure request.

## 4. `APIClass` jangan global

Hindari desain berikut:

```dart
APIClass.get('/conversations');
APIClass.post('/messages', body);
```

atau:

```dart
class APIClass {
  static final Dio dio = Dio();
}
```

Masalahnya:

- token dan interceptor mudah terbawa antar-user;
- base URL antar-environment sulit diisolasi;
- dua instance SDK dengan konfigurasi berbeda tidak aman;
- lifecycle `dispose` tidak jelas;
- testing membutuhkan network/global reset;
- logging dan retry policy menjadi state global tersembunyi;
- host yang menjalankan beberapa feature/tenant dapat terjadi credential leakage.

Nama `APIClass` boleh dipakai jika sudah menjadi konvensi project, tetapi bentuknya harus object biasa. Nama yang lebih jelas adalah `ApiClient`.

## 5. Bentuk `ApiClient` yang direkomendasikan

`LiveChatSdk` menjadi composition root. Semua dependency utama dibuat per instance:

```text
LiveChatSdk
 ├── ApiClient
 │    └── Dio
 │         └── AuthInterceptor
 ├── ConversationRepository
 ├── MessageRepository
 ├── UploadRepository
 ├── RealtimeChatClient
 └── LiveChatRuntime
```

Contoh boundary:

```dart
final class LiveChatSdk {
  LiveChatSdk({
    required this.config,
    required AuthProvider authProvider,
    required UserIdentity identity,
    Dio? dio,
  }) : _apiClient = ApiClient(
         dio ?? Dio(config.toBaseOptions()),
         authProvider: authProvider,
       ),
       identity = identity;

  final LiveChatConfig config;
  final UserIdentity identity;
  final ApiClient _apiClient;

  late final ConversationRepository conversations =
      ConversationRepositoryImpl(_apiClient);
  late final MessageRepository messages =
      MessageRepositoryImpl(_apiClient);

  Future<void> dispose() async {
    await _apiClient.close();
  }
}
```

Contoh public API yang lebih realistis:

```dart
final sdk = LiveChatSdk(
  config: LiveChatConfig(
    restBaseUrl: 'https://api.example.com/live-chat-service',
    websocketUrl: 'wss://api.example.com/live-chat-service',
  ),
  authProvider: hostAuthProvider,
  identity: UserIdentity(
    userId: user.id,
    email: user.email,
  ),
);

await sdk.dispose();
```

`Dio` dapat di-inject sebagai constructor parameter untuk test, tetapi production default tetap dibuat internal per `LiveChatSdk` instance.

## 6. Tanggung jawab tiap layer

| Komponen | Tanggung jawab | Tidak boleh dilakukan |
|---|---|---|
| `LiveChatSdk` | composition root, public entry point, lifecycle | menyimpan static mutable state |
| `LiveChatConfig` | base URL, timeout, retry/logging options | menyimpan token |
| `AuthProvider` | adapter token host dan force refresh | login/menyimpan refresh token SDK |
| `AuthInterceptor` | bearer injection, single-flight refresh, retry limit | memahami UI atau conversation |
| `ApiClient` | request generik, cancellation, parsing dasar, error mapping | mengandung endpoint-specific business logic |
| Repository | endpoint, DTO parsing, domain mapping | memanggil widget/snackbar |
| Use case/controller | orchestration dan state transition | mengakses global Dio |
| `RealtimeChatClient` | connect, auth handshake, subscribe, reconnect, event stream | menjadi database/history source of truth |
| UI | render state dan kirim intent | memanggil Dio/WebSocket langsung |

Repository harus menerima `ApiClient` melalui constructor:

```dart
final class ConversationRepositoryImpl
    implements ConversationRepository {
  ConversationRepositoryImpl(this._api);

  final ApiClient _api;

  @override
  Future<ConversationPage> getUserConversations({
    int limit = 20,
    String? lastId,
  }) async {
    final response = await _api.get<Map<String, dynamic>>(
      '/api/v1/conversations/user',
      queryParameters: {
        'limit': limit,
        if (lastId != null) 'last_id': lastId,
      },
    );
    return ConversationPageDto.fromJson(response).toDomain();
  }
}
```

UI/controller tidak boleh mengelola `last_id` secara langsung. Repository mengembalikan page + next cursor sesuai TRD.

## 7. Tiga arti “session” harus dipisahkan

### Auth session

Milik host app:

```text
login
access token
refresh token
logout
user identity
```

### Conversation session

Milik backend/domain:

```text
conversation.id
open/handling/escalated
resolved/cancelled
message history
rating
```

`conversation.id` tetap sama ketika WebSocket reconnect. Reconnect tidak membuat conversation baru.

### Runtime SDK session

Milik instance SDK selama aktif:

```text
isConnected
activeConversationId
loading state
pending upload
unread in-memory state
WebSocket subscription
```

Jangan memakai class generik bernama `SessionManager` untuk tiga konsep tersebut. Gunakan nama yang eksplisit seperti:

```text
AuthProvider
ConversationSession / Conversation
LiveChatRuntime
```

## 8. Logout dan user switch

TRD sudah menyebut cache memory harus dibuang saat logout, tetapi belum mendefinisikan public lifecycle API.

### Rekomendasi utama: satu instance untuk satu user identity

Saat logout atau user berganti:

```text
host logout/user change
        ↓
await sdk.dispose()
        ↓
close WebSocket
cancel request/upload/reconnect
clear in-memory conversation/message/unread state
discard pending attachment/message
create SDK baru untuk user baru
```

Ini lebih aman daripada mengganti token dan identity secara parsial pada instance yang sedang aktif.

### Jika instance harus tetap hidup

Sediakan API eksplisit dan atomik, misalnya:

```dart
await sdk.resetForUser(newIdentity);
```

Operasi tersebut harus:

- menghentikan koneksi lama;
- membatalkan retry/reconnect lama;
- membersihkan state lama;
- mengubah identity dan auth context secara konsisten;
- baru kemudian mengizinkan request user baru.

Jangan mengandalkan host mengganti token diam-diam sementara request user lama masih berjalan.

## 9. Error model dan retry policy

TRD sudah menyebut typed errors, tetapi mapping HTTP dan retry policy perlu dibakukan.

Rekomendasi:

```dart
sealed class LiveChatException implements Exception {
  const LiveChatException();
}

final class AuthException extends LiveChatException {
  const AuthException();
}

final class NetworkException extends LiveChatException {
  const NetworkException();
}

final class TimeoutException extends LiveChatException {
  const TimeoutException();
}

final class ApiException extends LiveChatException {
  const ApiException({required this.statusCode, this.requestId});

  final int statusCode;
  final String? requestId;
}

final class ValidationException extends LiveChatException {
  const ValidationException({this.message});

  final String? message;
}
```

Minimal mapping:

| Response | Perilaku |
|---|---|
| `401` | force refresh sekali, retry sekali, lalu `AuthException` |
| `403` | `ApiException`/forbidden, tidak retry |
| `404` | `ConversationNotFoundException` atau typed not-found |
| `409` | conflict, terutama create/send duplicate |
| `422` | `ValidationException` |
| `429` | hormati `Retry-After`; jangan retry tanpa batas |
| timeout/network | `TimeoutException`/`NetworkException`; retry terbatas untuk operasi aman |
| `5xx` | `ApiException`; retry terbatas hanya bila policy mengizinkan |

Mutation seperti create conversation, upload, dan send message tidak boleh diulang sembarangan. Jika backend mendukung, gunakan `Idempotency-Key` atau client mutation ID.

Semua request yang dapat dibatalkan harus menerima `CancelToken` atau abstraction cancellation. Chat room ditutup tidak boleh meninggalkan request/upload yang masih hidup tanpa owner.

## 10. WebSocket: blocker dan rekomendasi boundary

TRD dengan benar menyatakan WebSocket belum boleh difinalisasi sebelum kontrak backend tersedia. Yang masih harus dikonfirmasi:

- URL development/production;
- auth melalui header, query, atau handshake message;
- event name dan envelope;
- subscribe/unsubscribe payload;
- send payload dan acknowledgement;
- read/delivery event;
- status event;
- reconnect policy dan server resume mechanism.

Jangan menebak payload WebSocket dari screenshot/UI.

Boundary yang disarankan:

```dart
abstract interface class RealtimeChatClient {
  Stream<RealtimeEvent> get events;

  Future<void> connect({required String conversationId});

  Future<void> disconnect();
}
```

Aturan implementasi:

- REST tetap source of truth untuk history.
- WebSocket hanya event realtime.
- Event unknown tidak boleh menghentikan stream.
- Event dideduplikasi dengan `message.id` atau event ID.
- Reconnect mempertahankan `conversation.id`.
- Setelah reconnect, lakukan REST resync.
- Backoff memiliki batas maksimum dan retry limit.
- Logout/dispose membatalkan reconnect.

## 11. Security dan observability

Wajib:

- HTTPS/WSS untuk production.
- Bearer token tidak pernah dicatat.
- Message content, attachment content, dan PII tidak masuk log production.
- Logging development harus melakukan redaction header/token.
- Request ID/correlation ID diteruskan jika backend mendukung.
- Error yang ditampilkan UI tidak membocorkan detail internal/server.
- Jangan mengirim local file path sebagai message; upload dahulu dan kirim attachment identifier.

Untuk banking/security context, logging dan retry sama pentingnya dengan endpoint mapping. Jangan menambahkan interceptor logging generik yang mencetak seluruh request/response tanpa redaction.

## 12. Struktur folder yang disarankan

```text
lib/
├── live_chat_sdk.dart                 # public exports only
└── src/
    ├── core/
    │   ├── config/
    │   ├── errors/
    │   ├── network/
    │   │   ├── api_client.dart
    │   │   ├── auth_interceptor.dart
    │   │   └── token_coordinator.dart
    │   └── serialization/
    ├── auth/
    │   ├── auth_provider.dart
    │   └── user_identity.dart
    ├── domain/
    │   ├── models/
    │   ├── repositories/
    │   └── use_cases/
    ├── data/
    │   ├── dto/
    │   ├── repositories/
    │   └── realtime/
    ├── runtime/
    │   └── live_chat_runtime.dart
    └── ui/
        ├── conversation_list/
        ├── new_conversation/
        ├── chat_room/
        ├── articles/
        └── rating/
```

Public export hanya dari `lib/live_chat_sdk.dart`. Host tidak boleh mengimpor `src` untuk memakai SDK.

## 13. Rekomendasi dependency dan scope

`pubspec.yaml` saat ini belum mencerminkan seluruh technology stack TRD. Tambahkan dependency hanya ketika boundary dan kontrak sudah jelas:

1. `dio` untuk REST client.
2. `web_socket` setelah kontrak backend tersedia.
3. `json_serializable` + `build_runner` setelah DTO/API schema stabil.
4. `mocktail` untuk unit/contract test.
5. `flutter_secure_storage` hanya jika ownership storage token memang disepakati; default-nya host tetap memiliki auth storage.

Jangan mengimplementasikan secure storage di SDK hanya karena dependency ada di TRD. Itu keputusan ownership, bukan sekadar keputusan package.

## 14. Acceptance criteria untuk coding AI

### Architecture

- [ ] Tidak ada global mutable `Dio`, token, repository, WebSocket, atau feature state.
- [ ] Setiap `LiveChatSdk` memiliki `ApiClient` dan dependency sendiri.
- [ ] Dua instance SDK dapat hidup bersamaan dengan base URL/identity berbeda.
- [ ] UI/controller tidak memanggil Dio atau endpoint langsung.
- [ ] Repository dapat dites tanpa widget dan network asli.
- [ ] Public API tersedia dari `lib/live_chat_sdk.dart`.

### Auth

- [ ] Semua request protected mengambil token melalui `AuthProvider`.
- [ ] `AuthProvider` mendukung force refresh.
- [ ] `401` memicu satu refresh dan maksimal satu retry per request.
- [ ] Concurrent `401` memakai single-flight refresh.
- [ ] Refresh failure/token null menghasilkan `AuthException`.
- [ ] Token/refresh token tidak pernah masuk log.

### Lifecycle

- [ ] `dispose()` menutup WebSocket.
- [ ] `dispose()` membatalkan request, upload, dan reconnect yang dimiliki SDK.
- [ ] `dispose()` membersihkan conversation/message/unread state dari memory.
- [ ] User baru tidak dapat memakai state atau token user lama.

### REST/data

- [ ] Timeout connect/send/receive configurable.
- [ ] Error HTTP dipetakan ke typed exception.
- [ ] Pagination cursor dikelola repository, bukan UI.
- [ ] DTO dipetakan ke domain model.
- [ ] API wrapper `{meta, data}` divalidasi dan diparse typed.

### Testing

- [ ] Token injection.
- [ ] Token tidak tersedia.
- [ ] Refresh setelah `401`.
- [ ] Concurrent `401` dan single-flight.
- [ ] Retry limit.
- [ ] Error mapping `403/404/409/422/429/5xx`.
- [ ] Cancellation saat dispose.
- [ ] Logout/user switch cleanup.
- [ ] Dua SDK instance dengan credential/config berbeda.
- [ ] Repository memakai fake `ApiClient`/transport.
- [ ] `fvm flutter analyze` lulus.
- [ ] `fvm flutter test` lulus.

## 15. Instruksi implementasi untuk coding agent

1. Baca `LIVE_CHAT_PRD.md`, `LIVE_CHAT_TRD.md`, dan sequence diagram sebelum coding.
2. Inspect repository aktual dan pertahankan perubahan user yang sudah ada.
3. Buat `LiveChatConfig`, `UserIdentity`, dan `AuthProvider` terlebih dahulu.
4. Buat `ApiClient` instance-scoped dengan dependency injection.
5. Implementasikan `AuthInterceptor` + `TokenCoordinator` untuk force refresh/single-flight.
6. Implementasikan typed exception dan HTTP error mapping.
7. Buat DTO, domain model, repository interface, dan fake transport/repository.
8. Pindahkan state data dari fixture/widget ke controller/use-case layer.
9. Tambahkan `dispose`, cancellation, dan logout cleanup.
10. Hubungkan conversation/message UI ke repository/controller.
11. Implementasikan attachment upload setelah endpoint dan batas backend dikonfirmasi.
12. Implementasikan WebSocket hanya setelah kontrak resmi tersedia.
13. Jangan mengarang endpoint/payload WebSocket/create/upload/rating yang belum ada.
14. Jalankan format, analyze, unit test, widget test, dan bila tersedia integration test pada `example`.
15. Laporkan file yang berubah, command yang dijalankan, dan hasil test nyata.

## Rekomendasi akhir

Desain yang paling sehat untuk SDK ini:

```text
Host Auth/Identity
        ↓
AuthProvider
        ↓
LiveChatSdk (satu instance per user/session)
        ├── ApiClient instance-scoped
        ├── AuthInterceptor + single-flight refresh
        ├── Repository boundary
        ├── RealtimeChatClient
        └── Runtime state yang bisa di-dispose
```

Analogi iOS-nya: `ApiClient` lebih dekat ke `URLSession`/network client yang di-inject per feature, sementara `AuthProvider` adalah adapter ke session/auth layer host. Interceptor boleh menambahkan credential dan menangani retry, tetapi credential store dan refresh policy tetap menjadi ownership application layer.

Jangan membuat padanan `URLSession.shared` global yang membawa credential dan state Live Chat lintas user.

Prioritas implementasi bukan menambah semua endpoint sekaligus. Prioritasnya adalah membakukan ownership, lifecycle, dan retry semantics terlebih dahulu. Setelah itu endpoint REST dapat ditambahkan secara aman dan WebSocket dapat diimplementasikan ketika kontrak backend sudah tersedia.
