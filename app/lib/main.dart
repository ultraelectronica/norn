import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Android emulator reaches the dev machine's backend via 10.0.2.2.
const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8080',
);

void main() {
  runApp(const ProviderScope(child: NornApp()));
}

class NornApp extends StatelessWidget {
  const NornApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Norn',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5A6B7A),
          brightness: Brightness.dark,
        ),
        fontFamily: 'Geist',
        textTheme: Typography.whiteMountainView.apply(fontFamily: 'Geist'),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}

final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
  ],
);

final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 3),
      receiveTimeout: const Duration(seconds: 3),
    ),
  );
});

enum HealthState { up, down }

class HealthResult {
  const HealthResult({
    required this.state,
    this.latencyMs,
    this.error,
  });

  final HealthState state;
  final int? latencyMs;
  final String? error;
}

final healthProvider = FutureProvider.autoDispose<HealthResult>((ref) async {
  final dio = ref.watch(dioProvider);
  final stopwatch = Stopwatch()..start();
  try {
    final res = await dio.get<String>('$apiBaseUrl/healthz');
    stopwatch.stop();
    final ok = res.statusCode == 200 && res.data?.trim() == 'ok';
    return HealthResult(
      state: ok ? HealthState.up : HealthState.down,
      latencyMs: stopwatch.elapsedMilliseconds,
    );
  } on DioException catch (e) {
    return HealthResult(state: HealthState.down, error: e.message);
  }
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(healthProvider).value;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Norn'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recheck health',
            onPressed: () => ref.invalidate(healthProvider),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _StatusDot(result: result),
                      const SizedBox(width: 12),
                      Text(
                        switch (result?.state) {
                          HealthState.up => 'Backend up · ${result?.latencyMs}ms',
                          HealthState.down => 'Backend unreachable',
                          null => 'Checking backend…',
                        },
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'GET $apiBaseUrl/healthz',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.result});

  final HealthResult? result;

  @override
  Widget build(BuildContext context) {
    final color = switch (result?.state) {
      HealthState.up => Colors.greenAccent,
      HealthState.down => Colors.redAccent,
      null => Colors.amber,
    };
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
