import 'package:flutter_test/flutter_test.dart';

import 'package:obs/main.dart';

void main() {
  testWidgets('Giriş ekranı temel bileşenleri gösterir', (WidgetTester tester) async {
    await tester.pumpWidget(const ObsApp());

    expect(find.text('YÖKSİS ile giriş'), findsOneWidget);
    expect(find.text('e-DEVLET ile Giriş'), findsOneWidget);
    expect(find.text('Kimlik Numaranızı Giriniz'), findsOneWidget);
    expect(find.text('Şifrenizi Giriniz'), findsOneWidget);
  });
}
