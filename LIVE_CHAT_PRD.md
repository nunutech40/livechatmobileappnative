# Product Requirements Document (PRD)

## Live Chat Flutter SDK

**Status:** Draft  
**Version:** 0.1.0  
**Platform:** Flutter on Android and iOS  
**Audience:** Product, Design, Engineering, QA, and stakeholders

---

## 1. Document Purpose

Dokumen ini mendefinisikan kebutuhan produk dan perilaku fitur Live Chat yang akan dikembangkan sebagai Flutter SDK reusable untuk digunakan oleh beberapa aplikasi internal kantor.

Dokumen ini tidak menentukan pilihan framework, package, struktur kode, atau detail implementasi teknis. Hal-hal tersebut akan didefinisikan pada Technical Requirements Document (TRD) terpisah.

Flow antar user, aplikasi host, Live Chat SDK/UI, REST API, WebSocket, backend, dan agent tersedia di `LIVE_CHAT_SEQUENCE_DIAGRAM.md`.

## 2. PRD vs TRD

| Dokumen | Fokus | Contoh isi |
|---|---|---|
| **PRD** | Apa yang dibutuhkan user dan produk | Flow new chat, history chat, status session, fitur attachment, acceptance criteria |
| **TRD** | Bagaimana kebutuhan tersebut dibangun | Arsitektur Flutter, package HTTP/WebSocket, state management, struktur folder, retry strategy, CI/CD |

PRD ini menjadi acuan perilaku produk. TRD harus mengikuti kebutuhan yang didefinisikan di sini.

## 3. Product Overview

Live Chat adalah fitur bantuan pelanggan yang memungkinkan user menghubungi Customer Service Agent dari aplikasi utama setelah user berhasil login.

Fitur dikemas sebagai Flutter SDK agar dapat digunakan kembali pada beberapa project Flutter Android dan iOS tanpa mengimplementasikan ulang business flow chat pada setiap aplikasi.

SDK menyediakan dua bagian:

1. **Core capability:** conversation, message, API, WebSocket, attachment, status, dan rating.
2. **UI capability:** halaman dan widget Live Chat yang dapat digunakan langsung atau dikustomisasi oleh aplikasi pemakai.

## 4. Goals

- User dapat membuka Live Chat hanya setelah login pada aplikasi utama.
- Email user yang sudah login digunakan untuk mengambil conversation milik user.
- User dapat membuat conversation/session baru.
- User dapat melihat dan melanjutkan conversation aktif dari history.
- User dapat menerima dan mengirim pesan secara realtime.
- User dapat mengirim teks, foto, dokumen, dan emoji.
- User dapat melihat status conversation dan status pesan.
- User dapat menerima notifikasi pesan baru di dalam aplikasi dan melalui notifikasi device.
- User dapat memberikan rating setelah conversation selesai.
- Seluruh data chat bersumber dari API/backend.
- SDK dapat digunakan oleh beberapa aplikasi Flutter Android dan iOS.

## 5. Non-Goals

Hal berikut tidak termasuk dalam scope awal:

- Implementasi aplikasi login utama.
- Implementasi dashboard atau aplikasi agent/admin.
- Dukungan langsung untuk project native Kotlin atau Swift.
- Penyimpanan permanen conversation/message di local storage.
- Offline-first chat atau pengiriman pesan saat offline.
- Sinkronisasi chat antarperangkat secara lokal.
- Penentuan teknologi teknis SDK; hal ini dibahas di TRD.

## 6. User and Access Context

### User

User adalah pengguna aplikasi utama yang sudah login dan membutuhkan bantuan Customer Service.

### Prasyarat akses

- User telah berhasil login pada aplikasi host.
- Aplikasi host menyediakan email user dan auth session/token kepada SDK.
- SDK tidak menyimpan atau menggunakan kredensial admin.
- SDK tidak melakukan login dengan kredensial statis.

## 7. High-Level Navigation

```text
Aplikasi utama
  ↓
User login
  ↓
Buka Live Chat
  ↓
Tab Percakapan atau Artikel
  ↓
New Chat / History Chat
```

Fitur memiliki dua tab utama:

- **Percakapan:** membuat, melihat, dan melanjutkan conversation.
- **Artikel:** mencari dan membaca artikel pusat bantuan.

## 8. User Flow: New Chat

