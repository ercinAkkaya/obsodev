import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:obs/data/user_credentials_repository.dart';
import 'package:obs/login_page.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await UserCredentialsRepository.instance.resetForTests();
  });

  testWidgets('Giriş ekranı temel bileşenleri gösterir', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('YÖK OBS ile giriş'), findsOneWidget);
    expect(find.text('e-DEVLET ile Giriş'), findsOneWidget);
    expect(find.text('Kimlik Numaranızı Giriniz'), findsOneWidget);
    expect(find.text('Şifrenizi Giriniz'), findsOneWidget);
  });
}
