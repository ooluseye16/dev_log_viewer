import 'package:dev_log_client/dev_log_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

// ─── Dio setup ───────────────────────────────────────────────────────────────
// Option B: add DevLogInterceptor so every API request/response streams to
// the viewer automatically — no other changes needed.
final _dio = Dio(BaseOptions(baseUrl: 'https://jsonplaceholder.typicode.com'))
  ..interceptors.add(DevLogInterceptor());

void main() {
  // Connect to the Dev Log Viewer server.
  // Auto-discovers on ports 8181–8185; pass port: 8182 to be explicit.
  LogForwarder.init();

  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dev Log Client Example',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const _HomePage(),
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dev Log Viewer — Example')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader('Option A — LogForwarder.send()'),
          _DemoTile(
            label: 'Send info log',
            onTap: () => LogForwarder.send(
              tag: 'DEMO',
              message: 'Button tapped at ${DateTime.now()}',
            ),
          ),
          _DemoTile(
            label: 'Send error log',
            onTap: () => LogForwarder.send(
              tag: 'DEMO',
              message: 'Something went wrong',
              level: 'error',
              error: 'StateError: value was null',
              body: {'context': 'checkout', 'attempt': 2},
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader('Option B — DevLogInterceptor (Dio)'),
          _DemoTile(
            label: 'GET /posts/1',
            onTap: () => _dio.get('/posts/1'),
          ),
          _DemoTile(
            label: 'POST /posts',
            onTap: () => _dio.post('/posts', data: {
              'title': 'Hello from dev_log_client',
              'body': 'Example post',
              'userId': 1,
            }),
          ),
          _DemoTile(
            label: 'GET /404 (triggers error log)',
            onTap: () async {
              try {
                await _dio.get('/this-route-does-not-exist');
              } on DioException catch (_) {}
            },
          ),
          const SizedBox(height: 24),
          _SectionHeader('Option C — AppLog shortcuts'),
          _DemoTile(
            label: 'AppLog.auth()',
            onTap: () => AppLog.auth('User signed in: demo@example.com'),
          ),
          _DemoTile(
            label: 'AppLog.nav()',
            onTap: () => AppLog.nav('Pushed /checkout'),
          ),
          _DemoTile(
            label: 'AppLog.store()',
            onTap: () => AppLog.store('Cart updated — 3 items'),
          ),
          _DemoTile(
            label: 'AppLog.log() — custom tag',
            onTap: () => AppLog.log('PAYMENT', 'Stripe session created'),
          ),
          _DemoTile(
            label: 'AppLog.error()',
            onTap: () {
              try {
                throw StateError('Charge declined');
              } catch (e, s) {
                AppLog.error('PAY', 'Charge failed', error: e, stack: s);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.labelLarge),
    );
  }
}

class _DemoTile extends StatelessWidget {
  const _DemoTile({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card.outlined(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(label),
        trailing: const Icon(Icons.send_outlined),
        onTap: onTap,
      ),
    );
  }
}
