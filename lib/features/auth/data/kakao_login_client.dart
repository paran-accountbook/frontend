import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/network/api_exception.dart';

abstract interface class KakaoLoginClient {
  Future<String> login();
}

class KakaoSdkLoginClient implements KakaoLoginClient {
  const KakaoSdkLoginClient();

  @override
  Future<String> login() async {
    try {
      final token = await _login();
      return token.accessToken;
    } catch (error, stackTrace) {
      AppLogger.error('카카오 로그인 SDK 오류', error, stackTrace);
      throw _toApiException(error);
    }
  }

  Future<OAuthToken> _login() async {
    if (!await isKakaoTalkInstalled()) {
      return UserApi.instance.loginWithKakaoAccount();
    }

    try {
      return await UserApi.instance.loginWithKakaoTalk();
    } catch (error, stackTrace) {
      if (_isCanceled(error)) rethrow;
      AppLogger.warning('카카오톡 로그인 실패, 카카오계정 로그인으로 재시도', error, stackTrace);
      return UserApi.instance.loginWithKakaoAccount();
    }
  }
}

ApiException _toApiException(Object error) {
  if (_isCanceled(error)) {
    return const ApiException(
      code: 'KAKAO_LOGIN_CANCELED',
      message: '카카오 로그인이 취소되었습니다',
    );
  }
  if (error is KakaoAuthException) {
    return switch (error.error) {
      AuthErrorCause.invalidClient => const ApiException(
        code: 'KAKAO_INVALID_CLIENT',
        message: '카카오 앱 키 설정을 확인해 주세요',
      ),
      AuthErrorCause.misconfigured => const ApiException(
        code: 'KAKAO_MISCONFIGURED',
        message: '카카오 개발자 콘솔의 iOS 번들 ID 설정을 확인해 주세요',
      ),
      AuthErrorCause.unauthorized => const ApiException(
        code: 'KAKAO_UNAUTHORIZED',
        message: '카카오 로그인 사용 권한을 확인해 주세요',
      ),
      _ => const ApiException(
        code: 'KAKAO_LOGIN_FAILED',
        message: '카카오 로그인을 완료하지 못했습니다. 다시 시도해 주세요',
      ),
    };
  }
  return const ApiException(
    code: 'KAKAO_LOGIN_FAILED',
    message: '카카오 로그인을 완료하지 못했습니다. 다시 시도해 주세요',
  );
}

bool _isCanceled(Object error) =>
    error is PlatformException && error.code.toUpperCase() == 'CANCELED' ||
    error is KakaoAuthException && error.error == AuthErrorCause.accessDenied;
