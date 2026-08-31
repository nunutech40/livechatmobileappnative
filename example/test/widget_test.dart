import 'package:flutter_test/flutter_test.dart';
import 'package:livechat_sdk_example/demo_host_app.dart';

void main() {
  testWidgets('example boots on the host login screen', (tester) async {
    await tester.pumpWidget(const DemoHostApp());

    expect(find.text('Host App Demo'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('login opens the host app with the chat entry point', (
    tester,
  ) async {
    await tester.pumpWidget(const DemoHostApp());

    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.text('Komerce Affiliate'), findsOneWidget);
    expect(find.text('Butuh bantuan?'), findsOneWidget);
  });
}
