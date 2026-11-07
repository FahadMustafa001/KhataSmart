import 'package:flutter_test/flutter_test.dart';
import 'package:smartkhata/main.dart';

void main() {
  testWidgets('SmartKhataApp initial load smoke test',
      (WidgetTester tester) async {
    await tester.pumpWidget(const SmartKhataApp());
    expect(find.byType(SmartKhataApp), findsOneWidget);
  });
}