```text
User membuka Live Chat
  ↓
Memilih tab Percakapan
  ↓
Menekan "Buat Pesan Baru"
  ↓
Melihat pesan pembuka Customer Service Agent
  ↓
Memilih produk yang terkait
  ↓
Conversation/session baru dibuat
  ↓
User masuk ke Chat Room
  ↓
User mengirim pesan
  ↓
Agent membalas melalui koneksi realtime
```

Produk yang terlihat pada flow awal:

- Komads
- Komcards
- Komchat
- Kompack
- Komship
- Komtim

`conversation.id` menjadi identitas session bisnis yang dibuat backend. Membuka ulang koneksi WebSocket tidak membuat session baru.

## 9. User Flow: History and Continue Chat

```text
User membuka Live Chat
  ↓
Memilih tab Percakapan
  ↓
SDK mengambil daftar conversation berdasarkan email/user identity
  ↓
User memilih salah satu conversation
  ↓
SDK mengambil message history berdasarkan conversation.id
  ↓
Jika status masih aktif, user dapat melanjutkan chat
  ↓
SDK menghubungkan atau subscribe ke channel realtime conversation
```

History chat tidak membuat session baru. User melanjutkan conversation yang sudah ada.

## 10. User Flow: Conversation Ended

Conversation dapat berubah status dari backend. Status yang tersedia pada API:

- `open`
- `handling`
- `escalated`
- `resolved`
- `cancelled`

`resolved` dan `cancelled` diperlakukan sebagai status final pada sisi produk.

Ketika conversation berstatus final:

- User tetap dapat melihat history message.
- Input pesan tidak ditampilkan atau dinonaktifkan.
- User tidak dapat mengirim message baru pada session tersebut.
- Jika `is_rated` bernilai `false`, user dapat melihat form rating.
- Jika conversation sudah dinilai, form rating tidak ditampilkan lagi.

## 11. Functional Requirements

### FR-01: Open Live Chat

- Fitur hanya dapat diakses oleh user yang sudah login.
- SDK menerima identity user dan auth session dari aplikasi host.
- SDK tidak mengelola kredensial login aplikasi utama.

### FR-02: Conversation List

SDK harus dapat:

- Mengambil daftar conversation berdasarkan email atau user ID.
- Menampilkan status conversation.
- Menampilkan nomor ticket.
- Menampilkan preview message terakhir.
- Menampilkan waktu message terakhir.
- Membedakan conversation yang masih aktif dan sudah final.
- Mendukung cursor pagination menggunakan `last_id`.
- Menampilkan loading, empty state, dan error state.

Response utama dari API memiliki field:

```text
id
status
ticket_number
is_rated
last_message
```

### FR-03: Create New Conversation

SDK harus menyediakan entry point untuk:

- Menekan tombol “Buat Pesan Baru”.
- Memilih produk.
- Memulai conversation baru berdasarkan produk yang dipilih.
- Mengarahkan user ke Chat Room setelah conversation berhasil dibuat.

Endpoint dan payload create conversation harus dikonfirmasi dari API sebelum implementasi final.

### FR-04: Chat Room

Chat Room harus dapat:

- Menampilkan message history.
- Mengelompokkan message berdasarkan tanggal.
- Membedakan message dari user dan agent.
- Menampilkan nama dan avatar sender jika tersedia.
- Menampilkan waktu message.
- Menampilkan status `sent`, `delivered`, dan `read`.
- Mendukung load message lama menggunakan `last_id`.
- Mengirim message baru jika conversation masih aktif.

### FR-05: Message Types

Message content yang didukung API:

- `text`: isi berupa teks.
- `image`: isi berupa URL gambar.
- `document`: isi berupa public ID attachment, dengan metadata nama file, extension, dan size.

### FR-06: Attachment

UI Chat Room menyediakan:

- Tambah foto.
- Tambah file/dokumen.
- Preview attachment sebelum dikirim jika didukung API.
- Indikator upload dan error upload.
- Tampilan file berdasarkan tipe dan nama file.

Detail endpoint upload dan batasan file harus dikonfirmasi sebelum implementasi final.

### FR-07: Emoji

- User dapat membuka emoji picker.
- User dapat mencari atau memilih emoji.
- Emoji yang dipilih masuk ke composer message.
- Emoji dikirim sebagai bagian dari message teks.

### FR-08: Realtime Messaging

SDK harus dapat:

- Membuka koneksi realtime saat Chat Room aktif.
- Menerima message baru dari agent.
- Mengirim message melalui mekanisme yang ditentukan backend.
- Menangani koneksi terputus.
- Melakukan reconnect sesuai aturan teknis yang akan didefinisikan di TRD.
- Menutup atau melepas koneksi ketika user meninggalkan Chat Room.

