import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_app.dart';
import 'helpers/test_db.dart';

void main() {
  testWidgets('三栏导航可以切换', (tester) async {
    final db = openTestDb();
    await tester.pumpWidget(testApp(db));
    expect(find.text('今天'), findsWidgets);

    await tester.tapNav('任务');
    expect(find.text('还没有任务'), findsOneWidget);

    await tester.tapNav('日志');
    expect(find.text('日志'), findsWidgets);

    await tester.disposeApp();
    await tester.db(db.close);
  });
}
