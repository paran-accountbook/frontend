import '../../features/auth/data/auth_service.dart';
import '../../features/auth/data/kakao_login_client.dart';
import '../../features/dutch/data/dutch_pay_service.dart';
import '../../features/finance/data/finance_service.dart';
import 'api_client.dart';

abstract final class AppServices {
  static final ApiClient client = ApiClient();
  static final AuthService auth = AuthApiService(client);
  static const KakaoLoginClient kakaoLogin = KakaoSdkLoginClient();
  static final FinanceService finance = FinanceApiService(client);
  static final DutchPayService dutchPay = DutchPayApiService(client);
}
