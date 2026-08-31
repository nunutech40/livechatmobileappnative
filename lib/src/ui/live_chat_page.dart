import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/chat_models.dart';
import '../state/live_chat_fixture_providers.dart';
import 'articles/article_page.dart';
import 'chat_room/chat_composer.dart';
import 'chat_room/chat_room_components.dart';
import 'conversation_list/conversation_list_page.dart';
import 'new_conversation/new_conversation_page.dart';
import 'rating/rating_section.dart';
import 'shared/live_chat_header.dart';
import 'shared/live_chat_tabs.dart';

class LiveChatPage extends ConsumerStatefulWidget {
  const LiveChatPage({super.key, this.onClose});

  final VoidCallback? onClose;

  @override
  ConsumerState<LiveChatPage> createState() => _LiveChatPageState();
}

class _LiveChatPageState extends ConsumerState<LiveChatPage> {
  final _providerScopeKey = Object();
  String? _selectedConversation;
  ConversationStatus? _selectedConversationStatus;

  @override
  Widget build(BuildContext context) {
    if (_selectedConversation != null) {
      return ChatRoomPage(
        conversationId: _selectedConversation!,
        status: _selectedConversationStatus ?? ConversationStatus.open,
        onBack: () => setState(() {
          _selectedConversation = null;
          _selectedConversationStatus = null;
        }),
      );
    }

    final tab = ref.watch(selectedTabProvider(_providerScopeKey));
    return Scaffold(
      backgroundColor: const Color(0xFFEFF1F2),
      body: SafeArea(
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: Column(
            children: [
              LiveChatHeader(onClose: widget.onClose),
              LiveChatTabs(
                selectedTab: tab,
                unreadCount: 2,
                onTabChanged: (value) {
                  ref
                          .read(selectedTabProvider(_providerScopeKey).notifier)
                          .state =
                      value;
                },
              ),
              Expanded(
                child: tab == LiveChatTab.conversations
                    ? ConversationListPage(
                        onConversationTap: (conversation) {
                          setState(() {
                            _selectedConversation = conversation.id;
                            _selectedConversationStatus = conversation.status;
                          });
                        },
                        onNewChat: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => NewConversationPage(
                              onCreated: (id) {
                                Navigator.pop(context);
                                setState(() {
                                  _selectedConversation = id;
                                  _selectedConversationStatus =
                                      ConversationStatus.open;
                                });
                              },
                            ),
                          ),
                        ),
                      )
                    : ArticlePage(
                        onArticleTap: (title) =>
                            _showUiMessage('Artikel dipilih: $title'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUiMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class ChatRoomPage extends ConsumerStatefulWidget {
  const ChatRoomPage({
    super.key,
    required this.conversationId,
    required this.status,
    required this.onBack,
  });

  final String conversationId;
  final ConversationStatus status;
  final VoidCallback onBack;

  @override
  ConsumerState<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends ConsumerState<ChatRoomPage> {
  final _controller = TextEditingController();
  late final List<ChatMessage> _messages;
  bool _showAttachmentMenu = false;
  bool _showEmojiPicker = false;
  AttachmentData? _pendingAttachment;

  @override
  void initState() {
    super.initState();
    _messages = [...ref.read(messagesProvider(widget.conversationId))];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ended =
        widget.status == ConversationStatus.resolved ||
        widget.status == ConversationStatus.cancelled;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            LiveChatHeader(
              showBack: true,
              onBack: widget.onBack,
              onClose: widget.onBack,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
                children: [
                  const DateSeparator(label: 'today'),
                  const SizedBox(height: 16),
                  ..._messages.map(
                    (message) => MessageBubble(
                      message: message,
                      onDownload: _downloadAttachment,
                    ),
                  ),
                  if (ended) const ConversationEndedSection(),
                ],
              ),
            ),
            if (ended && widget.status == ConversationStatus.resolved)
              const RatingPreview(),
            if (!ended)
              ChatComposer(
                controller: _controller,
                showAttachmentMenu: _showAttachmentMenu,
                showEmojiPicker: _showEmojiPicker,
                pendingAttachment: _pendingAttachment,
                onToggleAttachment: () => setState(() {
                  _showAttachmentMenu = !_showAttachmentMenu;
                  _showEmojiPicker = false;
                }),
                onToggleEmoji: () => setState(() {
                  _showEmojiPicker = !_showEmojiPicker;
                  _showAttachmentMenu = false;
                }),
                onSend: _send,
                onPhotoTap: _pickPhoto,
                onFileTap: _pickFile,
                onRemoveAttachment: () =>
                    setState(() => _pendingAttachment = null),
                onEmojiSelected: () => setState(() {}),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPhoto() async {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() => _showAttachmentMenu = false);
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (file == null || !mounted) return;

      final bytes = await file.readAsBytes();
      if (!mounted) return;
      final dot = file.name.lastIndexOf('.');
      final extension = dot > 0 ? file.name.substring(dot + 1) : 'jpg';
      final size = '${(bytes.length / 1024).ceil()} KB';
      setState(() {
        _pendingAttachment = AttachmentData(
          name: file.name,
          extension: extension,
          size: size,
          kind: AttachmentKind.image,
          bytes: bytes,
        );
      });
    } on PlatformException {
      if (mounted) _showPickerError('foto');
    } catch (_) {
      if (mounted) _showPickerError('foto');
    }
  }

  Future<void> _pickFile() async {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() => _showAttachmentMenu = false);
    try {
      final file = await FilePicker.pickFile(type: FileType.any);
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      final size = await file.length();
      setState(() {
        _pendingAttachment = AttachmentData(
          name: file.name,
          extension: file.extension ?? 'file',
          size: _formatFileSize(size),
          kind: AttachmentKind.document,
          bytes: bytes,
        );
      });
    } on PlatformException {
      if (mounted) _showPickerError('file');
    } catch (_) {
      if (mounted) _showPickerError('file');
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).ceil()} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  void _showPickerError(String attachmentType) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Lampiran $attachmentType tidak dapat dipilih. Silakan coba lagi.',
        ),
      ),
    );
  }

  void _downloadAttachment(AttachmentData data) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Mengunduh ${data.name}...')));
  }

  void _send() => setState(() {
    _messages.add(
      ChatMessage(
        time: 'Now',
        variant: MessageBubbleVariant.outgoing,
        contents: [
          if (_controller.text.trim().isNotEmpty)
            TextContent(_controller.text.trim()),
          if (_pendingAttachment != null)
            AttachmentContent(_pendingAttachment!),
        ],
      ),
    );
    _controller.clear();
    _pendingAttachment = null;
  });
}
