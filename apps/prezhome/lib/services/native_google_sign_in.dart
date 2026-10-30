import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// IDs de cliente OAuth de Google Cloud (no son secretos). El web es el mismo
// que está en Supabase > Authentication > Providers > Google.
const googleWebClientId =
    '732472235947-rths32d9u7ofkhpmb9he8s5alea5v259.apps.googleusercontent.com';
const googleIosClientId =
    '732472235947-dkqhd9t0rf57b0m2utoqe7rgjathv63k.apps.googleusercontent.com';

/// Sin IDs se sigue usando el login por navegador de Supabase.
bool get nativeGoogleAvailable =>
    !kIsWeb &&
    googleWebClientId.isNotEmpty &&
    (defaultTargetPlatform == TargetPlatform.android ||
        (defaultTargetPlatform == TargetPlatform.iOS &&
            googleIosClientId.isNotEmpty));

// shortcut: el SDK solo acepta el nonce en initialize (una vez por arranque),
// así que todos los intentos de una misma sesión de la app comparten nonce.
final _rawNonce = base64Url.encode(
  List<int>.generate(32, (_) => Random.secure().nextInt(256)),
);
Future<void>? _init;

/// Hoja de cuentas nativa de Google y sesión en Supabase con el idToken.
/// Si la persona cancela, vuelve sin error.
Future<void> signInWithNativeGoogle() async {
  final signIn = GoogleSignIn.instance;
  await (_init ??= signIn.initialize(
    clientId: defaultTargetPlatform == TargetPlatform.iOS
        ? googleIosClientId
        : null,
    serverClientId: googleWebClientId,
    // Google firma el hash; Supabase recibe el nonce en claro y lo compara.
    nonce: sha256.convert(utf8.encode(_rawNonce)).toString(),
  ));
  final GoogleSignInAccount account;
  try {
    account = await signIn.authenticate();
  } on GoogleSignInException catch (e) {
    if (e.code == GoogleSignInExceptionCode.canceled) return;
    rethrow;
  }
  final idToken = account.authentication.idToken;
  if (idToken == null) throw const AuthException('Google no devolvió token');
  await Supabase.instance.client.auth.signInWithIdToken(
    provider: OAuthProvider.google,
    idToken: idToken,
    nonce: _rawNonce,
  );
}
