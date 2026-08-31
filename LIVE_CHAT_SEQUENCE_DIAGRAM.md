# Live Chat Sequence Diagrams

**Status:** Draft  
**Version:** 0.1.0  
**Related documents:** `LIVE_CHAT_PRD.md`, `LIVE_CHAT_TRD.md`, `LIVE_CHAT_UI_DESIGN.md`, `LIVE_CHAT_UI_FLOW.md`

---

## 1. Actors and Responsibilities

| Actor | Responsibility |
|---|---|
| User | Membuka Live Chat, memilih produk, membaca/mengirim message, memberi rating |
| App Host | Aplikasi Flutter utama yang mengelola login dan auth session |
| Live Chat SDK/UI | Menampilkan UI, mengelola state, memanggil repository, dan mengatur lifecycle chat |
| REST API | Mengambil conversation, message, status, attachment, dan data artikel |
| WebSocket | Jalur realtime untuk message dan perubahan status |
| Live Chat Backend | Memproses request, menyimpan data, publish event, dan menghubungkan agent |
| Agent | Membalas message dan mengubah status conversation melalui sistem agent |
| Local Notification | Menampilkan notifikasi device saat app aktif dan event WebSocket diterima |

## 2. General Architecture

```mermaid
flowchart LR
    U[User] --> H[App Host]
    H --> S[Live Chat SDK/UI]
    S --> R[REST API]
    S <--> W[WebSocket]
    R --> B[Live Chat Backend]
    W <--> B
    B <--> A[Agent/Web Admin]
    S --> N[Local Notification]
```

## 3. Open Live Chat After Login

```mermaid
sequenceDiagram
    actor User
    participant Host as App Host
    participant SDK as Live Chat SDK/UI
    participant API as REST API

    User->>Host: Login
    Host-->>User: Login berhasil
    User->>Host: Buka fitur Live Chat
    Host->>SDK: Open Live Chat(identity, authProvider)
    SDK->>Host: Request email/user ID dan auth token
    Host-->>SDK: User identity + auth session
    SDK->>API: GET conversations(user identity)
    API-->>SDK: Conversation list atau empty state
    SDK-->>User: Tampilkan LiveChatPage
```

## 4. Load Conversation History

```mermaid
sequenceDiagram
    actor User
    participant SDK as Conversation List UI
    participant Repo as Conversation Repository
    participant API as REST API
    participant Backend as Live Chat Backend

    User->>SDK: Buka tab Percakapan
    SDK->>Repo: loadConversations(identity, cursor)
    Repo->>API: GET /api/v1/conversations/user
    API->>Backend: Query conversations
    Backend-->>API: conversations + last_message
    API-->>Repo: meta + data
    Repo-->>SDK: Display-ready conversation items
    SDK-->>User: Render badge, status, preview, ticket, waktu
    User->>SDK: Scroll ke bawah
    SDK->>Repo: loadMore(last_id)
    Repo->>API: GET conversations(last_id)
    API-->>Repo: Next page
    Repo-->>SDK: Append items
```

## 5. New Chat

```mermaid
sequenceDiagram
    actor User
    participant Host as App Host
    participant SDK as Live Chat SDK/UI
    participant API as REST API
    participant Backend as Live Chat Backend

    User->>SDK: Tap Buat Pesan Baru
    SDK-->>User: Tampilkan greeting + product selection
    User->>SDK: Pilih product
    SDK->>Host: Request current identity/auth session
    Host-->>SDK: Identity + auth session
    SDK->>API: Create conversation(product, identity)
    API->>Backend: Create new conversation/session
    Backend-->>API: conversation.id baru
    API-->>SDK: Conversation created
    SDK-->>User: Buka ChatRoom(conversation.id)
    SDK->>API: GET /conversations/{id}/messages
    API-->>SDK: Initial message history
    SDK-->>User: Render Chat Room
```

> Endpoint dan payload create conversation masih menunggu konfirmasi backend. Nama request pada diagram adalah logical operation, bukan kontrak final.

## 6. Continue Existing Conversation

```mermaid
sequenceDiagram
    actor User
    participant SDK as Conversation List/Chat Room
    participant API as REST API
    participant Backend as Live Chat Backend
    participant WS as WebSocket

    User->>SDK: Tap conversation history
    SDK->>API: GET /api/v1/conversations/{id}/messages
    API->>Backend: Query messages by conversation.id
    Backend-->>API: Messages sorted newest first
    API-->>SDK: Message history
    SDK-->>User: Render timeline
    SDK->>WS: Connect/subscribe(conversation.id)
    WS->>Backend: Handshake + subscribe
    Backend-->>WS: Subscription accepted
    WS-->>SDK: Realtime events
    SDK-->>User: Update Chat Room
```

## 7. Send Message

```mermaid
sequenceDiagram
    actor User
    participant SDK as Chat Room/Controller
    participant API as REST API or WS
    participant Backend as Live Chat Backend
    participant Agent

    User->>SDK: Type message
    User->>SDK: Tap Send
    SDK->>SDK: Validate composer and session status
    alt Session active
        SDK->>API: Send message(conversation.id, content)
        API->>Backend: Persist and dispatch message
        Backend-->>Agent: New user message
        Backend-->>API: Message acknowledgement
        API-->>SDK: Sent message/event
        SDK-->>User: Render outgoing bubble + status
    else Session final
        SDK-->>User: Disable composer / show session ended
    end
```