Detail URL WebSocket, event name, handshake, subscribe, dan payload masih harus dikonfirmasi dari backend karena belum tercantum secara lengkap pada OpenAPI YAML.

### FR-09: Conversation Status

SDK harus memperbarui tampilan ketika status conversation berubah, baik dari response API maupun event realtime.

Perubahan status tidak membuat conversation baru. Status hanya mengubah lifecycle session yang sudah ada.

### FR-10: Rating

- Rating hanya tersedia setelah conversation selesai atau sesuai aturan backend.
- Rating ditampilkan jika `is_rated == false`.
- User dapat memilih nilai rating dan mengisi feedback opsional.
- Setelah berhasil dikirim, rating tidak dapat dikirim ulang dari UI.

Endpoint dan struktur response rating harus dikonfirmasi dari API.

### FR-11: Articles

Tab Artikel harus menyediakan:

- Artikel populer.
- Pencarian artikel pusat bantuan.
- Daftar artikel berdasarkan hasil pencarian.
- Halaman detail artikel.

Detail endpoint artikel akan menjadi scope API terpisah jika belum tersedia pada kebutuhan awal Live Chat.

### FR-12: New Message Notifications

SDK harus menyediakan dua bentuk indikasi pesan baru:

1. **In-app unread indicator** berupa badge merah pada tab Percakapan dan/atau conversation terkait.
2. **Local device notification** berupa notifikasi Android/iOS ketika ada pesan baru dan aplikasi masih aktif.

Aturan perilaku:

- Event pesan baru dari WebSocket memperbarui unread state secara realtime.
- Pesan dari conversation yang sedang aktif tidak boleh menghasilkan notifikasi device berulang jika user sedang melihat conversation tersebut.
- Ketika user membuka conversation, unread state harus disinkronkan kembali dengan API/backend.
- Ketika aplikasi berada di background atau terminated, notifikasi tidak dijamin muncul karena project ini tidak menggunakan FCM/APNs pada scope awal.
- Tapping device notification harus membuka aplikasi dan mengarahkan user ke conversation terkait jika payload menyediakan `conversation_id`.

Notifikasi background/terminated melalui FCM/APNs berada di luar scope MVP dan dapat dipertimbangkan sebagai extension di masa depan.

## 12. Data and API Contract

API yang sudah teridentifikasi dari dokumentasi backend:

| Kebutuhan | Method | Endpoint |
|---|---:|---|
| List conversation user | GET | `/api/v1/conversations/user` |
| List conversation admin | GET | `/api/v1/conversations` |
| List online agents | GET | `/api/v1/users/agents/online` |
| Conversation messages | GET | `/api/v1/conversations/{id}/messages` |
| Conversation timeline | GET | `/api/v1/conversations/{id}/timeline` |

Untuk mobile client, endpoint user conversation dan message yang bersifat public perlu tetap mengikuti aturan authorization dan ownership yang ditetapkan backend.

API response menggunakan wrapper umum:

```json
{
  "meta": {},
  "data": []
}
```

SDK harus mempertahankan field API dalam bentuk domain model yang konsisten, termasuk konversi `snake_case` ke konvensi Dart bila diperlukan. Aturan mapping akan ditentukan di TRD.

## 13. Data Persistence and Source of Truth

API/backend adalah source of truth untuk seluruh data Live Chat.

### Yang boleh disimpan lokal

- Auth session/token yang diperlukan agar user tetap terautentikasi.
- Data minimal untuk memulihkan auth session, sesuai kebijakan aplikasi host.

### Yang tidak disimpan lokal secara permanen

- Conversation list.
- Conversation messages.
- Status conversation.
- Status read/delivery.
- Daftar agent online.
- Attachment metadata.
- Rating state.

Setiap pembukaan fitur atau refresh harus mengambil data dari API. Cache memory sementara selama layar aktif diperbolehkan untuk kebutuhan rendering, tetapi bukan sebagai penyimpanan permanen atau source of truth.

Jika aplikasi offline, SDK menampilkan state koneksi/error. Offline-first dan queue pengiriman message belum termasuk scope awal.

## 14. UI Requirements

### Shared visual behavior

- Header dengan branding Komerce.
- Warna utama oranye dan elemen status sesuai desain.
- Dua tab: Percakapan dan Artikel.
- Layout responsif untuk ukuran layar Android dan iOS.
- Mendukung keyboard, safe area, dan scrolling.
- Mendukung loading, empty, error, retry, dan ended-session state.

