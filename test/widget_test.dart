// Tests de rendu de base pour l'application Wonn/Kotizz.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wonn/main.dart';
import 'package:wonn/screens/groups_screen.dart';

void main() {
  testWidgets('App démarre sans erreur critique', (WidgetTester tester) async {
    await tester.pumpWidget(const SolApp());
    await tester.pump(const Duration(seconds: 1));

    // Vérifie que l'app est bien rendue (scaffold présent)
    expect(find.byType(Scaffold), findsWidgets);
  });

  test('normalizeWhatsAppLink accepte et rejette les liens correctement', () {
    expect(
      normalizeWhatsAppLink('https://chat.whatsapp.com/abc123'),
      'https://chat.whatsapp.com/abc123',
    );
    expect(normalizeWhatsAppLink('https://example.com/test'), isNull);
    expect(normalizeWhatsAppLink('not-a-url'), isNull);
    expect(normalizeWhatsAppLink(null), isNull);
  });
}
