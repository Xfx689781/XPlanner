import 'package:facet/app/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('三栏导航可以切换', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FacetApp()));
    expect(find.text('今天'), findsWidgets);

    await tester.tap(find.bySemanticsLabel('任务'));
    await tester.pumpAndSettle();
    expect(find.text('任务'), findsWidgets);

    await tester.tap(find.bySemanticsLabel('日志'));
    await tester.pumpAndSettle();
    expect(find.text('日志'), findsWidgets);
  });
}
