import 'package:flutter_test/flutter_test.dart';
import 'package:prezhome/services/share_inbox.dart';

void main() {
  test('lee el texto que manda la extensión de iOS', () {
    // Lo que genera ShareViewController.appUrl (todo menos -._~ codificado).
    final uri = Uri.parse(
      'com.prezhome.app://share?text=https%3A%2F%2Fwww.instagram.com'
      '%2Freel%2FABC%2F%3Figsh%3Dx%26a%3D1%2B2',
    );
    expect(
      sharedTextFromLink(uri),
      'https://www.instagram.com/reel/ABC/?igsh=x&a=1+2',
    );
  });

  test('ignora la vuelta del login y textos vacíos', () {
    expect(
      sharedTextFromLink(Uri.parse('com.prezhome.app://login-callback?code=1')),
      isNull,
    );
    expect(
      sharedTextFromLink(Uri.parse('com.prezhome.app://share?text=%20')),
      isNull,
    );
  });
}
