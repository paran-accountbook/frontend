import '../../../core/network/api_client.dart';

abstract interface class AuthService {
  Future<void> checkEmail(String email);
  Future<void> sendVerificationCode(String email);
  Future<void> verifyCode({required String email, required String code});
  Future<void> signup({
    required String email,
    required String password,
    required String nickname,
    required bool marketingAgreed,
  });
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
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
