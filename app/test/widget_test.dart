import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:norn/main.dart';

void main() {
  testWidgets('Health screen renders title and endpoint', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          healthProvider.overrideWith(
            (ref) async => const HealthResult(state: HealthState.down),
          ),
        ],
        child: const NornApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Norn'), findsOneWidget);
    expect(find.textContaining('GET http://10.0.2.2:8080/healthz'), findsOneWidget);
    expect(find.byTooltip('Recheck health'), findsOneWidget);
  });
}
