import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livechatmobileappnative/livechatmobileappnative.dart';

import 'demo_partner_auth_client.dart';

const _demoEmail = 'ryanosaffiliete@yopmail.com';
const _demoPassword = '@Apaaja0';

class DemoHostApp extends StatelessWidget {
  const DemoHostApp({super.key, this.useLiveApi = true});

  final bool useLiveApi;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Komerce Host App Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF5722)),
          useMaterial3: true,
        ),
        home: DemoLoginPage(useLiveApi: useLiveApi),
      ),
    );
  }
}

class DemoLoginPage extends StatefulWidget {
  const DemoLoginPage({required this.useLiveApi, super.key});

  final bool useLiveApi;

  @override
  State<DemoLoginPage> createState() => _DemoLoginPageState();
}

class _DemoLoginPageState extends State<DemoLoginPage> {
  late final TextEditingController _emailController = TextEditingController(
    text: _demoEmail,
  );
  late final TextEditingController _passwordController = TextEditingController(
    text: _demoPassword,
  );
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    final valid =
        _emailController.text.trim() == _demoEmail &&
        _passwordController.text == _demoPassword;
    if (!valid) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email atau password demo tidak sesuai.')),
      );
      return;
    }

    late final DemoAuthSession session;
    if (widget.useLiveApi) {
      try {
        session = await DemoPartnerAuthClient().login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } on LiveChatException catch (error) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error.message)));
        }
        return;
      }
    } else {
      session = const DemoAuthSession(
        accessToken: 'demo-access-token',
        email: _demoEmail,
      );
    }

    final authProvider = _DemoAuthProvider(session.accessToken);
    final sdk = LiveChatSdk(
      config: const LiveChatConfig(
        restBaseUrl: 'https://api.internal.komerce.my.id/dev/live-chat',
        websocketUrl: 'wss://api.internal.komerce.my.id/dev/live-chat',
      ),
      authProvider: authProvider,
      identity: UserIdentity(userId: 'demo-ryan-oksa', email: session.email),
    );

    if (!mounted) {
      await sdk.dispose();
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => DemoHostHome(sdk: sdk)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.storefront_rounded, size: 72),
                const SizedBox(height: 20),
                Text(
                  'Host App Demo',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Login dulu untuk membuka Live Chat SDK.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Login'),
                ),
                const SizedBox(height: 12),
                Text(
                  'Credential demo lokal untuk example app.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DemoHostHome extends StatefulWidget {
  const DemoHostHome({required this.sdk, super.key});

  final LiveChatSdk sdk;

  @override
  State<DemoHostHome> createState() => _DemoHostHomeState();
}

class _DemoHostHomeState extends State<DemoHostHome> {
  @override
  void dispose() {
    widget.sdk.dispose();
    super.dispose();
  }

  void _openChat() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.88,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: LiveChatPage(
            repository: widget.sdk.conversations,
            onClose: () => Navigator.pop(context),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Komerce Affiliate')),
      body: Stack(
        children: [
          ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: 8,
            itemBuilder: (context, index) => Card(
              child: ListTile(
                leading: CircleAvatar(child: Text('${index + 1}')),
                title: Text('Order Affiliate ${index + 1}'),
                subtitle: const Text('Contoh konten host app'),
                trailing: const Text('Rp 1.978.025'),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(48),
              color: Colors.white,
              child: InkWell(
                onTap: _openChat,
                borderRadius: BorderRadius.circular(48),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
                  child: Row(
                    children: [
                      const Text('👋', style: TextStyle(fontSize: 38)),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Butuh bantuan?',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Klik di sini dan mulai tanya ke customer help',
                            ),
                          ],
                        ),
                      ),
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Color(0xFFFF8A3D),
                        child: Icon(Icons.support_agent, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final class _DemoAuthProvider implements AuthProvider {
  _DemoAuthProvider(this._token);

  final String _token;

  @override
  Future<String?> getAccessToken({bool forceRefresh = false}) async => _token;
}
