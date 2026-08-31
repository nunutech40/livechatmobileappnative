# Live Chat UI Design Specification

**Status:** Draft  
**Version:** 0.1.0  
**Related documents:** `LIVE_CHAT_PRD.md`, `LIVE_CHAT_TRD.md`, `flutter_component_architecture_guideline.docx`, `flutter_component_testing_guideline.docx`

UI flow lengkap dan pemetaan screenshot tersedia di `LIVE_CHAT_UI_FLOW.md`.

---

## 1. Purpose

Dokumen ini mendefinisikan keputusan desain dan boundary component UI Live Chat sebelum implementasi Flutter dimulai.

Guideline terlampir diperlakukan sebagai aturan implementasi component:

- Data turun melalui input eksplisit.
- Event naik melalui callback.
- Page menjadi tempat orchestration dan side effect.
- Primitive/composite component tidak boleh mengakses API, provider, repository, router, atau storage.
- Component reusable harus dapat dites secara independen.

Screenshot yang diberikan digunakan sebagai referensi visual produk, bukan sebagai kontrak data backend.

## 2. Decision: Tabs

### Keputusan

`LiveChatTabs` dibuat sebagai component internal/design-system, tanpa library tab eksternal.

### Alasan

- Hanya membutuhkan dua tab: Percakapan dan Artikel.
- Visual segmented control pada desain cukup spesifik.
- Interaksi sederhana: selected tab dan callback perubahan.
- Tidak perlu dependency tambahan.
- Lebih mudah menjaga konsistensi branding, spacing, radius, badge, dan golden test.

Flutter built-in `TabController`/`TabBarView` boleh digunakan di level Page bila diperlukan untuk swipe atau lifecycle tab, tetapi visual tab tetap dibungkus oleh `LiveChatTabs`. Aplikasi host tidak perlu mengetahui detail tersebut.

### Public component API

```dart
enum LiveChatTab {
  conversations,
  articles,
}

class LiveChatTabs extends StatelessWidget {
  const LiveChatTabs({
    super.key,
    required this.selectedTab,
    required this.onTabChanged,
    this.unreadCount = 0,
  });

  final LiveChatTab selectedTab;
  final ValueChanged<LiveChatTab> onTabChanged;
  final int unreadCount;
}
```

Component tidak melakukan navigation atau mengubah provider. Parent memutuskan konten yang ditampilkan setelah callback diterima.

### Tab states

- Selected.
- Unselected.
- Selected with unread badge.
- Disabled jika suatu saat diperlukan.

## 3. UI Component Hierarchy

```text
LiveChatPage
├── LiveChatHeader
├── LiveChatTabs
├── ConversationPage
│   ├── NewChatSection
│   └── ConversationListSection
│       └── ConversationCard
├── ArticlePage
│   ├── ArticleSearchSection
│   └── PopularArticleSection
└── ChatRoomPage
    ├── ChatRoomHeader
    ├── MessageTimeline
    │   ├── DateSeparator
    │   ├── ChatMessageBubble
    │   └── SystemEventBubble
    ├── ChatComposer
    │   ├── AttachmentButton
    │   ├── MessageTextField
    │   ├── EmojiButton
    │   └── SendButton
    └── ConversationEndedSection
```

## 4. Message Bubble Strategy

### Keputusan

Jangan membuat satu bubble dengan banyak flag seperti `isImage`, `isFile`, `isSystem`, `isAgent`, dan `isFailed`.

Gunakan data display yang eksplisit dan renderer berdasarkan tipe/variant.

```text
ChatMessageBubble
  ├── TextMessageContent
  ├── ImageMessageContent
  ├── DocumentMessageContent
  ├── UnsupportedMessageContent
  └── MessageMetaFooter
```

### Backend-supported content saat ini

Berdasarkan schema Swagger, `message` adalah array `MessageContent`, sehingga satu message dapat memiliki lebih dari satu content block.

Tipe yang sudah teridentifikasi:

- `text`: plain text.
- `image`: public image URL.
- `document`: attachment public ID dengan metadata file name, extension, dan size.

### Bubble variants

Bubble position/style dipisahkan dari content type:

```dart
enum MessageBubbleVariant {
  incoming,
  outgoing,
  system,
}
```

`incoming` dan `outgoing` menentukan alignment, warna, dan bentuk bubble. `system` digunakan untuk event/divider yang bukan message user biasa jika backend mengaktifkannya.

### Display model

UI menerima display-ready data, bukan model API mentah:

```dart
class MessageBubbleData {
  const MessageBubbleData({
    required this.id,
    required this.variant,
    required this.contents,
    required this.timeText,
    this.senderName,
    this.avatarUrl,
    this.status,
    this.isRead,
  });

  final String id;
  final MessageBubbleVariant variant;
  final List<MessageContentData> contents;
  final String timeText;
  final String? senderName;
  final String? avatarUrl;
  final MessageDeliveryStatus? status;
  final bool? isRead;
}
```

Mapping dari `ConversationMessage` ke `MessageBubbleData` dilakukan oleh mapper/view-model di luar component.

## 5. Extensibility for Future Bubble Types

Bubble renderer harus menggunakan registry/dispatch berdasarkan content type agar tipe baru dapat ditambahkan secara lokal.

```dart
abstract interface class MessageContentRenderer {
  bool supports(MessageContentData content);

  Widget build(BuildContext context, MessageContentData content);
}
```

Renderer yang direncanakan:

