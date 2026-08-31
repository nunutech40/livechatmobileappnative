import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livechatmobileappnative/livechatmobileappnative.dart';

void main() {
  test('ApiClient refreshes once after a 401', () async {
    final auth = _TestAuthProvider();
    final dio = Dio();
    var requests = 0;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests++;
          if (requests == 1) {
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response<void>(
                  requestOptions: options,
                  statusCode: 401,
                ),
              ),
            );
          } else {
            handler.resolve(
              Response<Map<String, Object?>>(
                requestOptions: options,
                statusCode: 200,
                data: const {'ok': true},
              ),
            );
          }
        },
      ),
    );
    final client = ApiClient(dio, authProvider: auth);

    final response = await client.get<Map<String, Object?>>('/health');

    expect(response.data?['ok'], true);
    expect(auth.refreshCalls, 1);
    expect(requests, 2);
    await client.close();
  });

  test('ApiClient rejects requests without a host token', () async {
    final client = ApiClient(
      Dio(),
      authProvider: _TestAuthProvider(token: null),
    );

    expect(() => client.get<void>('/protected'), throwsA(isA<AuthException>()));
    await client.close();
  });

  test('message model supports ordered mixed content', () {
    const attachment = AttachmentData(
      name: 'guide.pdf',
      extension: 'pdf',
      size: '10 KB',
      kind: AttachmentKind.document,
    );
    const message = ChatMessage(
      time: '10:00',
      variant: MessageBubbleVariant.outgoing,
      contents: [
        TextContent('Berikut filenya'),
        AttachmentContent(attachment),
        UnsupportedContent(),
      ],
    );

    expect(message.contents, hasLength(3));
    expect(message.text, 'Berikut filenya');
    expect(message.attachment, attachment);
  });

  testWidgets('renders conversation tab and new chat entry', (tester) async {
    await tester.pumpWidget(const LiveChatPreviewApp());

    expect(find.text('Percakapan'), findsOneWidget);
    expect(find.text('Buat Pesan Baru'), findsWidgets);
    expect(find.text('Baru-baru ini'), findsOneWidget);
  });

  testWidgets('switches to articles tab', (tester) async {
    await tester.pumpWidget(const LiveChatPreviewApp());

    await tester.tap(find.text('Artikel'));
    await tester.pumpAndSettle();

    expect(find.text('Artikel Terpopuler'), findsOneWidget);
    expect(find.text('Cari pusat bantuan kami...'), findsOneWidget);
  });

  testWidgets('filters articles locally and supports clearing search', (
    tester,
  ) async {
    await tester.pumpWidget(const LiveChatPreviewApp());
    await tester.tap(find.text('Artikel'));
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'komship');
    await tester.pump();
    expect(
      find.text('Kirim Paket Ke Luar Negeri Pakai Komship'),
      findsOneWidget,
    );
    expect(
      find.text('Cara Membagikan Akses Melalui Fitur Komerce'),
      findsNothing,
    );

    await tester.tap(find.byTooltip('Hapus pencarian'));
    await tester.pump();
    expect(find.byType(ArticleCard), findsAtLeastNWidgets(2));
  });

  testWidgets('opens new conversation product selection', (tester) async {
    await tester.pumpWidget(const LiveChatPreviewApp());

    await tester.tap(
      find.descendant(
        of: find.byType(NewChatCard),
        matching: find.text('Buat Pesan Baru'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Pilih produk yang ingin kamu tanyakan'), findsOneWidget);
    expect(find.text('Komship'), findsOneWidget);
  });

  testWidgets('opens a conversation and renders composer', (tester) async {
    await tester.pumpWidget(const LiveChatPreviewApp());

    await tester.tap(find.text('testing testing'));
    await tester.pumpAndSettle();

    expect(find.text('Send a message...'), findsOneWidget);
    expect(find.byTooltip('Tutup Live Chat'), findsOneWidget);
  });

  testWidgets('opens composer attachment menu and emoji picker', (
    tester,
  ) async {
    await tester.pumpWidget(const LiveChatPreviewApp());
    await tester.tap(find.text('testing testing'));
    await tester.pump();

    await tester.tap(find.byTooltip('Tambah lampiran'));
    await tester.pump();
    expect(find.text('Tambah Foto'), findsOneWidget);
    expect(find.text('Tambah File'), findsOneWidget);

    await tester.tap(find.byTooltip('Pilih emoji'));
    await tester.pump();
    expect(find.byType(EmojiPickerPanel), findsOneWidget);
  });

  testWidgets('ended conversation does not show composer', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: ChatRoomPage(
            conversationId: '535',
            status: ConversationStatus.resolved,
            onBack: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(RatingPreview), findsOneWidget);
    expect(find.byTooltip('Kirim pesan'), findsNothing);
  });
}

final class _TestAuthProvider implements AuthProvider {
  _TestAuthProvider({this.token = 'old-token'});

  String? token;
  int refreshCalls = 0;

  @override
  Future<String?> getAccessToken({bool forceRefresh = false}) async {
    if (forceRefresh) {
      refreshCalls++;
      token = 'new-token';
    }
    return token;
  }
}
