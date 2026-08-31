# Live Chat UI Flow

**Status:** Draft  
**Version:** 0.1.0  
**Related documents:** `LIVE_CHAT_PRD.md`, `LIVE_CHAT_TRD.md`, `LIVE_CHAT_UI_DESIGN.md`

Interaksi antar actor dan backend dijelaskan lebih detail di `LIVE_CHAT_SEQUENCE_DIAGRAM.md`.

---

## 1. Purpose

Dokumen ini menggabungkan flowchart behavior dengan UI flow sebagai acuan implementasi layar Live Chat Flutter.

Flowchart menjelaskan alur dan keputusan bisnis. UI flow menjelaskan layar, komponen, state, dan referensi visual dari screenshot yang diberikan.

Screenshot digunakan sebagai visual reference untuk layout, warna, spacing, card, header, tabs, bubble, composer, dan rating. Screenshot bukan sumber kebenaran untuk field API atau status backend.

## 2. Overall Entry Flow

```mermaid
flowchart TD
    A[User login di aplikasi host] --> B{Auth session valid?}
    B -- Tidak --> C[Live Chat tidak dapat dibuka]
    B -- Ya --> D[Buka Live Chat]
    D --> E[Load identity dan auth session]
    E --> F[Fetch conversation dan/atau article dari API]
    F --> G[LiveChatPage]
    G --> H[Tab Percakapan]
    G --> I[Tab Artikel]
```

## 3. Conversation Tab Flow

```mermaid
flowchart TD
    A[Tab Percakapan aktif] --> B[Fetch conversation berdasarkan user identity]
    B --> C{Response}
    C -- Data --> D[Tampilkan unread badge dan conversation cards]
    C -- Empty --> E[Tampilkan empty state + Buat Pesan Baru]
    C -- Error --> F[Tampilkan error state + Retry]
    D --> G{Aksi user}
    G -- Buat Pesan Baru --> H[New Conversation Flow]
    G -- Pilih history aktif --> I[Continue Chat Flow]
    G -- Pilih history final --> J[Read-only Chat Flow]
    D --> K[Load more dengan last_id]
```

## 4. New Conversation Flow

```mermaid
flowchart TD
    A[Klik Buat Pesan Baru] --> B[NewConversationPage]
    B --> C[Tampilkan greeting agent]
    C --> D[Pilih product]
    D --> E{Product valid dipilih?}
    E -- Tidak --> F[Tetap di halaman product selection]
    E -- Ya --> G[Controller memanggil create conversation API]
    G --> H{Create berhasil?}
    H -- Tidak --> I[Tampilkan error + Retry]
    H -- Ya --> J[Dapat conversation.id baru]
    J --> K[Buka ChatRoomPage]
    K --> L[Load history via REST]
    L --> M[Connect/subscribe WebSocket]
    M --> N[User dapat mengirim pesan jika session aktif]
```

`conversation.id` baru menandai session bisnis baru. WebSocket reconnect tidak membuat conversation baru.

## 5. Continue History Flow

```mermaid
flowchart TD
    A[User memilih ConversationCard] --> B[Ambil conversation.id]
    B --> C[Buka ChatRoomPage]
    C --> D[Fetch messages dari REST API]
    D --> E{Status conversation}
    E -- open/handling/escalated --> F[Connect/subscribe WebSocket]
    F --> G[Composer aktif]
    G --> H[User melanjutkan chat]
    E -- resolved/cancelled --> I[Composer disabled/hidden]
    I --> J{is_rated?}
    J -- false --> K[Tampilkan rating]
    J -- true --> L[Tampilkan history saja]
```

## 6. Chat Room Flow

```mermaid
flowchart TD
    A[ChatRoomPage dibuka] --> B[Fetch message history]
    B --> C[Render timeline]
    C --> D[Connect WebSocket]
    D --> E{Event masuk}
    E -- New message --> F[Deduplicate + update message state]
    F --> G{Chat sedang dibuka?}
    G -- Ya --> H[Update bubble tanpa local notification]
    G -- Tidak --> I[Update unread + local notification jika app aktif]
    E -- Status change --> J[Update conversation state]
    J --> K{Final status?}
    K -- Ya --> L[End session + disable composer]
    K -- Tidak --> M[Chat tetap aktif]
    E -- Disconnect --> N[Reconnect/backoff]
    N --> O[Resync history via REST]
```

## 7. New Message and Attachment Flow