### Conversation List

- Badge unread pada tab Percakapan.
- Card conversation dengan status, preview message, ticket number, dan waktu/tanggal.
- Tombol “Buat Pesan Baru”.
- Navigasi ke Chat Room ketika card dipilih.

### Chat Room

- Tombol kembali dan tutup.
- Date separator.
- Bubble incoming dan outgoing.
- Composer message.
- Tombol attachment, emoji, dan send.
- Tampilan session ended.
- Tampilan rating untuk conversation yang memenuhi syarat.

## 15. Error and Edge Cases

SDK harus menangani minimal:

- Auth session expired.
- Email/user identity tidak tersedia.
- API timeout atau server error.
- Conversation tidak ditemukan.
- Conversation berubah menjadi final saat user sedang membuka Chat Room.
- WebSocket gagal connect.
- WebSocket disconnect saat mengetik atau mengirim message.
- Message gagal dikirim.
- Upload gagal atau file tidak valid.
- Tidak ada online agent.
- Response API kosong.
- Pagination cursor tidak valid.
- User membuka conversation yang bukan miliknya.

## 16. Security Requirements

- SDK tidak boleh menyimpan kredensial admin.
- Token/auth session tidak boleh ditulis ke log.
- Message dan attachment harus dikirim melalui koneksi aman.
- Data user hanya boleh diambil berdasarkan identity dan authorization yang valid.
- Logging production tidak boleh mengekspos isi message, token, atau data attachment sensitif.
- Validasi ownership conversation harus mengikuti enforcement backend.

## 17. Acceptance Criteria

### Access and identity

- User belum login tidak dapat membuka Live Chat.
- User yang sudah login dapat membuka Live Chat menggunakan identity dari host app.
- Auth session dapat dipakai oleh SDK tanpa menyimpan data chat permanen.

### New chat

- User dapat memilih “Buat Pesan Baru”.
- User dapat memilih salah satu produk.
- Conversation baru dibuat hanya satu kali untuk satu aksi sukses.
- User diarahkan ke Chat Room conversation baru.

### History and continuation

- Daftar history berasal dari API.
- User dapat membuka conversation tertentu.
- Message history diambil menggunakan `conversation.id`.
- Conversation aktif dapat dilanjutkan.
- Conversation final tidak dapat menerima message baru.

### Messaging

- Message text dapat dikirim dan diterima.
- Image dan document dapat ditampilkan sesuai response API.
- Emoji dapat dikirim sebagai message.
- Status message dapat ditampilkan.
- Reconnect tidak membuat conversation/session baru.

### Session ending and rating

- Perubahan status dari backend tercermin di UI.
- Status `resolved` dan `cancelled` menutup kemampuan mengirim message.
- Rating ditampilkan hanya jika conversation belum dinilai.
- Setelah rating sukses, user tidak melihat form rating yang sama lagi.

### Data

- Conversation dan message tidak disimpan sebagai data permanen di local storage.
- Saat data lokal memory dibersihkan, data chat dapat diambil ulang dari API.

## 18. Open Questions

Hal berikut harus diselesaikan sebelum TRD dan implementasi final:

1. Endpoint dan payload create conversation setelah pemilihan produk.
2. Endpoint dan payload send message.
3. URL WebSocket production dan development.
4. Format handshake/authentication WebSocket.
5. Daftar event WebSocket dan payload masing-masing.
6. Endpoint mark as read dan aturan status delivery.
7. Endpoint upload attachment dan batas ukuran/tipe file.
8. Endpoint submit rating dan enum nilai rating.
9. Endpoint artikel, search, dan detail artikel.
10. Aturan status transition yang valid.
11. Apakah conversation `resolved` dapat dibuka kembali atau harus membuat conversation baru.
12. Aturan online agent dan fallback ketika semua agent offline.
13. Kebijakan token refresh dari aplikasi host.

## 19. Future Technical Requirements Document

TRD berikutnya akan mendefinisikan:

- Struktur package/module Flutter SDK.
- Pembagian core layer dan UI/widget layer.
- Pilihan HTTP client dan WebSocket client.
- State management.
- Model serialization dan API mapping.
- Auth session adapter.
- Reconnect, timeout, retry, dan lifecycle strategy.
- Attachment upload implementation.
- Memory cache policy.
- Error type dan observability.
- Testing strategy.
- CI/CD, versioning, release, dan distribusi private package.
