import 'dart:convert';

import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AppleLoginCredential {
  const AppleLoginCredential({
    required this.identityToken,
    required this.authorizationCode,
    this.email,
  });

  final String identityToken;
  final String authorizationCode;
  final String? email;
}

abstract interface class AppleLoginClient {
  Future<AppleLoginCredential> login();
}

class AppleLoginCanceledException implements Exception {
  const AppleLoginCanceledException();
}

class AppleLoginFailedException implements Exception {
  const AppleLoginFailedException();
}

class AppleSdkLoginClient implements AppleLoginClient {
  const AppleSdkLoginClient();

  @override
  Future<AppleLoginCredential> login() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final identityToken = credential.identityToken;
      final authorizationCode = credential.authorizationCode;
      if (identityToken == null ||
          identityToken.isEmpty ||
          authorizationCode.isEmpty) {
        throw const AppleLoginFailedException();
      }
      return AppleLoginCredential(
        identityToken: identityToken,
        authorizationCode: authorizationCode,
        email: credential.email ?? _emailFromIdentityToken(identityToken),
      );
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) {
        throw const AppleLoginCanceledException();
      }
      throw const AppleLoginFailedException();
    } on SignInWithAppleException {
      throw const AppleLoginFailedException();
    }
  }

  static String? _emailFromIdentityToken(String token) {
    final segments = token.split('.');
    if (segments.length != 3) return null;
    try {
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(segments[1])),
      );
      final json = jsonDecode(payload);
      return json is Map<String, dynamic> ? json['email'] as String? : null;
    } on FormatException {
      return null;
    }
  }
}