| Renderer | Status | Catatan |
|---|---|---|
| Text | MVP | Plain text, multiline, long text |
| Image | MVP | URL, loading, failed image |
| Document | MVP | File name, extension, size, download/open callback |
| Unsupported | MVP fallback | Tidak boleh membuat timeline crash |
| Link preview | Future | Hanya jika backend mengirim contract preview |
| Audio | Future | Hanya jika backend mendukung content type/audio metadata |
| Video | Future | Hanya jika backend mendukung content type/video metadata |
| Location | Future | Hanya jika backend mendukung location payload |
| Sticker/GIF | Future | Hanya jika backend mendukung contract |
| Reaction/reply | Future | Membutuhkan message relation/event contract |
| System event | Separate event | Status/assignment event, bukan regular message bubble |

Tipe future tidak boleh diperlakukan sebagai fakta bahwa backend sudah mendukungnya. Untuk tipe yang belum dikenali, UI menampilkan fallback `UnsupportedMessageContent` dan tetap menampilkan timestamp/message ID bila tersedia.

## 6. System Events and Timeline

Swagger mendefinisikan endpoint timeline yang dapat menggabungkan regular message dan system event. Karena itu, timeline UI tidak boleh mengasumsikan semua item adalah message biasa.

```text
TimelineItem
├── MessageTimelineItem
│   └── ChatMessageBubble
└── SystemTimelineItem
    └── SystemEventBubble / TimelineDivider
```

System event yang mungkin perlu diakomodasi:

- Status berubah.
- Assignee berubah.
- Conversation escalated.
- Conversation resolved.
- Conversation cancelled.

Payload dan event type final tetap mengikuti kontrak backend.

## 7. Chat Composer Design

`ChatComposer` adalah composite UI component yang menerima state dan callback dari Page/Controller.

```dart
enum ComposerState {
  enabled,
  disabled,
  sending,
  uploading,
  ended,
}
```

Public events:

- `onTextChanged`.
- `onSend`.
- `onAttachmentPressed`.
- `onEmojiPressed`.
- `onRetry` jika pengiriman gagal.

`ChatComposer` tidak melakukan upload, mengirim WebSocket, membuka picker, atau menampilkan snackbar secara langsung. Semua efek tersebut dilakukan controller melalui callback.

## 8. Conversation Card Design

`ConversationCard` menerima:

```text
statusText
statusColor/semantic status
previewText
ticketText
dateText
hasUnread
trailing action/indicator
```

Tidak menerima response `Conversation` mentah. Mapping dilakukan di section/controller agar component tetap reusable.

States:

- Normal active.
- Unread.
- Resolved.
- Cancelled.
- Long preview text.
- Empty/unknown preview.
- Missing ticket number/date.

## 9. New Chat Product Selection

Product selection memakai component eksplisit:

```dart
class ProductSelectionList extends StatelessWidget {
  const ProductSelectionList({
    super.key,
    required this.products,
    required this.onProductSelected,
    this.selectedProductId,
  });

  final List<ProductCardData> products;
  final ValueChanged<String> onProductSelected;
  final String? selectedProductId;
}
```

Daftar product dan icon dapat dikonfigurasi dari data/design token. Product card tidak membuat conversation sendiri.

## 10. State and Side-Effect Boundary

```text
Page / Controller
 ├── Riverpod state
 ├── Dio/API call
 ├── WebSocket lifecycle
 ├── Notification trigger
 ├── Navigation
 └── Dialog/snackbar

Section / Composite / Primitive
 ├── Receive display data
 ├── Render state
 └── Emit callbacks
```

Local notification dari pesan WebSocket dipicu oleh controller/notification service, bukan oleh `MessageBubble`.

## 11. Component Testing Plan

### LiveChatTabs

- Selected tab render benar.
- Unselected tab render benar.
- Badge unread render benar.
- Tap tab memanggil `onTabChanged`.
- Tidak ada akses provider/API/router.
- Golden test untuk selected/unselected/badge matrix.

### ChatMessageBubble

- Incoming text.
- Outgoing text.
- Long text.
- Multiline text.
- Image loading/success/error.
- Document with metadata.
- Multiple content blocks in one message.
- Unknown content type fallback.
- Sender/avatar optional.
- Delivery/read state.
- Golden test untuk variant/content matrix.

### ChatComposer

- Enabled.
- Disabled.
- Sending.
- Uploading.
- Ended.
- Text callback.
- Send callback.
- Attachment callback.
- Emoji callback.

### ConversationCard

- Active/unread.
- Resolved.
- Cancelled.
- Long preview.
- Missing optional data.
- Tap callback.

Semua component dirender menggunakan `pumpComponent` dengan data dummy dan callback palsu. Tidak menggunakan API, provider feature, router, storage, atau login session real.

## 12. Visual Tokens

Visual token final harus dipusatkan pada design system package:

```text
AppColors
AppSpacing
AppRadius
AppTypography
AppShadows
AppIconSizes
```

Token awal berdasarkan screenshot:

- Komerce orange sebagai primary action/header.
- Peach/orange muda untuk outgoing bubble.
- Abu-abu terang untuk incoming bubble.
- Biru untuk active/open status.
- Hijau untuk resolved.
- Merah untuk cancelled dan unread badge.
- Border abu-abu ringan.
- Rounded card dan panel.

Nilai numerik token harus ditentukan dari hasil review visual/figma atau implementasi prototype, bukan ditebak dari screenshot saja.

## 13. Design Decisions Summary

| Area | Keputusan |
|---|---|
| Tabs | Custom internal component; tidak memakai library eksternal |
| Tab behavior | Controlled component dengan enum dan callback |
| Bubble | Content renderer extensible, bukan banyak boolean |
| Current content | Text, image, document |
| Future content | Renderer baru dapat ditambahkan dengan fallback unknown |
| Timeline | Memisahkan message dan system event |
| Composer | Controlled state dan callback |
| API/provider access | Hanya Page/Controller |
| Local notification | Controller/service, bukan bubble/component |
| Component test | Widget test wajib; golden test untuk visual matrix |