> Mekanisme send final—REST atau WebSocket—harus mengikuti kontrak backend yang belum tersedia lengkap.

## 8. Receive Agent Message and Local Notification

```mermaid
sequenceDiagram
    participant Agent
    participant Backend as Live Chat Backend
    participant WS as WebSocket
    participant SDK as Live Chat SDK
    participant State as Riverpod State
    participant Notify as Local Notification
    actor User

    Agent->>Backend: Send reply
    Backend-->>WS: Publish new message event
    WS-->>SDK: Receive event
    SDK->>SDK: Deduplicate by message/event ID
    SDK->>State: Update messages and unread state
    alt User is viewing same conversation
        State-->>User: Render new incoming bubble
    else App active, another screen/conversation
        State-->>User: Update red unread badge
        SDK->>Notify: Show local notification
        Notify-->>User: Device notification
    end
```

FCM/APNs tidak digunakan pada MVP. Jika app masuk background atau terminated, WebSocket/local notification tidak menjamin event diterima. Saat app aktif kembali, SDK melakukan resync via REST API.

## 9. WebSocket Disconnect and Resync

```mermaid
sequenceDiagram
    participant SDK as Live Chat SDK
    participant WS as WebSocket
    participant Backend as Live Chat Backend
    participant API as REST API
    actor User

    WS-->>SDK: Connection closed/error
    SDK-->>User: Tampilkan reconnecting state
    SDK->>SDK: Apply reconnect backoff
    SDK->>WS: Reconnect + authenticate + subscribe
    alt Reconnect berhasil
        WS-->>SDK: Subscription accepted
        SDK->>API: Resync messages/status
        API-->>SDK: Latest data
        SDK-->>User: Update timeline dan status
    else Retry limit / network unavailable
        SDK-->>User: Offline/error state + retry action
    end
```

## 10. Conversation Status Changes

```mermaid
sequenceDiagram
    participant Agent
    participant Backend as Live Chat Backend
    participant WS as WebSocket
    participant SDK as Live Chat SDK
    participant State as Riverpod State
    actor User

    Agent->>Backend: Update conversation status
    Backend-->>WS: Publish status event
    WS-->>SDK: Status event(conversation.id, status)
    SDK->>State: Update conversation state
    State-->>User: Update status label
    alt Status is resolved or cancelled
        SDK->>State: Set composer = ended
        State-->>User: Disable composer + show session ended
        SDK->>State: Check is_rated
        alt Not rated
            State-->>User: Show rating form
        else Already rated
            State-->>User: Show read-only/confirmation state
        end
    else Status remains active
        State-->>User: Keep composer enabled
    end
```

## 11. Attachment Flow

```mermaid
sequenceDiagram
    actor User
    participant SDK as Chat Composer/Controller
    participant Picker as Image/File Picker
    participant API as REST API
    participant Backend as Live Chat Backend
    participant WS as WebSocket

    User->>SDK: Tap photo/file
    SDK->>Picker: Open picker
    Picker-->>SDK: Local file reference
    SDK->>SDK: Validate MIME type and size
    SDK->>API: Upload attachment
    API->>Backend: Store attachment
    Backend-->>API: Attachment ID/URL/metadata
    API-->>SDK: Upload result
    SDK->>WS: Send message referencing attachment
    WS->>Backend: Persist attachment message
    Backend-->>SDK: Message acknowledgement/event
    SDK-->>User: Render image/document bubble
```

## 12. Rating Flow

```mermaid
sequenceDiagram
    actor User
    participant SDK as Rating UI/Controller
    participant API as REST API
    participant Backend as Live Chat Backend

    User->>SDK: Pilih rating
    User->>SDK: Isi feedback opsional
    User->>SDK: Tap Kirim Penilaian
    SDK->>API: Submit rating(conversation.id, score, feedback)
    API->>Backend: Persist rating
    Backend-->>API: Rating success
    API-->>SDK: Success response
    SDK-->>User: Update is_rated + confirmation
```

## 13. UI Boundary Summary

```text
User interaction
  ↓
Page/Controller
  ├─ Riverpod state
  ├─ Dio REST request
  ├─ WebSocket lifecycle
  ├─ Local notification
  └─ Navigation/side effect
  ↓
Section/Composite/Primitive
  ├─ Receive display-ready data
  ├─ Render visual state
  └─ Emit callback
```

Primitive dan composite component tidak boleh memanggil API, mengakses provider, membuka router, mengirim notification, atau membaca storage.

## 14. Pending Backend Contracts

Sequence yang masih membutuhkan konfirmasi backend:

- Create conversation dan product payload.
- Send message: REST atau WebSocket.
- WebSocket URL, handshake, authentication, dan subscribe.
- WebSocket event names dan payload.
- Message acknowledgement dan delivery/read event.
- Upload attachment.
- Submit rating.
- Article search/detail.