```mermaid
flowchart TD
    A[ChatComposer] --> B{Pilih aksi}
    B -- Text --> C[Input text]
    B -- Emoji --> D[Emoji picker]
    B -- Foto --> E[Image picker]
    B -- File --> F[File picker]
    C --> G[Validate message]
    D --> G
    E --> H[Validate file]
    F --> H
    H --> I[Upload attachment]
    I --> J[Dapatkan attachment reference]
    J --> K[Build message payload]
    G --> K
    K --> L[Send message melalui contract backend]
    L --> M{Berhasil?}
    M -- Ya --> N[Render outgoing bubble]
    M -- Tidak --> O[Tampilkan failed/retry state]
```

Endpoint dan payload create/send/upload masih menunggu konfirmasi backend.

## 8. Rating Flow

```mermaid
flowchart TD
    A[Conversation status final] --> B[Fetch/receive is_rated]
    B --> C{Sudah rated?}
    C -- Ya --> D[Tampilkan thank-you/read-only state]
    C -- Tidak --> E[Tampilkan RatingSection]
    E --> F[User memilih rating]
    F --> G[User mengisi feedback opsional]
    G --> H[Kirim rating]
    H --> I{Berhasil?}
    I -- Ya --> J[Update is_rated + tampilkan confirmation]
    I -- Tidak --> K[Tampilkan error + Retry]
```

## 9. UI Screen Inventory

| Screen/Section | Tujuan | Screenshot reference |
|---|---|---|
| `LiveChatPage` | Shell, header, tab, dan overlay/panel | Semua screenshot |
| `ConversationListPage` | New chat entry dan history list | Screenshot conversation list |
| `NewConversationPage` | Greeting dan pilihan product | Screenshot pilihan Komads–Komtim |
| `ChatRoomPage` | Timeline, composer, attachment, emoji | Screenshot chat room |
| `ConversationEndedSection` | Menandai session selesai | Screenshot “Sesi obrolan telah berakhir” |
| `RatingSection` | Rating dan feedback | Screenshot rating |
| `ArticlePage` | Search dan popular articles | Screenshot tab Artikel |

## 10. Visual Reference Mapping

### Conversation List

Elemen yang terlihat:

- Header orange Komerce.
- Tombol close.
- Segmented tab Percakapan/Artikel.
- Badge jumlah unread.
- Card greeting “Agent kami siap membalas pesanmu secepatnya”.
- CTA “Buat Pesan Baru”.
- Section “Baru-baru ini”.
- Conversation card dengan status, preview message, ticket number, waktu/tanggal, dan chevron.

### New Conversation

Elemen yang terlihat:

- Tombol back.
- Greeting dari Customer Service Agent.
- Daftar pilihan product.
- Icon dan chevron per product.

### Chat Room

Elemen yang terlihat:

- Header dengan back dan close.
- Date separator.
- Incoming/outgoing bubble.
- Avatar sender.
- Timestamp.
- Delivery/read indicator.
- Composer text.
- Attachment button.
- Emoji button dan picker.
- Send button.

### Ended Conversation and Rating

Elemen yang terlihat:

- Pesan sesi berakhir.
- Rating emoji 1–5.
- Feedback opsional.
- Tombol kirim penilaian.
- Confirmation setelah rating diterima.

## 11. UI State Matrix

| Area | States |
|---|---|
| Live Chat entry | authenticated, unauthenticated, auth expired |
| Conversation list | initial, loading, loaded, empty, loading more, error |
| New conversation | idle, product selected, submitting, error |
| Chat room | loading history, loaded, connecting, connected, reconnecting, error |
| Composer | enabled, disabled, sending, uploading, ended |
| Message bubble | incoming, outgoing, system, unsupported, failed |
| Attachment | selecting, validating, uploading, uploaded, failed |
| Rating | available, submitting, submitted, error |
| Article | loading, loaded, empty, searching, error |

## 12. Component Boundary Rules

```text
Page / Controller
  ├── API/Dio
  ├── Riverpod
  ├── WebSocket
  ├── Navigation
  ├── Notification
  └── Side effects

Section / Composite / Primitive
  ├── Display-ready input
  ├── Explicit visual state
  └── Callback event
```

Tidak boleh ada `ConversationCard` atau `MessageBubble` yang memanggil API, provider, repository, router, notification, atau storage secara langsung.

## 13. Recommended Deliverables Before Coding

1. Finalize visual tokens: color, spacing, radius, typography, icon size, shadow.
2. Confirm screenshot dimensions and responsive behavior.
3. Confirm product icon assets.
4. Confirm exact API contract untuk create conversation, send message, attachment, rating, dan WebSocket.
5. Buat component spec untuk tabs, cards, bubble, composer, status, dan rating.
6. Buat widget/golden test matrix untuk visual states.
