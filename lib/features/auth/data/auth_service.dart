import '../../../core/network/api_client.dart';

abstract interface class AuthService {
  Future<void> checkEmail(String email);
  Future<void> sendVerificationCode(String email);
  Future<void> verifyCode({required String email, required String code});
  Future<void> signup({
    required String email,
    required String password,
    required String nickname,
    required bool ageConfirmed,
    required bool marketingAgreed,
  });
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  });
  Future<Map<String, dynamic>> loginWithKakao(String kakaoAccessToken);
  Future<Map<String, dynamic>> loginWithApple({
    required String identityToken,
    required String authorizationCode,
    String? email,
    String? givenName,
    String? familyName,
  });
  Future<Map<String, dynamic>> termsDocument();
  Future<Map<String, dynamic>> termsStatus();
  Future<Map<String, dynamic>> myAgreement();
  Future<Map<String, dynamic>> agreeToLatestTerms();
  Future<Map<String, dynamic>> initialAgree({
    String? nickname,
    required bool ageConfirmed,
    required bool marketingAgreed,
  });
  Future<void> sendPasswordResetCode(String email);
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
  Future<void> logout();
  Future<void> deleteAccount({String? password});
  Future<void> cancelDeletion();
}

class AuthApiService implements AuthService {
  const AuthApiService(this._client);
  final ApiClient _client;

  @override
  Future<void> checkEmail(String email) async {
    await _client.post(
      '/auth/check-email',
      body: {'email': email},
      authenticated: false,
    );
  }

  @override
  Future<void> sendVerificationCode(String email) async {
    await _client.post(
      '/auth/verify/send-code',
      body: {'email': email},
      authenticated: false,
    );
  }

  @override
  Future<void> verifyCode({required String email, required String code}) async {
    await _client.post(
      '/auth/verify/check-code',
      body: {'email': email, 'code': code},
      authenticated: false,
    );
  }

  @override
  Future<void> signup({
    required String email,
    required String password,
    required String nickname,
    required bool ageConfirmed,
    required bool marketingAgreed,
  }) async {
    final data =
        await _client.post(
              '/auth/signup',
              body: {
                'email': email,
                'password': password,
                'password_confirm': password,
                'nickname': nickname,
                'terms_agreed': true,
                'privacy_agreed': true,
                'age_confirmed': ageConfirmed,
                'marketing_agreed': marketingAgreed,
              },
              authenticated: false,
            )
            as Map<String, dynamic>;
    await _saveTokens(data);
  }

  @override
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final data =
        await _client.post(
              '/auth/login',
              body: {'email': email, 'password': password},
              authenticated: false,
            )
            as Map<String, dynamic>;
    await _saveTokens(data);
    return data;
  }

  @override
  Future<Map<String, dynamic>> loginWithKakao(String kakaoAccessToken) async {
    final data =
        await _client.post(
              '/auth/kakao',
              body: {'kakao_access_token': kakaoAccessToken},
              authenticated: false,
            )
            as Map<String, dynamic>;
    await _saveTokens(data);
    return data;
  }

  @override
  Future<Map<String, dynamic>> loginWithApple({
    required String identityToken,
    required String authorizationCode,
    String? email,
    String? givenName,
    String? familyName,
  }) async {
    final body = <String, Object?>{
      'identity_token': identityToken,
      'authorization_code': authorizationCode,
    };
    if (email != null) body['email'] = email;
    if (givenName != null) body['given_name'] = givenName;
    if (familyName != null) body['family_name'] = familyName;
    final data =
        await _client.post('/auth/apple', body: body, authenticated: false)
            as Map<String, dynamic>;
    await _saveTokens(data);
    return data;
  }

  @override
  Future<Map<String, dynamic>> termsDocument() async =>
      await _client.get('/auth/terms/document', authenticated: false)
          as Map<String, dynamic>;

  @override
  Future<Map<String, dynamic>> termsStatus() async =>
      await _client.get('/auth/terms/status') as Map<String, dynamic>;

  @override
  Future<Map<String, dynamic>> myAgreement() async =>
      await _client.get('/auth/terms/my-agreement') as Map<String, dynamic>;

  @override
  Future<Map<String, dynamic>> agreeToLatestTerms() async =>
      await _client.post('/auth/terms/agree') as Map<String, dynamic>;

  @override
  Future<Map<String, dynamic>> initialAgree({
    String? nickname,
    required bool ageConfirmed,
    required bool marketingAgreed,
  }) async {
    final body = <String, Object?>{
      'terms_agreed': true,
      'privacy_agreed': true,
      'age_confirmed': ageConfirmed,
      'marketing_agreed': marketingAgreed,
    };
    if (nickname != null) body['nickname'] = nickname;
    return await _client.post('/auth/terms/initial-agree', body: body)
        as Map<String, dynamic>;
  }

  Future<void> _saveTokens(Map<String, dynamic> data) async {
    final access = data['access_token'] as String?;
    final refresh = data['refresh_token'] as String?;
    if (access != null && refresh != null) {
      await _client.sessionStore.save(
        accessToken: access,
        refreshToken: refresh,
      );
    }
  }

  @override
  Future<void> sendPasswordResetCode(String email) async {
    await _client.post(
      '/auth/password-reset/send-code',
      body: {'email': email},
      authenticated: false,
    );
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _client.post(
      '/auth/password-reset/confirm',
      body: {
        'email': email,
        'code': code,
        'new_password': newPassword,
        'new_password_confirm': newPassword,
      },
      authenticated: false,
    );
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _client.patch(
      '/mypage/account/password',
      body: {
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirm': newPassword,
      },
    );
  }

  @override
  Future<void> logout() => _client.sessionStore.clear();
  @override
  Future<void> deleteAccount({String? password}) async {
    await _client.post(
      '/mypage/account/delete_account',
      body: {'password': password},
    );
    await _client.sessionStore.clear();
  }

  @override
  Future<void> cancelDeletion() async {
    await _client.post('/mypage/account/cancel_deletion');
  }
}
